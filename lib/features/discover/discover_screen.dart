import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/text_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/notification_badge.dart';
import '../../presentation/widgets/website_details_dialog.dart';
import '../../presentation/widgets/shimmer_loading.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/widgets/advertisement_carousel.dart';
import '../../data/models/collection_model.dart';
import 'widgets/discover_filter_bottom_sheet.dart';
import 'widgets/discover_quick_filter_bar.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trendingState = ref.watch(trendingPaginatedProvider);
    final popularState = ref.watch(popularPaginatedProvider);
    final featuredState = ref.watch(featuredPaginatedProvider);
    final discoverState = ref.watch(discoverPaginatedProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final search = ref.watch(discoverSearchProvider);
    final collectionsAsync = ref.watch(featuredCollectionsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            title: Text(
              AppLocalizations.of(context)!.discoverTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
            ),
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            actions: [
              // Community Button
              IconButton(
                onPressed: () => context.push('/community'),
                icon: Icon(
                  PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                  color: AppTheme.primaryColor,
                  size: 26,
                ),
                tooltip: AppLocalizations.of(context)!.actionCommunity,
              ),
              // Bookmark toggle
              IconButton(
                onPressed: () {
                  final current = ref.read(showBookmarksOnlyProvider);
                  ref.read(showBookmarksOnlyProvider.notifier).state = !current;
                  if (!current) {
                    ref.invalidate(bookmarkedWebsitesProvider);
                  }
                },
                icon: Icon(
                  ref.watch(showBookmarksOnlyProvider)
                      ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                      : PhosphorIcons.bookmarkSimple(),
                  color: ref.watch(showBookmarksOnlyProvider)
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                tooltip: AppLocalizations.of(context)!.actionBookmarks,
              ),
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: NotificationBadge(
                  child: Icon(
                    PhosphorIcons.bell(),
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),

          // ── Sticky Search + Filter Bar ──
          if (!ref.watch(showBookmarksOnlyProvider))
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 68,
              backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  children: [
                    // ── Search Bar ──
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          onChanged: (v) {
                            ref.read(discoverSearchProvider.notifier).state = v;
                            if (_searchDebounce?.isActive ?? false) {
                              _searchDebounce!.cancel();
                            }
                            _searchDebounce = Timer(
                              const Duration(milliseconds: 1500),
                              () {
                                if (v.trim().isNotEmpty) {
                                  AnalyticsService.trackSearch(v);
                                }
                              },
                            );
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.searchDiscover,
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              PhosphorIcons.magnifyingGlass(),
                              size: 20,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkCard
                                : AppTheme.lightCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Filter Button ──
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => const DiscoverFilterBottomSheet(),
                        );
                      },
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkCard
                              : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.faders(),
                              size: 22,
                              color:
                                  (ref.watch(selectedContentTypeProvider) !=
                                          null ||
                                      ref.watch(selectedCategoryProvider) !=
                                          null)
                                  ? AppTheme.primaryColor
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            if (ref.watch(selectedContentTypeProvider) !=
                                    null ||
                                ref.watch(selectedCategoryProvider) != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!ref.watch(showBookmarksOnlyProvider))
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: DiscoverQuickFilterBar(),
              ),
            ),

          // Advertisement Panel
          const SliverToBoxAdapter(
            child: AdvertisementCarousel(
              targetScreen: 'discover',
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            ),
          ),

          if (ref.watch(showBookmarksOnlyProvider)) ...[
            // Search bar (non-sticky in bookmarks mode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  onChanged: (v) {
                    ref.read(discoverSearchProvider.notifier).state = v;
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchBookmarks,
                    prefixIcon: Icon(
                      PhosphorIcons.magnifyingGlass(),
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Bookmarks View
            SliverToBoxAdapter(
              child: ref
                  .watch(bookmarkedWebsitesProvider)
                  .when(
                    data: (sites) {
                      if (sites.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Column(
                            children: [
                              Icon(
                                PhosphorIcons.bookmarkSimple(),
                                size: 64,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noItemsYet,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the bookmark icon on any item to save it here',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _buildSection(
                        context,
                        ref,
                        AppLocalizations.of(context)!.bookmarks,
                        PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
                        sites,
                        isDark,
                      );
                    },
                    loading: () => _buildShimmerSection(isDark),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: OfflineWarningWidget(error: e),
                    ),
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ] else if (!trendingState.isInitialLoad &&
              !popularState.isInitialLoad &&
              !featuredState.isInitialLoad &&
              !discoverState.isInitialLoad &&
              trendingState.items.isEmpty &&
              popularState.items.isEmpty &&
              featuredState.items.isEmpty &&
              discoverState.items.isEmpty) ...[
            SliverFillRemaining(
              hasScrollBody: false,
              child:
                  (trendingState.error != null ||
                      popularState.error != null ||
                      featuredState.error != null ||
                      discoverState.error != null)
                  ? OfflineWarningWidget(
                      error:
                          trendingState.error ??
                          popularState.error ??
                          featuredState.error ??
                          discoverState.error ??
                          'Unknown Error',
                    )
                  : _buildEmptyState(isDark),
            ),
          ] else ...[
            // Trending Section
            SliverToBoxAdapter(
              child: trendingState.isInitialLoad
                  ? _buildShimmerSection(isDark)
                  : trendingState.items.isEmpty
                  ? const SizedBox()
                  : _buildPaginatedSection(
                      context,
                      ref,
                      AppLocalizations.of(context)!.sectionTrending,
                      PhosphorIcons.trendUp(),
                      trendingState,
                      trendingPaginatedProvider,
                      isDark,
                      showBadge: true,
                    ),
            ),

            // Popular Section
            SliverToBoxAdapter(
              child: popularState.isInitialLoad
                  ? _buildShimmerSection(isDark)
                  : popularState.items.isEmpty
                  ? const SizedBox()
                  : _buildPaginatedSection(
                      context,
                      ref,
                      AppLocalizations.of(context)!.sectionPopular,
                      PhosphorIcons.fire(),
                      popularState,
                      popularPaginatedProvider,
                      isDark,
                    ),
            ),

            // Featured Section
            SliverToBoxAdapter(
              child: featuredState.isInitialLoad
                  ? _buildShimmerSection(isDark)
                  : featuredState.items.isEmpty
                  ? const SizedBox()
                  : _buildPaginatedSection(
                      context,
                      ref,
                      AppLocalizations.of(context)!.sectionFeatured,
                      PhosphorIcons.star(),
                      featuredState,
                      featuredPaginatedProvider,
                      isDark,
                    ),
            ),

            // Featured Collections Section
            SliverToBoxAdapter(
              child: collectionsAsync.when(
                data: (collections) {
                  if (collections.isEmpty) return const SizedBox();
                  return _buildCollectionsSection(context, collections, isDark);
                },
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),
            ),

            // All / Filter Results Section — Two Horizontal Rows
            if (discoverState.isInitialLoad)
              SliverToBoxAdapter(child: _buildShimmerSection(isDark))
            else if (discoverState.items.isNotEmpty) ...[
              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.stack(),
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (selected != null || search.isNotEmpty)
                            ? 'Results'
                            : AppLocalizations.of(context)!.sectionNewlyAdded,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
              ),
              // Two Independent Horizontal Rows
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final row1Items = <WebsiteModel>[];
                    final row2Items = <WebsiteModel>[];
                    for (int i = 0; i < discoverState.items.length; i++) {
                      if (i.isEven) {
                        row1Items.add(discoverState.items[i]);
                      } else {
                        row2Items.add(discoverState.items[i]);
                      }
                    }

                    return Column(
                      children: [
                        // Row 1
                        SizedBox(
                          height: 290,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200) {
                                ref
                                    .read(discoverPaginatedProvider.notifier)
                                    .loadMore();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount:
                                  row1Items.length +
                                  (discoverState.hasMore ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i >= row1Items.length) {
                                  return const ShimmerCard();
                                }
                                int originalIndex = i * 2;
                                return _buildDiscoverCard(
                                  context,
                                  ref,
                                  row1Items[i],
                                  isDark,
                                  false,
                                  originalIndex,
                                );
                              },
                            ),
                          ),
                        ),
                        if (row2Items.isNotEmpty || discoverState.hasMore) ...[
                          const SizedBox(height: 14),
                          // Row 2
                          SizedBox(
                            height: 290,
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (scrollInfo) {
                                if (scrollInfo.metrics.pixels >=
                                    scrollInfo.metrics.maxScrollExtent - 200) {
                                  ref
                                      .read(discoverPaginatedProvider.notifier)
                                      .loadMore();
                                }
                                return false;
                              },
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount:
                                    row2Items.length +
                                    (discoverState.hasMore ? 1 : 0),
                                itemBuilder: (ctx, i) {
                                  if (i >= row2Items.length) {
                                    return const ShimmerCard();
                                  }
                                  int originalIndex = i * 2 + 1;
                                  return _buildDiscoverCard(
                                    context,
                                    ref,
                                    row2Items[i],
                                    isDark,
                                    false,
                                    originalIndex,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  // ── Collections Section Builder ──
  Widget _buildCollectionsSection(
    BuildContext context,
    List<CollectionModel> collections,
    bool isDark,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.folderStar(PhosphorIconsStyle.fill),
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.collectionsTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: collections.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final col = collections[i];
                final color = Color(col.colorValue);
                return GestureDetector(
                  onTap: () => context.push('/collection-items', extra: col),
                  child: Container(
                    width: 130,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background Layer (Image or Color Gradient)
                        if (col.coverImageUrl != null &&
                            col.coverImageUrl!.isNotEmpty)
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: col.coverImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.8), color],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),

                        // Dark/Gradient Overlay to make text readable
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Content (Icon and Title)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Spacer(),
                              Text(
                                col.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (col.itemCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${col.itemCount} items',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Full Screen Image Viewer ──
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Builder ──
  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    List<WebsiteModel> sites,
    bool isDark, {
    bool showBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 14),
          SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sites.length,
              itemBuilder: (ctx, i) => _buildDiscoverCard(
                context,
                ref,
                sites[i],
                isDark,
                showBadge,
                i,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Paginated version of _buildSection — detects horizontal scroll end to load more
  Widget _buildPaginatedSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    PaginatedWebsitesState pState,
    AutoDisposeStateNotifierProvider<
      PaginatedWebsitesNotifier,
      PaginatedWebsitesState
    >
    provider,
    bool isDark, {
    bool showBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 14),
          SizedBox(
            height: 290,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
                  ref.read(provider.notifier).loadMore();
                }
                return false;
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: pState.items.length + (pState.hasMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i >= pState.items.length) {
                    // Shimmer trailing loader
                    return const ShimmerCard();
                  }
                  return _buildDiscoverCard(
                    context,
                    ref,
                    pState.items[i],
                    isDark,
                    showBadge,
                    i,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dynamic Card Builder ──
  Widget _buildDiscoverCard(
    BuildContext context,
    WidgetRef ref,
    WebsiteModel site,
    bool isDark,
    bool showBadge,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => WebsiteDetailsDialog(site: site),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 14),
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
                    child: GestureDetector(
                      onTap: () {
                        if (site.imageUrl != null &&
                            site.imageUrl!.isNotEmpty) {
                          _showFullImage(context, site.imageUrl!);
                        }
                      },
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
                          : _placeholderImage(
                              context,
                              isDark,
                              site.contentType,
                            ),
                    ),
                  ),
                  // Trending badge
                  if (showBadge)
                    Positioned(
                      top: 8,
                      left: 8,
                      child:
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFFF8E53),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PhosphorIcons.trendUp(),
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.badgeTrending,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
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
                              _typeLabel(context, site.contentType),
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
                  // Video badge
                  if (site.hasVideo)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Expiry badge
                  if (site.expiresAt != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 10,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatTimeLeft(site.expiresAt!),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (site.pricingModel != 'free' &&
                            site.pricingModel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: site.pricingModel == 'paid'
                                  ? Colors.redAccent.withValues(alpha: 0.15)
                                  : Colors.orangeAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: site.pricingModel == 'paid'
                                    ? Colors.redAccent.withValues(alpha: 0.3)
                                    : Colors.orangeAccent.withValues(
                                        alpha: 0.3,
                                      ),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              site.pricingModel == 'paid'
                                  ? AppLocalizations.of(
                                      context,
                                    )!.pricingPaid.toUpperCase()
                                  : AppLocalizations.of(
                                      context,
                                    )!.pricingFreemium.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: site.pricingModel == 'paid'
                                    ? (isDark
                                          ? Colors.redAccent.shade100
                                          : Colors.redAccent.shade700)
                                    : (isDark
                                          ? Colors.orangeAccent.shade100
                                          : Colors.orange.shade800),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // For prompts/offers: show the copyable value preview
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
                          if (TextUtils.getPlainTextFromDescription(
                                    site.description,
                                  ).length >
                                  50 &&
                              !site.hasCopyableValue)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Read more...',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (site.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: site.tags
                            .take(6)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // ── Dynamic Action Buttons ──
                    _buildActionButtons(context, ref, site, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
  }

  // ── Action Buttons per content type ──
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    WebsiteModel site,
    bool isDark,
  ) {
    switch (site.contentType) {
      case 'prompt':
        return Row(
          children: [
            // Copy button
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(context, site.actionValue),
                  icon: Icon(PhosphorIcons.copy(), size: 14),
                  label: Text(
                    AppLocalizations.of(context)!.copyButton,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            // Try button (only if URL exists)
            if (site.hasUrl) ...[
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  onPressed: () =>
                      context.push('/discover-browser', extra: site),
                  icon: Icon(PhosphorIcons.arrowSquareOut(), size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  color: isDark ? Colors.white70 : Colors.black54,
                  tooltip: 'Try Prompt',
                ),
              ),
            ],
            const SizedBox(width: 6),
            _bookmarkButton(ref, site, isDark),
          ],
        );

      case 'offer':
        return Row(
          children: [
            // Copy code button
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: site.hasCopyableValue
                      ? () => _copyToClipboard(context, site.actionValue)
                      : null,
                  icon: Icon(PhosphorIcons.key(), size: 14),
                  label: Text(
                    site.hasCopyableValue
                        ? AppLocalizations.of(context)!.copyButton
                        : AppLocalizations.of(context)!.detailsButton,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            if (site.hasUrl) ...[
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  onPressed: () =>
                      context.push('/discover-browser', extra: site),
                  icon: Icon(PhosphorIcons.globe(), size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  color: isDark ? Colors.white70 : Colors.black54,
                  tooltip: 'Visit',
                ),
              ),
            ],
            const SizedBox(width: 6),
            _bookmarkButton(ref, site, isDark),
          ],
        );

      case 'announcement':
      case 'tutorial':
        final isAnnouncement = site.contentType == 'announcement';
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => WebsiteDetailsDialog(site: site),
                    );
                  },
                  icon: Icon(
                    isAnnouncement
                        ? PhosphorIcons.article()
                        : PhosphorIcons.chalkboardTeacher(),
                    size: 14,
                  ),
                  label: Text(
                    isAnnouncement
                        ? AppLocalizations.of(context)!.actionRead
                        : AppLocalizations.of(context)!.actionView,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAnnouncement
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            if (site.hasUrl) ...[
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  onPressed: () =>
                      context.push('/discover-browser', extra: site),
                  icon: Icon(PhosphorIcons.globe(), size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  color: isDark ? Colors.white70 : Colors.black54,
                  tooltip: 'Visit',
                ),
              ),
            ],
            const SizedBox(width: 6),
            _bookmarkButton(ref, site, isDark),
          ],
        );

      case 'tool':
      case 'course':
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: site.hasUrl
                      ? () => context.push('/discover-browser', extra: site)
                      : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => WebsiteDetailsDialog(site: site),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor(site.contentType),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    site.hasUrl
                        ? AppLocalizations.of(context)!.openButton
                        : AppLocalizations.of(context)!.detailsButton,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (site.hasUrl) ...[
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  onPressed: () => _openUrl(site.url, inApp: false),
                  icon: Icon(PhosphorIcons.globe(), size: 18),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  color: isDark ? Colors.white70 : Colors.black54,
                  tooltip: 'Open in Browser',
                ),
              ),
            ],
            const SizedBox(width: 6),
            _bookmarkButton(ref, site, isDark),
          ],
        );

      default: // website
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: site.hasUrl
                      ? () => context.push('/discover-browser', extra: site)
                      : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => WebsiteDetailsDialog(site: site),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    site.hasUrl
                        ? AppLocalizations.of(context)!.openButton
                        : AppLocalizations.of(context)!.detailsButton,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (site.hasUrl) ...[
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                width: 32,
                child: IconButton(
                  onPressed: () => _openUrl(site.url, inApp: false),
                  icon: Icon(PhosphorIcons.globe(), size: 18),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  color: isDark ? Colors.white70 : Colors.black54,
                  tooltip: 'Open in Browser',
                ),
              ),
            ],
            const SizedBox(width: 6),
            _bookmarkButton(ref, site, isDark),
          ],
        );
    }
  }

  Widget _bookmarkButton(WidgetRef ref, WebsiteModel site, bool isDark) {
    final bookmarkedIds = ref.watch(bookmarkedIdsProvider).valueOrNull ?? {};
    final isBookmarked = bookmarkedIds.contains(site.id);

    return SizedBox(
      height: 32,
      width: 32,
      child: IconButton(
        onPressed: () async {
          await toggleBookmark(site.id);
          ref.invalidate(bookmarkedIdsProvider);
          ref.invalidate(bookmarkedWebsitesProvider);
          AnalyticsService.trackBookmark(site.id, !isBookmarked);
        },
        icon: Icon(
          isBookmarked
              ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
              : PhosphorIcons.bookmarkSimple(),
          size: 18,
        ),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: isBookmarked
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        color: isBookmarked
            ? AppTheme.primaryColor
            : (isDark ? Colors.white54 : Colors.black45),
      ),
    );
  }

  // ── Placeholder image based on content type ──
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
              _typeLabel(context, contentType),
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

  Widget _buildShimmerSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.white12 : Colors.grey.shade300,
              highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
              child: Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (ctx, i) => Shimmer.fromColors(
                baseColor: isDark ? Colors.white12 : Colors.grey.shade300,
                highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
              PhosphorIcons.compass(PhosphorIconsStyle.duotone),
              color: AppTheme.primaryColor,
              size: 40,
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          Text(
            'Nothing to discover yet',
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
            'Check back soon for trending content!',
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

  // ── Utilities ──

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

  String _typeLabel(BuildContext context, String type) {
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

  String _formatTimeLeft(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl(String url, {bool inApp = true}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
      );
    }
  }
}
