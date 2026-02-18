import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/auth_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = ref.watch(isAdminProvider);
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: isAdmin.when(
        data: (admin) {
          if (!admin) return const _AccessDeniedView();

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
                                child: const Text(
                                  'ADMINISTRATOR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Control Center',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Manage your vault ecosystem',
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
                  onPressed: () => context.pop(),
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
                    error: (e, s) => Text('Error: $e'),
                  ),
                ),
              ),

              // 3. Management Title
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'MANAGEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ),

              // 4. Action Grid
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _ActionCard(
                      title: 'Suggestions',
                      subtitle: 'Review Requests',
                      icon: PhosphorIcons.lightbulb(PhosphorIconsStyle.duotone),
                      color: const Color(0xFF8B5CF6), // Violet
                      isDark: isDark,
                      onTap: () => context.push('/admin/suggestions'),
                      delay: 0,
                    ),
                    _ActionCard(
                      title: 'Websites',
                      subtitle: 'Add/Edit Sites',
                      icon: PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                      color: const Color(0xFF3B82F6), // Blue
                      isDark: isDark,
                      onTap: () => context.push('/admin/websites'),
                      delay: 50,
                    ),
                    _ActionCard(
                      title: 'Categories',
                      subtitle: 'Organize Content',
                      icon: PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                      color: const Color(0xFF10B981), // Emerald
                      isDark: isDark,
                      onTap: () => context.push('/admin/categories'),
                      delay: 100,
                    ),
                    _ActionCard(
                      title: 'Notifications',
                      subtitle: 'Push Alerts',
                      icon: PhosphorIcons.bellRinging(
                        PhosphorIconsStyle.duotone,
                      ),
                      color: const Color(0xFFF59E0B), // Amber
                      isDark: isDark,
                      onTap: () => context.push('/admin/notifications'),
                      delay: 200,
                    ),
                    _ActionCard(
                      title: 'Users',
                      subtitle: 'View Accounts',
                      icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
                      color: const Color(0xFFEC4899), // Pink
                      isDark: isDark,
                      onTap: () => context.push('/admin/users'),
                      delay: 300,
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
            label: 'Total Users',
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
            label: 'Websites',
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
            label: 'Categories',
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

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
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
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
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
      ),
    ).animate(delay: delay.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
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
            'Access Resticted',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Administrator privileges required.',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Return Home'),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }
}
