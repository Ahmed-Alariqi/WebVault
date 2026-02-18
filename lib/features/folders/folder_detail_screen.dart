import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/widgets/suggestion_dialog.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/page_model.dart';

class FolderDetailScreen extends ConsumerWidget {
  final String folderId;

  const FolderDetailScreen({super.key, required this.folderId});

  static final List<IconData> _folderIcons = [
    PhosphorIcons.folder(),
    PhosphorIcons.briefcase(),
    PhosphorIcons.heart(),
    PhosphorIcons.code(),
    PhosphorIcons.bookmarkSimple(),
    PhosphorIcons.student(),
    PhosphorIcons.image(),
    PhosphorIcons.barbell(),
    PhosphorIcons.monitor(),
    PhosphorIcons.musicNote(),
    PhosphorIcons.gameController(),
    PhosphorIcons.shoppingCart(),
  ];

  IconData _getFolderIcon(int codePoint) {
    try {
      return _folderIcons.firstWhere(
        (icon) => icon.codePoint == codePoint,
        orElse: () => PhosphorIcons.folder(),
      );
    } catch (_) {
      return PhosphorIcons.folder();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final folders = ref.watch(foldersProvider);
    final folderIndex = folders.indexWhere((f) => f.id == folderId);

    if (folderIndex == -1) {
      return const Scaffold(body: Center(child: Text('Folder not found')));
    }

    final folder = folders[folderIndex];
    final color = Color(folder.colorValue);

    final allPages = ref.watch(pagesProvider);
    final folderPages = allPages.where((p) => p.folderId == folderId).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: BackButton(
          color: isDark ? Colors.white : Colors.black,
          onPressed: () => context.pop(),
        ),
        title: Text(
          folder.name,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.trash(), color: AppTheme.errorColor),
            onPressed: () => _confirmDeleteFolder(context, ref, folder),
          ),
        ],
      ),
      body: Column(
        children: [
          // Folder Info Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getFolderIcon(folder.iconCodePoint),
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.itemCount(folderPages.length),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created on ${_formatDate(folder.createdAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pages List
          Expanded(
            child: folderPages.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: folderPages.length,
                    itemBuilder: (context, index) {
                      final page = folderPages[index];
                      return _FolderPageItem(
                        page: page,
                        isDark: isDark,
                        onTap: () => context.push('/browser/${page.id}'),
                        onRemove: () {
                          // Remove from folder directly
                          ref
                              .read(pagesProvider.notifier)
                              .removeFromFolder(page.id);
                        },
                        onLongPress: () => showSuggestionDialog(
                          context,
                          ref,
                          title: page.title,
                          url: page.url,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.files(PhosphorIconsStyle.duotone),
            size: 64,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.folderEmpty,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addPagesFromBrowser,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(
    BuildContext context,
    WidgetRef ref,
    FolderModel folder,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteFolder),
        content: Text(AppLocalizations.of(context)!.deleteFolderConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(foldersProvider.notifier).deleteFolder(folder.id);
              Navigator.pop(ctx); // Close dialog
              context.pop(); // Go back to folders screen
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}

class _FolderPageItem extends StatelessWidget {
  final PageModel page;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onLongPress;

  const _FolderPageItem({
    required this.page,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(page.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.folder_off, color: Colors.white),
        ),
        onDismissed: (_) => onRemove(),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIcons.globe(),
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        page.url,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIcons.dotsThreeVertical(),
                    size: 20,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onPressed: () {
                    // Show options if needed
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}
