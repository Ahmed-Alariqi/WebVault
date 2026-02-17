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
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        forceMaterialTransparency: true,
      ),
      body: isAdmin.when(
        data: (admin) {
          if (!admin) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
                    size: 56,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need admin privileges',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                stats.when(
                  data: (s) => Row(
                    children: [
                      _statCard(
                        'Websites',
                        s['websites'] ?? 0,
                        PhosphorIcons.globe(),
                        const Color(0xFF3F51B5),
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        'Categories',
                        s['categories'] ?? 0,
                        PhosphorIcons.tag(),
                        const Color(0xFF009688),
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        'Users',
                        s['users'] ?? 0,
                        PhosphorIcons.users(),
                        const Color(0xFFE91E63),
                        isDark,
                      ),
                    ],
                  ).animate().fadeIn(),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Text('Error loading stats'),
                ),

                const SizedBox(height: 32),

                Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                _actionTile(
                  context,
                  'Manage Websites',
                  'Add, edit, or remove websites',
                  PhosphorIcons.globe(PhosphorIconsStyle.fill),
                  const Color(0xFF3F51B5),
                  isDark,
                  () => context.push('/admin/websites'),
                  0,
                ),
                _actionTile(
                  context,
                  'Manage Categories',
                  'Organize content by category',
                  PhosphorIcons.tag(PhosphorIconsStyle.fill),
                  const Color(0xFF009688),
                  isDark,
                  () => context.push('/admin/categories'),
                  1,
                ),
                _actionTile(
                  context,
                  'Send Notification',
                  'Push announcements to all users',
                  PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
                  const Color(0xFFFF9800),
                  isDark,
                  () => context.push('/admin/notifications'),
                  2,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            const Center(child: Text('Error checking admin status')),
      ),
    );
  }

  Widget _statCard(
    String label,
    int count,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(),
                size: 18,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.05);
  }
}
