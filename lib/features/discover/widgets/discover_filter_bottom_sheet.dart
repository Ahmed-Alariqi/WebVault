import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/discover_providers.dart';
import '../../../l10n/app_localizations.dart';

class DiscoverFilterBottomSheet extends ConsumerStatefulWidget {
  const DiscoverFilterBottomSheet({super.key});

  @override
  ConsumerState<DiscoverFilterBottomSheet> createState() =>
      _DiscoverFilterBottomSheetState();
}

class _DiscoverFilterBottomSheetState
    extends ConsumerState<DiscoverFilterBottomSheet> {
  // Temporary state before user clicks "Apply"
  String? _tempContentType;
  String? _tempCategoryId;
  String? _tempPricingModel;
  String _tempSortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _tempContentType = ref.read(selectedContentTypeProvider);
    _tempCategoryId = ref.read(selectedCategoryProvider);
    _tempPricingModel = ref.read(selectedPricingModelProvider);
    _tempSortBy = ref.read(discoverSortByProvider);
  }

  void _applyFilters() {
    ref.read(selectedContentTypeProvider.notifier).state = _tempContentType;
    ref.read(selectedCategoryProvider.notifier).state = _tempCategoryId;
    ref.read(selectedPricingModelProvider.notifier).state = _tempPricingModel;
    ref.read(discoverSortByProvider.notifier).state = _tempSortBy;
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _tempContentType = null;
      _tempCategoryId = null;
      _tempPricingModel = null;
      _tempSortBy = 'newest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filterTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    l10n.filterReset,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSectionTitle(l10n.filterContentType, isDark),
                const SizedBox(height: 12),
                _buildContentTypeChips(isDark, l10n),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.filterCategory, isDark),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (cats) {
                    final filteredCats = cats.where((c) {
                      if (_tempContentType == null) return true;
                      return c.contentType == null ||
                          c.contentType == _tempContentType;
                    }).toList();

                    return _buildCategoryChips(filteredCats, isDark, l10n);
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Text(l10n.filterErrorLoading),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.filterPricingModel, isDark),
                const SizedBox(height: 12),
                _buildPricingModelChips(isDark, l10n),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.filterSortBy, isDark),
                const SizedBox(height: 12),
                _buildSortByChips(isDark, l10n),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Apply Button
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.filterApply,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildContentTypeChips(bool isDark, AppLocalizations l10n) {
    final types = <({String? value, String label})>[
      (value: null, label: l10n.filterAll),
      (value: 'website', label: l10n.formTypeResources),
      (value: 'tool', label: l10n.formTypeTools),
      (value: 'course', label: l10n.formTypeCourses),
      (value: 'prompt', label: l10n.formTypePrompts),
      (value: 'offer', label: l10n.formTypeOffers),
      (value: 'announcement', label: l10n.formTypeNews),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: types.map((type) {
        final val = type.value;
        final label = type.label;
        final isSelected = _tempContentType == val;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _tempContentType = val;
              _tempCategoryId = null;
            });
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          labelStyle: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips(
    List categories,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        ChoiceChip(
          label: Text(l10n.filterAll),
          selected: _tempCategoryId == null,
          onSelected: (selected) {
            setState(() => _tempCategoryId = null);
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          labelStyle: TextStyle(
            color: _tempCategoryId == null
                ? AppTheme.primaryColor
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: _tempCategoryId == null
                ? FontWeight.w600
                : FontWeight.w500,
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _tempCategoryId == null
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
        ),
        ...categories.map((cat) {
          final isSelected = _tempCategoryId == cat.id;
          return ChoiceChip(
            label: Text(cat.name),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _tempCategoryId = selected ? cat.id : null);
            },
            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            labelStyle: TextStyle(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPricingModelChips(bool isDark, AppLocalizations l10n) {
    final pricingModels = <({String? value, String label})>[
      (value: null, label: l10n.filterAny),
      (value: 'free', label: l10n.pricingFree),
      (value: 'freemium', label: l10n.pricingFreemium),
      (value: 'paid', label: l10n.pricingPaid),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: pricingModels.map((model) {
        final val = model.value;
        final label = model.label;
        final isSelected = _tempPricingModel == val;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _tempPricingModel = val);
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          labelStyle: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortByChips(bool isDark, AppLocalizations l10n) {
    final sortOptions = [
      {'value': 'newest', 'label': l10n.filterNewest},
      {'value': 'popular', 'label': l10n.filterPopular},
      {'value': 'trending', 'label': l10n.filterTrending},
      {'value': 'oldest', 'label': l10n.filterOldest},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: sortOptions.map((opt) {
        final val = opt['value']!;
        final label = opt['label']!;
        final isSelected = _tempSortBy == val;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _tempSortBy = val);
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          labelStyle: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }
}
