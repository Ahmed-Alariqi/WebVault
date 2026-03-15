import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
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
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.magicWand()),
            tooltip: AppLocalizations.of(context)!.seedDefaultCategories,
            onPressed: () => _seedDefaultCategories(ref, context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDialog(context, ref, isDark),
          ),
        ],
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
                          if (cat.contentType != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
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
                                  cat.contentType!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
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

  Future<void> _seedDefaultCategories(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final defaults = [
      {
        'name': 'Technology',
        'icon_code_point': PhosphorIcons.desktop().codePoint,
        'color_value': 0xFF3F51B5.toSigned(32),
        'sort_order': 0,
      },
      {
        'name': 'Education',
        'icon_code_point': PhosphorIcons.bookBookmark().codePoint,
        'color_value': 0xFF4CAF50.toSigned(32),
        'sort_order': 1,
      },
      {
        'name': 'Software',
        'icon_code_point': PhosphorIcons.code().codePoint,
        'color_value': 0xFFF44336.toSigned(32),
        'sort_order': 2,
      },
      {
        'name': 'Design',
        'icon_code_point': PhosphorIcons.paintBrush().codePoint,
        'color_value': 0xFFE91E63.toSigned(32),
        'sort_order': 3,
      },
      {
        'name': 'Business',
        'icon_code_point': PhosphorIcons.briefcase().codePoint,
        'color_value': 0xFFFF9800.toSigned(32),
        'sort_order': 4,
      },
    ];

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );

      for (final cat in defaults) {
        await adminAddCategory(cat);
      }

      ref.invalidate(adminCategoriesProvider);
      ref.invalidate(categoriesProvider);

      if (context.mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.defaultCategoriesInjected,
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.failedToSeedCategories(e.toString()),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark, {
    CategoryModel? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedContentType = existing?.contentType;

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
                  DropdownButtonFormField<String?>(
                    value: selectedContentType,
                    decoration: InputDecoration(
                      labelText: 'Content Type (Optional)',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All/General')),
                      DropdownMenuItem(
                        value: 'website',
                        child: Text('Websites / Resources'),
                      ),
                      DropdownMenuItem(value: 'tool', child: Text('Tools')),
                      DropdownMenuItem(value: 'course', child: Text('Courses')),
                      DropdownMenuItem(value: 'prompt', child: Text('Prompts')),
                      DropdownMenuItem(value: 'offer', child: Text('Offers')),
                      DropdownMenuItem(
                        value: 'announcement',
                        child: Text('News / Articles'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedContentType = val;
                      });
                    },
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
                    'content_type': selectedContentType,
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
