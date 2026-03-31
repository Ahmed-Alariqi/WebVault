import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../presentation/widgets/modern_fab.dart';
import '../../l10n/app_localizations.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageCategoriesTitle),
        forceMaterialTransparency: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ModernFab.extended(
        onPressed: () => _showAddEditDialog(context, ref, isDark),
        icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
        label: Text(AppLocalizations.of(context)!.addCategory),
      ),
      body: categories.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                    size: 56,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noCategories,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            onReorder: (oldI, newI) async {
              // Simple reorder logic
              if (newI > oldI) newI--;
              final cat = list[oldI];
              await adminUpdateCategory(cat.id, {'sort_order': newI});
              ref.invalidate(adminCategoriesProvider);
              ref.invalidate(categoriesProvider);
            },
            itemBuilder: (ctx, i) {
              final cat = list[i];
              return Container(
                key: ValueKey(cat.id),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        IconData(
                          cat.iconCodePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(cat.colorValue),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (cat.contentTypes != null &&
                              cat.contentTypes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: cat.contentTypes!.map((type) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.pencilSimple(),
                        size: 18,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      onPressed: () => _showAddEditDialog(
                        context,
                        ref,
                        isDark,
                        existing: cat,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.trash(),
                        size: 18,
                        color: AppTheme.errorColor,
                      ),
                      onPressed: () async {
                        await adminDeleteCategory(cat.id);
                        ref.invalidate(adminCategoriesProvider);
                        ref.invalidate(categoriesProvider);
                      },
                    ),
                    Icon(
                      PhosphorIcons.dotsSixVertical(),
                      size: 18,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => OfflineWarningWidget(error: e),
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark, {
    CategoryModel? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    List<String> selectedContentTypes = existing?.contentTypes?.toList() ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              existing == null
                  ? AppLocalizations.of(context)!.addCategory
                  : AppLocalizations.of(context)!.editCategory,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.categoryName,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.formContentType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          {
                            'val': 'all',
                            'lbl': AppLocalizations.of(context)!.all,
                          },
                          {
                            'val': 'website',
                            'lbl': AppLocalizations.of(
                              context,
                            )!.formTypeResources,
                          },
                          {
                            'val': 'tool',
                            'lbl': AppLocalizations.of(context)!.formTypeTools,
                          },
                          {
                            'val': 'course',
                            'lbl': AppLocalizations.of(
                              context,
                            )!.formTypeCourses,
                          },
                          {
                            'val': 'prompt',
                            'lbl': AppLocalizations.of(
                              context,
                            )!.formTypePrompts,
                          },
                          {
                            'val': 'offer',
                            'lbl': AppLocalizations.of(context)!.formTypeOffers,
                          },
                          {
                            'val': 'announcement',
                            'lbl': AppLocalizations.of(context)!.formTypeNews,
                          },
                          {
                            'val': 'tutorial',
                            'lbl': AppLocalizations.of(
                              context,
                            )!.formTypeTutorials,
                          },
                        ].map((item) {
                          final val = item['val']!;
                          final lbl = item['lbl']!;
                          final isAll = val == 'all';

                          // "All" is visibly selected only when the actual array is empty
                          final isSelected = isAll
                              ? selectedContentTypes.isEmpty
                              : selectedContentTypes.contains(val);

                          return FilterChip(
                            label: Text(
                              lbl,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (isAll) {
                                  // Choosing All instantly clears specific typings
                                  selectedContentTypes.clear();
                                } else {
                                  if (selected) {
                                    selectedContentTypes.add(val);
                                  } else {
                                    selectedContentTypes.remove(val);
                                  }
                                }
                              });
                            },
                            showCheckmark: false,
                            selectedColor: AppTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  final data = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                    'content_types': selectedContentTypes.isEmpty
                        ? null
                        : selectedContentTypes,
                  };

                  if (existing == null) {
                    data['icon_code_point'] = PhosphorIcons.tag().codePoint;
                    data['color_value'] = AppTheme.primaryColor
                        .toARGB32()
                        .toSigned(32);
                    data['sort_order'] = 0;

                    await adminAddCategory(data);
                  } else {
                    await adminUpdateCategory(existing.id, data);
                  }

                  ref.invalidate(adminCategoriesProvider);
                  ref.invalidate(categoriesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  existing == null
                      ? AppLocalizations.of(context)!.addBtn
                      : AppLocalizations.of(context)!.save,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
