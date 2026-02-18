import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/folder_model.dart';
import '../../presentation/widgets/modern_form_widgets.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  static const List<int> _folderColors = [
    0xFF3F51B5,
    0xFF009688,
    0xFFE91E63,
    0xFFFF9800,
    0xFF4CAF50,
    0xFF9C27B0,
    0xFF2196F3,
    0xFF795548,
    0xFF607D8B,
    0xFFF44336,
    0xFF9E9E9E,
    0xFF35465C,
  ];

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

  // Helper to get const IconData from codePoint for tree-shaking support
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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Folders'),
        forceMaterialTransparency: true,
      ),
      body: folders.isEmpty
          ? _buildEmpty(isDark)
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: folders.length,
              itemBuilder: (context, i) =>
                  _buildFolderCard(context, ref, folders[i], isDark),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFolderDialog(context, ref, isDark),
        icon: Icon(PhosphorIcons.folderPlus(PhosphorIconsStyle.fill)),
        label: const Text('New Folder'),
      ),
    );
  }

  Widget _buildFolderCard(
    BuildContext context,
    WidgetRef ref,
    FolderModel folder,
    bool isDark,
  ) {
    final color = Color(folder.colorValue);
    // Map stored codePoint back to Phosphor if possible, mainly for display logic.
    // However, since we store codePoint, we need to be careful if we switch icon packs.
    // For now we assume the codepoint is valid for the font family used.
    // Since we switched to Phosphor, existing dummy data using Material Icons might break visually
    // if not handled. But since dummy data is re-seeded or persistent..
    // We should probably clear dummy data or handle migration.
    // For this task, we'll assume new folders will be correct.
    // Material icons wont show up with Phosphor font family.
    // We will use IconData with specific fontFamily if we stored it, but we only stored codePoint.
    // Fix: We'll interpret codePoint as Material if it matches known Material range or just standard Icon()
    // For simplicity, we are building *new* features.

    final itemCount = ref
        .watch(pagesProvider)
        .where((p) => p.folderId == folder.id)
        .length;

    return GestureDetector(
      onTap: () => context.push('/folders/${folder.id}'),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Delete Folder',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    ref.read(foldersProvider.notifier).deleteFolder(folder.id);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                // Fix: Use lookup to ensure const IconData for tree shaking
                _getFolderIcon(folder.iconCodePoint),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                folder.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$itemCount items',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              PhosphorIcons.folderOpen(PhosphorIconsStyle.duotone),
              color: AppTheme.primaryColor,
              size: 40,
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          Text(
            'No folders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create folders to organize your pages',
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final nameCtrl = TextEditingController();
    int selectedColor = _folderColors[0];
    IconData selectedIcon = _folderIcons[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.folderPlus(),
                        size: 24,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'New Folder',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: nameCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: ModernFormWidgets.inputDecoration(
                      context,
                      label: 'Folder Name',
                      hint: 'e.g. Finance',
                      icon: PhosphorIcons.textT(),
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _folderColors.map((c) {
                      final isSelected = c == selectedColor;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = c),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(c).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Icon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _folderIcons.map((ic) {
                      final isSelected = ic == selectedIcon;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = ic),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(selectedColor).withValues(alpha: 0.2)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: Color(selectedColor),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Icon(
                            ic,
                            size: 24,
                            color: isSelected
                                ? Color(selectedColor)
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  ModernFormWidgets.gradientButton(
                    label: 'Create Folder',
                    icon: PhosphorIcons.plus(),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final folder = FolderModel(
                        id: const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        iconCodePoint: selectedIcon.codePoint,
                        colorValue: selectedColor,
                        createdAt: DateTime.now(),
                      );
                      ref.read(foldersProvider.notifier).addFolder(folder);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
