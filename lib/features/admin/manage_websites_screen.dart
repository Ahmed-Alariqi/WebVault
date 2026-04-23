import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../core/utils/text_utils.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/modern_fab.dart';
import '../../presentation/widgets/website_details_dialog.dart';
import '../../presentation/widgets/shimmer_loading.dart';
import '../../l10n/app_localizations.dart';

class ManageWebsitesScreen extends ConsumerStatefulWidget {
  const ManageWebsitesScreen({super.key});

  @override
  ConsumerState<ManageWebsitesScreen> createState() =>
      _ManageWebsitesScreenState();
}

class _ManageWebsitesScreenState extends ConsumerState<ManageWebsitesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Sync search controller with provider
    _searchController.text = ref.read(adminSearchQueryProvider);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(adminWebsitesPaginatedProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminSearchQueryProvider.notifier).state = query;
      ref.read(adminWebsitesPaginatedProvider.notifier).reset();
    });
  }

  void _onContentTypeChanged(String? type) {
    ref.read(adminContentTypeFilterProvider.notifier).state = type;
    ref.read(adminWebsitesPaginatedProvider.notifier).reset();
  }

  void _toggleSort() {
    final current = ref.read(adminSortAscendingProvider);
    ref.read(adminSortAscendingProvider.notifier).state = !current;
    ref.read(adminWebsitesPaginatedProvider.notifier).reset();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pState = ref.watch(adminWebsitesPaginatedProvider);
    final l10n = AppLocalizations.of(context)!;
    final selectedType = ref.watch(adminContentTypeFilterProvider);
    final ascending = ref.watch(adminSortAscendingProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.adminSearchItems,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 16,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              )
            : Text(l10n.manageItemsTitle),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(
              _isSearching
                  ? PhosphorIcons.x()
                  : PhosphorIcons.magnifyingGlass(),
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _onSearchChanged('');
                }
                _isSearching = !_isSearching;
              });
            },
            tooltip: _isSearching ? l10n.cancel : l10n.adminSearchItems,
          ),
          // Sort toggle
          IconButton(
            icon: Icon(
              ascending
                  ? PhosphorIcons.sortAscending()
                  : PhosphorIcons.sortDescending(),
            ),
            onPressed: _toggleSort,
            tooltip: ascending ? l10n.adminSortOldest : l10n.adminSortNewest,
          ),
          // Drafts toggle
          Consumer(
            builder: (context, ref, _) {
              final draftCount = ref.watch(adminDraftCountProvider);
              final readyCount = ref.watch(adminReadyDraftCountProvider);

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                      color: const Color(0xFFF59E0B),
                    ),
                    onPressed: () => context.push('/admin/drafts'),
                    tooltip: 'المسودات',
                  ),
                  if (draftCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: readyCount > 0 ? AppTheme.successColor : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          draftCount > 9 ? '9+' : draftCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Content Type Filter Chips ──
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip(
                  label: l10n.adminAllTypes,
                  isSelected: selectedType == null,
                  onTap: () => _onContentTypeChanged(null),
                  isDark: isDark,
                ),
                _filterChip(
                  label: l10n.formTypeResources,
                  isSelected: selectedType == 'website',
                  onTap: () => _onContentTypeChanged('website'),
                  isDark: isDark,
                  color: AppTheme.primaryColor,
                ),
                _filterChip(
                  label: l10n.formTypeTools,
                  isSelected: selectedType == 'tool',
                  onTap: () => _onContentTypeChanged('tool'),
                  isDark: isDark,
                  color: const Color(0xFF607D8B),
                ),
                _filterChip(
                  label: l10n.formTypeCourses,
                  isSelected: selectedType == 'course',
                  onTap: () => _onContentTypeChanged('course'),
                  isDark: isDark,
                  color: const Color(0xFF4CAF50),
                ),
                _filterChip(
                  label: l10n.formTypePrompts,
                  isSelected: selectedType == 'prompt',
                  onTap: () => _onContentTypeChanged('prompt'),
                  isDark: isDark,
                  color: const Color(0xFF9C27B0),
                ),
                _filterChip(
                  label: l10n.formTypeOffers,
                  isSelected: selectedType == 'offer',
                  onTap: () => _onContentTypeChanged('offer'),
                  isDark: isDark,
                  color: const Color(0xFFFF9800),
                ),
                _filterChip(
                  label: l10n.formTypeNews,
                  isSelected: selectedType == 'announcement',
                  onTap: () => _onContentTypeChanged('announcement'),
                  isDark: isDark,
                  color: const Color(0xFF2196F3),
                ),
                _filterChip(
                  label: l10n.formTypeTutorials,
                  isSelected: selectedType == 'tutorial',
                  onTap: () => _onContentTypeChanged('tutorial'),
                  isDark: isDark,
                  color: const Color(0xFFE91E63),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Item count ──
          if (!pState.isInitialLoad)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.adminItemsCount(pState.items.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ── Grid ──
          Expanded(
            child: pState.isInitialLoad
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: List.generate(
                        5,
                        (_) => const ShimmerAdminTile(),
                      ),
                    ),
                  )
                : pState.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                          size: 56,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noItemsYet,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tapPlusToAddOne,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 290,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                    itemCount: pState.items.length + (pState.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= pState.items.length) {
                        return const ShimmerAdminTile();
                      }
                      return _websiteTile(
                        context,
                        ref,
                        pState.items[i],
                        isDark,
                        i,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ModernFab.extended(
        onPressed: () => context.push('/admin/websites/edit'),
        icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
        label: Text(l10n.newItem),
      ),
    );
  }

  // ── Filter Chip Widget ──
  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final chipColor = color ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.15)
                : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? chipColor.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? chipColor
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _websiteTile(
    BuildContext context,
    WidgetRef ref,
    WebsiteModel site,
    bool isDark,
    int index,
  ) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    String? catName;

    if (site.categoryId != null) {
      categoriesAsync.whenData((cats) {
        try {
          catName = cats.firstWhere((c) => c.id == site.categoryId).name;
        } catch (_) {}
      });
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => WebsiteDetailsDialog(site: site),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + Badges ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: site.imageUrl != null && site.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: site.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                              child: Center(
                                child: Icon(
                                  _typeIcon(site.contentType),
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                              ),
                            ),
                            errorWidget: (ctx, url, err) => _placeholderImage(
                              context,
                              isDark,
                              site.contentType,
                            ),
                          )
                        : _placeholderImage(context, isDark, site.contentType),
                  ),
                  // Content type badge
                  if (site.contentType != 'website')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor(
                            site.contentType,
                          ).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _typeIcon(site.contentType),
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _typeDisplayName(context, site.contentType),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Active/Inactive/Expired badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Wrap(
                      direction: Axis.vertical,
                      spacing: 4,
                      children: [
                        if (!site.isActive)
                          _badge(
                            AppLocalizations.of(context)!.badgeInactive,
                            Colors.grey,
                            isDark,
                          ),
                        if (site.isExpired)
                          _badge(
                            AppLocalizations.of(context)!.badgeExpired,
                            Colors.red,
                            isDark,
                          ),
                        if (site.isTrending)
                          _badge(
                            AppLocalizations.of(context)!.badgeTrending,
                            const Color(0xFFFF6B6B),
                            isDark,
                          ),
                        if (site.isPopular)
                          _badge(
                            AppLocalizations.of(context)!.badgePopular,
                            const Color(0xFFFF9800),
                            isDark,
                          ),
                        if (site.isFeatured)
                          _badge(
                            AppLocalizations.of(context)!.badgeFeatured,
                            const Color(0xFF4CAF50),
                            isDark,
                          ),
                        if (catName != null)
                          _badge(catName!, AppTheme.primaryColor, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (site.hasCopyableValue) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Text(
                                site.actionValue,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            Text(
                              TextUtils.getPlainTextFromDescription(
                                site.description,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Admin Actions ──
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(
                                '/admin/websites/edit',
                                extra: site,
                              ),
                              icon: Icon(
                                PhosphorIcons.pencilSimple(),
                                size: 14,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.cardButtonEdit,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.confirmDeletionTitle,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.confirmDeletionMessage(site.title),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.cardButtonDelete,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await adminDeleteWebsite(site.id);
                                ref
                                    .read(
                                      adminWebsitesPaginatedProvider.notifier,
                                    )
                                    .reset();
                                ref.invalidate(adminWebsitesProvider);
                                ref.invalidate(discoverWebsitesProvider);
                                ref.invalidate(trendingWebsitesProvider);
                                ref.invalidate(popularWebsitesProvider);
                                ref.invalidate(featuredWebsitesProvider);
                              }
                            },
                            icon: Icon(PhosphorIcons.trash(), size: 16),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            color: Colors.red,
                            tooltip: AppLocalizations.of(
                              context,
                            )!.cardButtonDelete,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'prompt':
        return PhosphorIcons.sparkle();
      case 'offer':
        return PhosphorIcons.tag();
      case 'announcement':
        return PhosphorIcons.megaphone();
      case 'tutorial':
        return PhosphorIcons.chalkboardTeacher();
      case 'tool':
        return PhosphorIcons.wrench();
      case 'course':
        return PhosphorIcons.graduationCap();
      default:
        return PhosphorIcons.globe();
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'prompt':
        return const Color(0xFF9C27B0);
      case 'offer':
        return const Color(0xFFFF9800);
      case 'announcement':
        return const Color(0xFF2196F3);
      case 'tutorial':
        return const Color(0xFFE91E63);
      case 'tool':
        return const Color(0xFF607D8B);
      case 'course':
        return const Color(0xFF4CAF50);
      default:
        return AppTheme.primaryColor;
    }
  }

  String _typeDisplayName(BuildContext context, String type) {
    switch (type) {
      case 'prompt':
        return AppLocalizations.of(context)!.badgePrompt;
      case 'offer':
        return AppLocalizations.of(context)!.badgeOffer;
      case 'announcement':
        return AppLocalizations.of(context)!.badgeAnnounce;
      case 'tutorial':
        return AppLocalizations.of(context)!.badgeTutorial;
      case 'tool':
        return AppLocalizations.of(context)!.toolBadge;
      case 'course':
        return AppLocalizations.of(context)!.courseBadge;
      default:
        return AppLocalizations.of(context)!.badgeWebsite;
    }
  }

  Widget _placeholderImage(
    BuildContext context,
    bool isDark,
    String contentType,
  ) {
    return Container(
      height: 120,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _typeIcon(contentType),
              size: 32,
              color: _typeColor(contentType).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              _typeDisplayName(context, contentType),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
