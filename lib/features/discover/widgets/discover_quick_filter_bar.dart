import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/discover_providers.dart';
import '../../../l10n/app_localizations.dart';

class DiscoverQuickFilterBar extends ConsumerWidget {
  const DiscoverQuickFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final selectedType = ref.watch(selectedContentTypeProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final types = <({String? value, String label})>[
      (value: null, label: l10n.filterAll),
      (value: 'website', label: l10n.formTypeResources),
      (value: 'tool', label: l10n.formTypeTools),
      (value: 'course', label: l10n.formTypeCourses),
      (value: 'prompt', label: l10n.formTypePrompts),
      (value: 'offer', label: l10n.formTypeOffers),
      (value: 'announcement', label: l10n.formTypeNews),
    ];

    // Determine sub-categories based on selectedType
    final subCategories = categoriesAsync.maybeWhen(
      data: (cats) {
        if (selectedType == null) return [];
        return cats.where((c) {
          return c.contentTypes == null ||
              c.contentTypes!.isEmpty ||
              c.contentTypes!.contains(selectedType);
        }).toList();
      },
      orElse: () => [],
    );

    final hasSubCategories = subCategories.isNotEmpty && selectedType != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Main Categories (Content Types) ──
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = types[index];
              final isSelected = item.value == selectedType;
              return Center(
                child: GestureDetector(
                  onTap: () {
                    // Update content type
                    ref.read(selectedContentTypeProvider.notifier).state =
                        item.value;
                    // Reset sub-category since main category changed
                    ref.read(selectedCategoryProvider.notifier).state = null;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Sub Categories (Animated Expansion) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutBack,
          alignment: Alignment.topCenter,
          child: hasSubCategories
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          subCategories.length + 1, // +1 for "All" option
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isAllOption = index == 0;
                        final isSelected = isAllOption
                            ? selectedCat == null
                            : selectedCat == subCategories[index - 1].id;

                        final label = isAllOption
                            ? l10n.filterAll
                            : subCategories[index - 1].name;
                        final id = isAllOption
                            ? null
                            : subCategories[index - 1].id;

                        return Center(
                          child: GestureDetector(
                            onTap: () {
                              ref
                                      .read(selectedCategoryProvider.notifier)
                                      .state =
                                  id;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? Colors.white24 : Colors.black87)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.black12),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
