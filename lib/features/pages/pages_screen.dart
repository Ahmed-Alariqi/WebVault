import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/page_model.dart';
import '../../presentation/widgets/modern_fab.dart';
import '../../presentation/widgets/tutorial_overlay.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants.dart';
import 'package:flutter/services.dart';

class PagesScreen extends ConsumerStatefulWidget {
  const PagesScreen({super.key});

  @override
  ConsumerState<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends ConsumerState<PagesScreen> {
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _foldersButtonKey = GlobalKey();

  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _enterMultiSelect(String id) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _exitMultiSelect();
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await TutorialManager.shouldShowSection(TutorialSection.pages);
    if (mounted && shouldShow) {
      final l10n = AppLocalizations.of(context)!;
      TutorialOverlay.show(
        context,
        section: TutorialSection.pages,
        steps: TutorialManager.getPagesSteps(l10n, _addButtonKey, _foldersButtonKey),
        onComplete: () {
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = ref.watch(filteredPagesProvider);
    final searchQuery = ref.watch(pageSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('${_selectedIds.length} ${AppLocalizations.of(context)!.selected}')
            : Text(AppLocalizations.of(context)!.pages),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: Icon(PhosphorIcons.x()),
                onPressed: _exitMultiSelect,
              )
            : null,
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: Icon(
                _selectedIds.length == pages.length
                    ? PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)
                    : PhosphorIcons.square(),
              ),
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == pages.length) {
                    _exitMultiSelect();
                  } else {
                    _selectedIds.addAll(pages.map((p) => p.id));
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.cloud_done_outlined, color: AppTheme.primaryLight),
              tooltip: AppLocalizations.of(context)!.syncAllSelected,
              onPressed: () {
                final allPagesInState = ref.read(pagesProvider);
                int currentSyncedCount = allPagesInState.where((p) => p.syncEnabled).length;

                for (final id in _selectedIds) {
                  final page = allPagesInState.firstWhere((p) => p.id == id);
                  if (!page.syncEnabled) {
                    if (currentSyncedCount >= kMaxSyncPages) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.syncLimitReached),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      break;
                    }
                    ref.read(pagesProvider.notifier).updatePage(page.copyWith(syncEnabled: true));
                    currentSyncedCount++;
                  }
                }
                _exitMultiSelect();
              },
            ),
            IconButton(
              icon: Icon(Icons.cloud_off_outlined, color: Colors.grey),
              tooltip: AppLocalizations.of(context)!.unsyncAllSelected,
              onPressed: () {
                final allPagesInState = ref.read(pagesProvider);
                for (final id in _selectedIds) {
                  final page = allPagesInState.firstWhere((p) => p.id == id);
                  if (page.syncEnabled) {
                    ref.read(pagesProvider.notifier).updatePage(page.copyWith(syncEnabled: false));
                  }
                }
                _exitMultiSelect();
              },
            ),
            IconButton(
              icon: Icon(PhosphorIcons.trash(), color: AppTheme.errorColor),
              tooltip: AppLocalizations.of(context)!.deleteAllSelected,
              onPressed: () {
                // Confirm delete
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.deleteSelected),
                    content: Text(AppLocalizations.of(context)!.deleteConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          for (final id in _selectedIds) {
                            ref.read(pagesProvider.notifier).deletePage(id);
                          }
                          Navigator.pop(ctx);
                          _exitMultiSelect();
                        },
                        child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: AppTheme.errorColor)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextButton.icon(
                key: _foldersButtonKey,
                onPressed: () => context.push('/folders'),
                icon: Icon(PhosphorIcons.folder(), size: 18),
                label: Text(
                  AppLocalizations.of(context)!.folders,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (v) => ref.read(pageSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchPages,
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(PhosphorIcons.x(), size: 18),
                        onPressed: () =>
                            ref.read(pageSearchProvider.notifier).state = '',
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: pages.isEmpty
                ? _buildEmpty(isDark, searchQuery.isNotEmpty, context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: pages.length,
                    itemBuilder: (context, i) =>
                        _buildPageItem(context, ref, pages[i], isDark),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ModernFab.extended(
        key: _addButtonKey,
        onPressed: () => context.push('/add-page'),
        icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
        label: Text(AppLocalizations.of(context)!.addPage),
      ),
    );
  }

  Widget _buildPageItem(
    BuildContext context,
    WidgetRef ref,
    PageModel page,
    bool isDark,
  ) {
    return Dismissible(
      key: Key(page.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.errorColor.withValues(alpha: 0.15),
              AppTheme.errorColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                PhosphorIcons.trash(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'حذف',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(context, page, isDark);
      },
      onDismissed: (_) {
        ref.read(pagesProvider.notifier).deletePage(page.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text('تم حذف "${page.title}"'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: AppTheme.primaryColor,
              onPressed: () {
                ref.read(pagesProvider.notifier).restoreLastPage();
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          if (!_isMultiSelectMode) {
            _enterMultiSelect(page.id);
          }
        },
        onTap: () {
          if (_isMultiSelectMode) {
            _toggleSelection(page.id);
            return;
          }
          context.push('/browser/${page.id}');
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedIds.contains(page.id)
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _selectedIds.contains(page.id)
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
              width: _selectedIds.contains(page.id) ? 1.5 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppTheme.primaryColor)
                    .withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                          AppTheme.primaryColor.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                      color: AppTheme.primaryColor,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        page.syncEnabled 
                            ? PhosphorIcons.cloudCheck(PhosphorIconsStyle.fill) 
                            : PhosphorIcons.cloudSlash(PhosphorIconsStyle.bold),
                        size: 14,
                        color: page.syncEnabled 
                            ? AppTheme.primaryColor 
                            : (isDark ? Colors.white30 : Colors.black26),
                      ).animate(target: page.syncEnabled ? 1 : 0).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 300.ms,
                        curve: Curves.elasticOut,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            page.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      page.url,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (page.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: page.tags.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(pagesProvider.notifier)
                        .toggleFavorite(page.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: page.isFavorite
                            ? AppTheme.errorColor.withValues(alpha: 0.1)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        page.isFavorite
                            ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                            : PhosphorIcons.heart(),
                        size: 18,
                        color: page.isFavorite
                            ? AppTheme.errorColor
                            : (isDark ? Colors.white38 : Colors.black26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push('/edit-page/${page.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        PhosphorIcons.pencilSimple(),
                        size: 18,
                        color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut).slideY(
          begin: 0.06,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Future<bool> _showDeleteConfirmDialog(
    BuildContext context,
    PageModel page,
    bool isDark,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIcons.trash(),
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'حذف الصفحة؟',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            content: Text(
              'سيتم حذف "${page.title}" نهائياً.',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'إلغاء',
                  style:
                      TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildEmpty(bool isDark, bool isSearch, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSearch
                  ? PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone)
                  : PhosphorIcons.browsers(PhosphorIconsStyle.duotone),
              color: AppTheme.primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? l.noResultsFound : l.noPagesYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch ? l.noResultsFound : l.addFirstPage,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
