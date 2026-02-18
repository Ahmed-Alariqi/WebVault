import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/discover_providers.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trending = ref.watch(trendingWebsitesProvider);
    final popular = ref.watch(popularWebsitesProvider);
    final featured = ref.watch(featuredWebsitesProvider);

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
              IconButton(
                icon: Icon(
                  PhosphorIcons.bell(),
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                onChanged: (v) =>
                    ref.read(discoverSearchProvider.notifier).state = v,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search websites & tools...',
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
            ).animate().fadeIn(),
          ),

          // Category Chips
          SliverToBoxAdapter(child: _buildCategoryChips(ref, isDark)),

          // Trending Section
          SliverToBoxAdapter(
            child: trending.when(
              data: (sites) => sites.isEmpty
                  ? const SizedBox()
                  : _buildSection(
                      context,
                      ref,
                      'Trending',
                      PhosphorIcons.trendUp(),
                      sites,
                      isDark,
                      showBadge: true,
                    ),
              loading: () => _buildShimmerSection(isDark),
              error: (e, st) => const SizedBox(),
            ),
          ),

          // Popular Section
          SliverToBoxAdapter(
            child: popular.when(
              data: (sites) => sites.isEmpty
                  ? const SizedBox()
                  : _buildSection(
                      context,
                      ref,
                      'Popular',
                      PhosphorIcons.fire(),
                      sites,
                      isDark,
                    ),
              loading: () => _buildShimmerSection(isDark),
              error: (e, st) => const SizedBox(),
            ),
          ),

          // Featured Section
          SliverToBoxAdapter(
            child: featured.when(
              data: (sites) => sites.isEmpty
                  ? const SizedBox()
                  : _buildSection(
                      context,
                      ref,
                      'Featured',
                      PhosphorIcons.star(),
                      sites,
                      isDark,
                    ),
              loading: () => _buildShimmerSection(isDark),
              error: (e, st) => const SizedBox(),
            ),
          ),

          // Empty State
          if (trending.valueOrNull?.isEmpty == true &&
              popular.valueOrNull?.isEmpty == true &&
              featured.valueOrNull?.isEmpty == true)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(isDark),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(WidgetRef ref, bool isDark) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return categories.when(
      data: (cats) {
        if (cats.isEmpty) return const SizedBox(height: 8);
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _chip(
                'All',
                selected == null,
                isDark,
                () => ref.read(selectedCategoryProvider.notifier).state = null,
              ),
              ...cats.map(
                (c) => _chip(
                  c.name,
                  selected == c.id,
                  isDark,
                  () =>
                      ref.read(selectedCategoryProvider.notifier).state = c.id,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (e, st) => const SizedBox(height: 8),
    );
  }

  Widget _chip(String label, bool active, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
            borderRadius: BorderRadius.circular(12),
            border: active
                ? null
                : Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

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
            height: 280, // Increased height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sites.length,
              itemBuilder: (ctx, i) => _buildWebsiteCard(
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

  Widget _buildWebsiteCard(
    BuildContext context,
    WidgetRef ref,
    WebsiteModel site,
    bool isDark,
    bool showBadge,
    int index,
  ) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 120, // Increased image height slightly
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
                                PhosphorIcons.image(),
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ),
                          errorWidget: (ctx, url, err) =>
                              _placeholderImage(isDark),
                        )
                      : _placeholderImage(isDark),
                ),
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
              ],
            ),
          ),

          // Content
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
                    child: Text(
                      site.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 3, // Increased lines
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _openUrl(site.url, inApp: true),
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
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: IconButton(
                          onPressed: () => _saveSite(ref, site),
                          icon: Icon(PhosphorIcons.bookmarkSimple(), size: 18),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          color: isDark ? Colors.white54 : Colors.black45,
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
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
  }

  Widget _placeholderImage(bool isDark) {
    return Container(
      height: 120,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          PhosphorIcons.globe(),
          size: 32,
          color: isDark ? Colors.white24 : Colors.black12,
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
            height: 280,
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

  Future<void> _openUrl(String url, {bool inApp = true}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _saveSite(WidgetRef ref, WebsiteModel site) async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      await client.from('user_saved_websites').upsert({
        'user_id': user.id,
        'website_id': site.id,
      });
      ref.invalidate(savedWebsiteIdsProvider);
    } catch (_) {}
  }
}
