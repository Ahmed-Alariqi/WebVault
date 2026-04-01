import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../l10n/app_localizations.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAccess = ref.watch(hasAdminAccessProvider);
    final userPerms = ref.watch(userPermissionsProvider);
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: hasAccess.when(
        data: (access) {
          if (!access) return const _AccessDeniedView();

          final perms = userPerms.valueOrNull ?? [];

          return CustomScrollView(
            slivers: [
              // 1. Pro Header with Gradient
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6366F1), // Indigo
                          const Color(0xFF8B5CF6), // Violet
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                            size: 150,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            MediaQuery.of(context).padding.top + 60,
                            20,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.adminBadge,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.controlCenter,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.manageVaultEcosystem,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                ),
              ),

              // 2. Stats Grid
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: statsAsync.when(
                    data: (stats) => _StatsGrid(stats: stats, isDark: isDark),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => OfflineWarningWidget(error: e),
                  ),
                ),
              ),

              // 3. Management Title
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    AppLocalizations.of(context)!.management,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ),

              // 4. Action Grid — filtered by permissions
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    if (perms.contains('analytics'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.appActivities,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.analyticsTracking,
                        icon: PhosphorIcons.chartLineUp(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                        onTap: () => context.push('/admin/analytics'),
                        delay: 0,
                      ),
                    if (perms.contains('suggestions'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.suggestionsTitle,
                        subtitle: AppLocalizations.of(context)!.reviewRequests,
                        icon: PhosphorIcons.lightbulb(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () => context.push('/admin/suggestions'),
                        delay: 0,
                      ),
                    if (perms.contains('websites'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.websitesTitle,
                        subtitle: AppLocalizations.of(context)!.addEditSites,
                        icon: PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                        onTap: () => context.push('/admin/websites'),
                        delay: 50,
                      ),
                    if (perms.contains('categories'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.categoriesTitle,
                        subtitle: AppLocalizations.of(context)!.organizeContent,
                        icon: PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () => context.push('/admin/categories'),
                        delay: 100,
                      ),
                    if (perms.contains('notifications'))
                      _ActionCard(
                        title: AppLocalizations.of(
                          context,
                        )!.pushNotificationsTitle,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.sendOutsideAlerts,
                        icon: PhosphorIcons.bellRinging(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () => context.push('/admin/notifications'),
                        delay: 200,
                      ),
                    if (perms.contains('in_app_messages'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.inAppMessagesTitle,
                        subtitle: AppLocalizations.of(context)!.popupCampaigns,
                        icon: PhosphorIcons.megaphone(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFF14B8A6),
                        isDark: isDark,
                        onTap: () => context.push('/admin/in-app-messages'),
                        delay: 250,
                      ),
                    if (perms.contains('users'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.usersTitle,
                        subtitle: AppLocalizations.of(context)!.viewAccounts,
                        icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
                        color: const Color(0xFFEC4899),
                        isDark: isDark,
                        onTap: () => context.push('/admin/users'),
                        delay: 300,
                      ),
                    if (perms.contains('community'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.communityTitle,
                        subtitle: AppLocalizations.of(context)!.managePosts,
                        icon: PhosphorIcons.usersThree(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFFEAB308),
                        isDark: isDark,
                        onTap: () => context.push('/admin/community'),
                        delay: 325,
                      ),
                    if (perms.contains('advertisements'))
                      _ActionCard(
                        title: AppLocalizations.of(
                          context,
                        )!.adminAdvertisementsTitle,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.adminAdvertisementsSubtitle,
                        icon: PhosphorIcons.presentationChart(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () => context.push('/admin/advertisements'),
                        delay: 335,
                      ),
                    if (perms.contains('websites'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.manageCollections,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.manageCollectionsDesc,
                        icon: PhosphorIcons.folderStar(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFF0EA5E9),
                        isDark: isDark,
                        onTap: () => context.push('/admin/collections'),
                        delay: 340,
                      ),

                    Consumer(
                      builder: (context, ref, _) {
                        // User messages is a special card — show if user has 'users' permission
                        // (covers support chat access)
                        if (!perms.contains('users') &&
                            !perms.contains('community')) {
                          return const SizedBox.shrink();
                        }
                        final count = ref.watch(adminTotalUnreadCountProvider);

                        return _ActionCard(
                          title: AppLocalizations.of(
                            context,
                          )!.userMessagesTitle,
                          subtitle: AppLocalizations.of(context)!.supportChats,
                          icon: PhosphorIcons.chatCircleDots(
                            PhosphorIconsStyle.duotone,
                          ),
                          color: const Color(0xFFF43F5E),
                          isDark: isDark,
                          onTap: () => context.push('/admin/user-chats'),
                          delay: 350,
                          badge: count > 0 ? _buildBadge(count) : null,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const _AccessDeniedView(),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  final bool isDark;

  const _StatsGrid({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            label: AppLocalizations.of(context)!.totalUsers,
            value: stats['users']?.toString() ?? '0',
            icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          _StatItem(
            label: AppLocalizations.of(context)!.websitesTitle,
            value: stats['websites']?.toString() ?? '0',
            icon: PhosphorIcons.globe(PhosphorIconsStyle.fill),
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          _StatItem(
            label: AppLocalizations.of(context)!.categoriesTitle,
            value: stats['categories']?.toString() ?? '0',
            icon: PhosphorIcons.tag(PhosphorIconsStyle.fill),
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  }); // Fixed typo in copy/paste construction? No, wait.

  // Actually, I should just use the previous _StatItem class.
  // I will check the constructor in the previous view.
  // It was: const _StatItem({required this.label, ..., required this.isDark});
  // I will just copy it.

  // Wait, I am writing the WHOLE file.
  // I need to be careful with `_StatItem` and `_ActionCard` and `_AccessDeniedView`.
  // They are at the bottom of the file in step 1026.

  // Let me just copy them from step 1026 output.

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final int delay;
  final Widget? badge;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
    required this.delay,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if (badge != null) const SizedBox(width: 8),
              ?badge,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: card,
    ).animate(delay: delay.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

Widget _buildBadge(int count) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.red,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      count > 99 ? '99+' : count.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.shieldWarning(PhosphorIconsStyle.duotone),
            size: 80,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.accessRestricted,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.adminPrivilegesRequired,
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context)!.returnHome),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }
}
