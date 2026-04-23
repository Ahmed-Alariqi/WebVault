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
                          const Color(0xFF1E293B), // Slate 800
                          AppTheme.primaryColor,   // Indigo
                          const Color(0xFF0F172A), // Slate 900
                        ],
                        stops: const [0.0, 0.4, 1.0],
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
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3, // Slightly taller to accommodate wrapping text safely
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
                      Consumer(
                        builder: (context, ref, _) {
                          final count = ref.watch(adminDraftCountProvider);
                          return _ActionCard(
                            title: 'المسودات',
                            subtitle: 'إدارة مسودات المحتوى',
                            icon: PhosphorIcons.notepad(PhosphorIconsStyle.duotone),
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                            onTap: () => context.push('/admin/drafts'),
                            delay: 25,
                            badge: count > 0 ? _buildBadge(count) : null,
                          );
                        },
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
                    if (perms.contains('events'))
                      _ActionCard(
                        title: AppLocalizations.of(context)!.eventsTitle,
                        subtitle: AppLocalizations.of(context)!.eventsSubtitle,
                        icon: PhosphorIcons.confetti(
                          PhosphorIconsStyle.duotone,
                        ),
                        color: const Color(0xFFE11D48),
                        isDark: isDark,
                        onTap: () => context.push('/admin/events'),
                        delay: 345,
                      ),

                    // AI Management
                    _ActionCard(
                      title: 'إدارة الذكاء الاصطناعي',
                      subtitle: 'الشخصيات والمزودين',
                      icon: PhosphorIcons.brain(
                        PhosphorIconsStyle.duotone,
                      ),
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      onTap: () => context.push('/admin/ai-management'),
                      delay: 350,
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
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: AppLocalizations.of(context)!.totalUsers,
            value: stats['users']?.toString() ?? '0',
            icon: PhosphorIcons.users(PhosphorIconsStyle.bold),
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: AppLocalizations.of(context)!.websitesTitle,
            value: stats['websites']?.toString() ?? '0',
            icon: PhosphorIcons.globe(PhosphorIconsStyle.bold),
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: AppLocalizations.of(context)!.categoriesTitle,
            value: stats['categories']?.toString() ?? '0',
            icon: PhosphorIcons.tag(PhosphorIconsStyle.bold),
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.black45,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark 
                ? color.withValues(alpha: 0.2) 
                : color.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.15 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                icon,
                size: 70,
                color: color.withValues(alpha: 0.04),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.1,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            badge!,
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 400.ms).scale(
      begin: const Offset(0.92, 0.92),
      curve: Curves.easeOutBack,
    );
  }
}

Widget _buildBadge(int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.errorColor,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: AppTheme.errorColor.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      count > 99 ? '99+' : count.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
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
