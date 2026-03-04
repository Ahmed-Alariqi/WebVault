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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(
              'Discover',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
            ),
            forceMaterialTransparency: true,
            actions: [
              // Community Button
              IconButton(
                onPressed: () => context.push('/community'),
                icon: Icon(
                  PhosphorIcons.globeHemisphereWest(PhosphorIconsStyle.fill),
                  color: AppTheme.primaryColor,
                  size: 26,
                ),
                tooltip: 'Community',
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
                tooltip: 'Bookmarks',
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
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchFilterDelegate(
                isDark: isDark,
                ref: ref,
                onSearchChanged: (v) {
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
                    hintText: 'Search bookmarks...',
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
                                'No bookmarks yet',
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
                        'Your Bookmarks',
                        PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
                        sites,
                        isDark,
                      );
                    },
                    loading: () => _buildShimmerSection(isDark),
                    error: (e, st) => const SizedBox(),
                  ),
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
                      'Trending',
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
                      'Popular',
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
                      'Featured',
                      PhosphorIcons.star(),
                      featuredState,
                      featuredPaginatedProvider,
                      isDark,
                    ),
            ),

            // All / Filter Results Section
            SliverToBoxAdapter(
              child: discoverState.isInitialLoad
                  ? _buildShimmerSection(isDark)
                  : discoverState.items.isEmpty
                  ? const SizedBox()
                  : _buildPaginatedSection(
                      context,
                      ref,
                      (selected != null || search.isNotEmpty)
                          ? 'Results'
                          : 'Newly Added',
                      PhosphorIcons.stack(),
                      discoverState,
                      discoverPaginatedProvider,
                      isDark,
                    ),
            ),

            // Offline Error State — show only when all sections are empty + initial load done
            if (!trendingState.isInitialLoad &&
                !popularState.isInitialLoad &&
                !featuredState.isInitialLoad &&
                !discoverState.isInitialLoad &&
                trendingState.items.isEmpty &&
                popularState.items.isEmpty &&
                featuredState.items.isEmpty &&
                discoverState.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(isDark),
              ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                            errorWidget: (ctx, url, err) =>
                                _placeholderImage(isDark, site.contentType),
                          )
                        : _placeholderImage(isDark, site.contentType),
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
                                    const Text(
                                      'Trending',
                                      style: TextStyle(
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
                              _typeLabel(site.contentType),
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
                  label: const Text(
                    'Copy',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                    site.hasCopyableValue ? 'Copy Code' : 'View',
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
                  icon: Icon(PhosphorIcons.article(), size: 14),
                  label: const Text(
                    'Read',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
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

      default: // website
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () =>
                      context.push('/discover-browser', extra: site),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
  Widget _placeholderImage(bool isDark, String contentType) {
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
              _typeLabel(contentType),
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
      default:
        return AppTheme.primaryColor;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'prompt':
        return 'Prompt';
      case 'offer':
        return 'Offer';
      case 'announcement':
        return 'News';
      default:
        return 'Website';
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

// ════════════════════════════════════════════════════════════════════════════
// Sticky Search + Filter Header Delegate
// ════════════════════════════════════════════════════════════════════════════

class _StickySearchFilterDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final WidgetRef ref;
  final ValueChanged<String> onSearchChanged;

  static const double _maxExtent = 148.0;
  static const double _minExtent = 148.0;

  // Type filter definitions (must match the ones in _DiscoverScreenState)
  static const _typeFilters = [
    {'value': null, 'label': 'All', 'icon': 'all'},
    {'value': 'website', 'label': 'Websites', 'icon': 'website'},
    {'value': 'prompt', 'label': 'Prompts', 'icon': 'prompt'},
    {'value': 'offer', 'label': 'Offers', 'icon': 'offer'},
    {'value': 'announcement', 'label': 'News', 'icon': 'announcement'},
  ];

  _StickySearchFilterDelegate({
    required this.isDark,
    required this.ref,
    required this.onSearchChanged,
  });

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant _StickySearchFilterDelegate oldDelegate) {
    return isDark != oldDelegate.isDark;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: shrinkOffset > 0
                ? (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06))
                : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: SizedBox(
              height: 44,
              child: TextField(
                onChanged: onSearchChanged,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search discover...',
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
                  fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
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

          // ── Content Type Tabs ──
          SizedBox(height: 42, child: _buildTypeTabs(context)),

          // ── Category Chips ──
          SizedBox(height: 42, child: _buildCategoryChips()),
        ],
      ),
    );
  }

  Widget _buildTypeTabs(BuildContext context) {
    final selectedType = ref.watch(selectedContentTypeProvider);

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _typeFilters.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final filter = _typeFilters[index];
        final value = filter['value'];
        final label = filter['label'] as String;
        final iconKey = filter['icon'] as String;
        final isActive = selectedType == value;

        IconData icon;
        Color activeColor;
        switch (iconKey) {
          case 'website':
            icon = PhosphorIcons.globe(
              isActive ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
            );
            activeColor = const Color(0xFF6366F1);
            break;
          case 'prompt':
            icon = PhosphorIcons.lightbulb(
              isActive ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
            );
            activeColor = const Color(0xFFEC4899);
            break;
          case 'offer':
            icon = PhosphorIcons.tag(
              isActive ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
            );
            activeColor = const Color(0xFFF59E0B);
            break;
          case 'announcement':
            icon = PhosphorIcons.megaphone(
              isActive ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
            );
            activeColor = const Color(0xFF489DFC);
            break;
          default:
            icon = PhosphorIcons.squaresFour(
              isActive ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
            );
            activeColor = AppTheme.primaryColor;
        }

        return GestureDetector(
          onTap: () =>
              ref.read(selectedContentTypeProvider.notifier).state = value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.3)
                    : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.06)),
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? activeColor
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? activeColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return categories.when(
      data: (cats) {
        if (cats.isEmpty) return const SizedBox();
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: cats.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final isActive = isAll
                ? selected == null
                : selected == cats[index - 1].id;
            final label = isAll ? 'All' : cats[index - 1].name;
            final onTap = isAll
                ? () => ref.read(selectedCategoryProvider.notifier).state = null
                : () => ref.read(selectedCategoryProvider.notifier).state =
                      cats[index - 1].id;

            return GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.15)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primaryColor.withValues(alpha: 0.3)
                        : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.06)),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
    );
  }
}
