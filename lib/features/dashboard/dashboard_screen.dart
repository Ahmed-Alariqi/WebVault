import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../presentation/widgets/notification_badge.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/suggestion_dialog.dart';
import '../../presentation/widgets/advertisement_carousel.dart';
import '../../data/models/page_model.dart';
import '../../data/models/clipboard_item_model.dart';
import '../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ref.watch(dashboardStatsProvider);
    final totalPages = stats['totalPages'] as int;
    final favCount = stats['favoritesCount'] as int;
    final foldersCount = stats['foldersCount'] as int;
    final clipboardCount = stats['clipboardCount'] as int;
    final mostVisited = stats['mostVisited'] as PageModel?;
    final recentPages = stats['recentPages'] as List<PageModel>;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // Dynamic modern App Bar/Header
          SliverToBoxAdapter(child: _DashboardHeader(isDark: isDark)),

          // Advertisement Panel
          const SliverToBoxAdapter(
            child: AdvertisementCarousel(
              targetScreen: 'home',
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Actions Grid
                const _QuickActions(),
                const SizedBox(height: 20),

                // Search Bar
                _SearchBar(isDark: isDark),
                const SizedBox(height: 24),

                // Stats Section Header
                _SectionHeader(
                  title: AppLocalizations.of(context)!.vaultOverview,
                  icon: PhosphorIcons.chartBar(),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Premium Compact Stats Grid (2×2)
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatCard(
                        icon: PhosphorIcons.browsers(
                          PhosphorIconsStyle.duotone,
                        ),
                        label: AppLocalizations.of(context)!.totalPages,
                        value: '$totalPages',
                        color: AppTheme.primaryColor,
                        isDark: isDark,
                        index: 0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactStatCard(
                        icon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
                        label: AppLocalizations.of(context)!.favorites,
                        value: '$favCount',
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                        index: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatCard(
                        icon: PhosphorIcons.folderOpen(
                          PhosphorIconsStyle.duotone,
                        ),
                        label: AppLocalizations.of(context)!.folders,
                        value: '$foldersCount',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        index: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactStatCard(
                        icon: PhosphorIcons.clipboardText(
                          PhosphorIconsStyle.duotone,
                        ),
                        label: AppLocalizations.of(context)!.clipboard,
                        value: '$clipboardCount',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        index: 3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Top Vault / Most Visited
                if (mostVisited != null) ...[
                  _SectionHeader(
                    title: AppLocalizations.of(context)!.topVault,
                    icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _TopVaultCard(page: mostVisited, isDark: isDark),
                  const SizedBox(height: 32),
                ],

                // Recent activity
                if (recentPages.isNotEmpty) ...[
                  _SectionHeader(
                    title: AppLocalizations.of(context)!.recentActivity,
                    icon: PhosphorIcons.clockCounterClockwise(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  ...recentPages.asMap().entries.map(
                    (entry) => _RecentItem(
                      page: entry.value,
                      isDark: isDark,
                      index: entry.key,
                      onSuggestion: () => showSuggestionDialog(
                        context,
                        ref,
                        title: entry.value.title,
                        url: entry.value.url,
                      ),
                    ),
                  ),
                ] else if (totalPages == 0)
                  _EmptyState(isDark: isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  final bool isDark;

  const _DashboardHeader({required this.isDark});

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 17) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  void _showProfilePreview(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfilePreviewSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationCountProvider).valueOrNull ?? 0;
    final hasUnread = unreadCount > 0;
    final isAdmin = ref.watch(hasAdminAccessProvider).valueOrNull ?? false;
    final chatUnreadCount =
        ref.watch(userUnreadCountStreamProvider).valueOrNull ?? 0;
    final hasUnreadChats = chatUnreadCount > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
              ],
            ),
          ),

          if (isAdmin) ...[
            IconButton(
              onPressed: () => context.push('/admin'),
              icon: Icon(
                PhosphorIcons.crown(PhosphorIconsStyle.fill),
                size: 24,
                color: AppTheme.primaryColor,
              ),
              tooltip: AppLocalizations.of(context)!.adminDashboard,
            ).animate().fadeIn().scale(),
            const SizedBox(width: 8),
          ],

          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: NotificationBadge(
              child: Icon(
                hasUnread
                    ? PhosphorIcons.bellRinging(PhosphorIconsStyle.fill)
                    : PhosphorIcons.bell(),
                size: 24,
                color: hasUnread
                    ? AppTheme.primaryColor
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showProfilePreview(context, isDark),
            child: _HeaderAvatar(
              isDark: isDark,
              hasUnreadChats: hasUnreadChats,
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionBtn(
          icon: PhosphorIcons.plus(),
          label: AppLocalizations.of(context)!.newPage,
          color: const Color(0xFF6366F1),
          onTap: () => context.push('/add-page'),
          delay: 0,
        ),
        _QuickActionBtn(
          icon: PhosphorIcons.folderPlus(),
          label: AppLocalizations.of(context)!.folders,
          color: const Color(0xFF10B981),
          onTap: () => context.push('/folders'),
          delay: 100,
        ),
        _QuickActionBtn(
          icon: PhosphorIcons.clipboardText(),
          label: AppLocalizations.of(context)!.clipboard,
          color: const Color(0xFFF59E0B),
          onTap: () => context.push('/clipboard'),
          delay: 200,
        ),
        _QuickActionBtn(
          icon: PhosphorIcons.bookmarkSimple(),
          label: AppLocalizations.of(context)!.bookmarks,
          color: const Color(0xFFEC4899),
          onTap: () {
            ref.read(showBookmarksOnlyProvider.notifier).state = true;
            ref.invalidate(bookmarkedWebsitesProvider);
            context.go('/discover');
          },
          delay: 300,
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final int index;

  const _CompactStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.04 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (300 + (index * 80)).ms).slideY(begin: 0.1);
  }
}

class _SearchBar extends ConsumerWidget {
  final bool isDark;

  const _SearchBar({required this.isDark});

  void _openSearch(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlobalSearchSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openSearch(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.magnifyingGlass(),
              size: 20,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.searchPagesAndClipboard,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                PhosphorIcons.funnelSimple(),
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}

class _GlobalSearchSheet extends ConsumerStatefulWidget {
  final bool isDark;

  const _GlobalSearchSheet({required this.isDark});

  @override
  ConsumerState<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends ConsumerState<_GlobalSearchSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final pages = ref.watch(pagesProvider);
    final clipboardItems = ref.watch(clipboardItemsProvider);

    // Filter
    final q = _query.toLowerCase();
    final matchedPages = q.isEmpty
        ? <PageModel>[]
        : pages
              .where(
                (p) =>
                    p.title.toLowerCase().contains(q) ||
                    p.url.toLowerCase().contains(q) ||
                    p.tags.any((t) => t.toLowerCase().contains(q)),
              )
              .toList();

    final matchedClipboard = q.isEmpty
        ? <ClipboardItemModel>[]
        : clipboardItems
              .where(
                (c) =>
                    c.label.toLowerCase().contains(q) ||
                    c.value.toLowerCase().contains(q),
              )
              .toList();

    final hasResults = matchedPages.isNotEmpty || matchedClipboard.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchVault,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  prefixIcon: Icon(
                    PhosphorIcons.magnifyingGlass(),
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(PhosphorIcons.x(), size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
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
            // Results
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (q.isEmpty) ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            PhosphorIcons.magnifyingGlass(
                              PhosphorIconsStyle.duotone,
                            ),
                            size: 48,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.searchSavedPagesAndClipboard,
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!hasResults) ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            PhosphorIcons.magnifyingGlass(),
                            size: 40,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.noResultsForQuery(_query),
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Pages results
                  if (matchedPages.isNotEmpty) ...[
                    _searchSectionHeader(
                      AppLocalizations.of(context)!.searchResultPages,
                      PhosphorIcons.browsers(),
                      matchedPages.length,
                      isDark,
                    ),
                    ...matchedPages
                        .take(8)
                        .map((p) => _pageResultTile(context, p, isDark)),
                  ],
                  // Clipboard results
                  if (matchedClipboard.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _searchSectionHeader(
                      AppLocalizations.of(context)!.searchResultClipboard,
                      PhosphorIcons.clipboardText(),
                      matchedClipboard.length,
                      isDark,
                    ),
                    ...matchedClipboard
                        .take(8)
                        .map((c) => _clipboardResultTile(context, c, isDark)),
                  ],
                  // Discover link
                  if (q.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          PhosphorIcons.compass(),
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.browseDiscover,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.searchOnlineContent,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      trailing: Icon(
                        PhosphorIcons.arrowRight(),
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/discover');
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchSectionHeader(
    String title,
    IconData icon,
    int count,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageResultTile(BuildContext context, PageModel page, bool isDark) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          PhosphorIcons.globe(PhosphorIconsStyle.duotone),
          color: AppTheme.primaryColor,
          size: 18,
        ),
      ),
      title: Text(
        page.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        page.url,
        style: TextStyle(
          fontSize: 11,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: page.isFavorite
          ? Icon(
              PhosphorIcons.heart(PhosphorIconsStyle.fill),
              size: 14,
              color: AppTheme.errorColor,
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        context.push('/browser/${page.id}');
      },
    );
  }

  Widget _clipboardResultTile(
    BuildContext context,
    ClipboardItemModel item,
    bool isDark,
  ) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          PhosphorIcons.copySimple(),
          color: const Color(0xFFF59E0B),
          size: 18,
        ),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.value,
        style: TextStyle(
          fontSize: 11,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        PhosphorIcons.copySimple(),
        size: 14,
        color: isDark ? Colors.white38 : Colors.black26,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Clipboard.setData(ClipboardData(text: item.value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied "${item.label}"'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}

class _TopVaultCard extends StatelessWidget {
  final PageModel page;
  final bool isDark;

  const _TopVaultCard({required this.page, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              PhosphorIcons.crown(PhosphorIconsStyle.fill),
              color: AppTheme.accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.mostVisited,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  page.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${page.visitCount} ${AppLocalizations.of(context)!.lifetimeVisits}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.caretRight(),
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _RecentItem extends StatelessWidget {
  final PageModel page;
  final bool isDark;
  final int index;
  final VoidCallback onSuggestion;

  const _RecentItem({
    required this.page,
    required this.isDark,
    required this.index,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/browser/${page.id}'),
      onLongPress: onSuggestion,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    (index % 2 == 0
                            ? AppTheme.primaryColor
                            : AppTheme.accentColor)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                color: index % 2 == 0
                    ? AppTheme.primaryColor
                    : AppTheme.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    page.url,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (page.isFavorite)
              Icon(
                PhosphorIcons.heart(PhosphorIconsStyle.fill),
                size: 16,
                color: AppTheme.errorColor,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (700 + (index * 50)).ms).slideX(begin: 0.05);
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIcons.browsers(PhosphorIconsStyle.duotone),
            color: AppTheme.primaryColor,
            size: 48,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.yourVaultIsEmpty,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.addFirstPage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => context.push('/add-page'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
          label: Text(
            AppLocalizations.of(context)!.addMyFirstPage,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Premium header avatar.
///
/// Visuals:
///  • Outer 2-stop gradient ring (primary → accent) with soft brand-coloured
///    glow that lifts the avatar off the header.
///  • Inner gradient disc carrying the user's first initial in white — much
///    more striking than the old "primary text on white card" treatment.
///  • Optional red dot (with a contrasting border that matches the page
///    background) when there are unread support-chat messages.
class _HeaderAvatar extends ConsumerWidget {
  final bool isDark;
  final bool hasUnreadChats;

  const _HeaderAvatar({
    required this.isDark,
    this.hasUnreadChats = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (profile) {
        final fullName = profile?['full_name'] as String? ?? '';
        final initial = fullName.trim().isNotEmpty
            ? fullName.trim()[0].toUpperCase()
            : '?';
        return _buildShell(child: _buildInitial(initial));
      },
      loading: () => _buildShell(
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      error: (_, _) => _buildShell(
        child: Icon(
          PhosphorIcons.user(PhosphorIconsStyle.bold),
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Solid primary ring + soft glow (no gradient — uses the app's
        // single brand colour as requested).
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.28),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Background-coloured hairline between the ring and the inner
          // disc — gives the avatar a clean two-tone separation similar to
          // premium banking / messaging apps.
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
              child: child,
            ),
          ),
        ),

        if (hasUnreadChats)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitial(String initial) {
    return Text(
      initial,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: 0.5,
        height: 1.0,
      ),
    );
  }
}

class _ProfilePreviewSheet extends ConsumerWidget {
  final bool isDark;

  const _ProfilePreviewSheet({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: userProfileAsync.when(
            data: (profile) {
              final fullName = profile?['full_name'] as String? ?? 'Vault User';
              final email = currentUser?.email ?? 'No email';
              final initials = fullName.isNotEmpty
                  ? fullName[0].toUpperCase()
                  : '?';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.pop();
                        context.push('/profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(PhosphorIcons.user(), size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.profile,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        context.pop();
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          context.go('/');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(
                          color: AppTheme.errorColor.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(PhosphorIcons.signOut(), size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.signOut,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Center(child: Text('Error loading profile')),
          ),
        ),
      ),
    );
  }
}
