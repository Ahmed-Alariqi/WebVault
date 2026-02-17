import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../presentation/widgets/notification_badge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/page_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ref.watch(dashboardStatsProvider);
    final totalPages = stats['totalPages'] as int;
    final favCount = stats['favoritesCount'] as int;
    final mostVisited = stats['mostVisited'] as PageModel?;
    final recentPages = stats['recentPages'] as List<PageModel>;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // Dynamic modern App Bar/Header
          SliverToBoxAdapter(child: _DashboardHeader(isDark: isDark)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Actions Grid
                const _QuickActions(),
                const SizedBox(height: 32),

                // Stats Section Header
                _SectionHeader(
                  title: AppLocalizations.of(context)!.vaultOverview,
                  icon: PhosphorIcons.chartBar(),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Premium Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
                        label: AppLocalizations.of(context)!.favorites,
                        value: '$favCount',
                        color: AppTheme.errorColor,
                        isDark: isDark,
                        index: 1,
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

class _DashboardHeader extends StatelessWidget {
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
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
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(
                PhosphorIcons.user(PhosphorIconsStyle.fill),
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.userProfile,
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
              AppLocalizations.of(context)!.welcomeBack,
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
                  context.pop(); // Close modal
                  context.push('/settings'); // Go to settings
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
                icon: Icon(PhosphorIcons.gear(), size: 20),
                label: Text(
                  AppLocalizations.of(context)!.manageSettings,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: NotificationBadge(
              child: Icon(
                PhosphorIcons.bell(),
                size: 24,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showProfilePreview(context, isDark),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                child: Icon(
                  PhosphorIcons.user(PhosphorIconsStyle.bold),
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
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
          icon: PhosphorIcons.shieldCheck(),
          label: AppLocalizations.of(context)!.security,
          color: const Color(0xFFEC4899),
          onTap: () => context.push('/settings'),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final int index;

  const _StatCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (400 + (index * 100)).ms).slideY(begin: 0.1);
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

  const _RecentItem({
    required this.page,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
