import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/shimmer_loading.dart';

class ManageWebsitesScreen extends ConsumerStatefulWidget {
  const ManageWebsitesScreen({super.key});

  @override
  ConsumerState<ManageWebsitesScreen> createState() =>
      _ManageWebsitesScreenState();
}

class _ManageWebsitesScreenState extends ConsumerState<ManageWebsitesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(adminWebsitesPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pState = ref.watch(adminWebsitesPaginatedProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Manage Items'),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/admin/websites/edit'),
          ),
        ],
      ),
      body: pState.isInitialLoad
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(5, (_) => const ShimmerAdminTile()),
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
                  const Text(
                    'No items yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add one',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: pState.items.length + (pState.hasMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i >= pState.items.length) {
                  return const ShimmerAdminTile();
                }
                return _websiteTile(context, ref, pState.items[i], isDark, i);
              },
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _typeColor(site.contentType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _typeIcon(site.contentType),
              color: _typeColor(site.contentType),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  site.url,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    if (site.contentType != 'website')
                      _badge(
                        _typeDisplayName(site.contentType),
                        _typeColor(site.contentType),
                        isDark,
                      ),
                    if (catName != null)
                      _badge(catName!, AppTheme.primaryColor, isDark),
                    if (site.isTrending)
                      _badge('Trending', const Color(0xFFFF6B6B), isDark),
                    if (site.isPopular)
                      _badge('Popular', const Color(0xFFFF9800), isDark),
                    if (site.isFeatured)
                      _badge('Featured', const Color(0xFF4CAF50), isDark),
                    if (!site.isActive) _badge('Inactive', Colors.grey, isDark),
                    if (site.isExpired) _badge('Expired', Colors.red, isDark),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                context.push('/admin/websites/edit', extra: site);
              } else if (v == 'delete') {
                await adminDeleteWebsite(site.id);
                ref.read(adminWebsitesPaginatedProvider.notifier).reset();
                ref.invalidate(adminWebsitesProvider);
                ref.invalidate(discoverWebsitesProvider);
                ref.invalidate(trendingWebsitesProvider);
                ref.invalidate(popularWebsitesProvider);
                ref.invalidate(featuredWebsitesProvider);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.04);
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

  String _typeDisplayName(String type) {
    switch (type) {
      case 'prompt':
        return 'Prompt';
      case 'offer':
        return 'Offer';
      case 'announcement':
        return 'Announce';
      default:
        return 'Website';
    }
  }
}
