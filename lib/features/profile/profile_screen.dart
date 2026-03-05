import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _loading = false;
  bool _saved = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final user = SupabaseConfig.client.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            forceMaterialTransparency: false,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, Color(0xFF7C4DFF)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 3),
                          color: Colors.white24,
                        ),
                        child: profile.when(
                          data: (p) {
                            final avatarUrl = p?['avatar_url'] as String?;
                            if (avatarUrl != null && avatarUrl.isNotEmpty) {
                              return ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 84,
                                  height: 84,
                                ),
                              );
                            }
                            return const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 40,
                            );
                          },
                          loading: () => const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          error: (e, st) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ).animate().scale(
                        begin: const Offset(0.6, 0.6),
                        curve: Curves.elasticOut,
                        duration: 800.ms,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.email ?? 'User',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile Form
          SliverToBoxAdapter(
            child: profile.when(
              data: (p) {
                // Pre-fill controllers once
                if (_nameCtrl.text.isEmpty && p != null) {
                  _nameCtrl.text = p['full_name'] as String? ?? '';
                  _usernameCtrl.text = p['username'] as String? ?? '';
                }
                return _buildForm(isDark, p);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark, Map<String, dynamic>? profile) {
    final role = profile?['role'] as String? ?? 'user';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: role == 'admin'
                      ? Colors.amber.withValues(alpha: 0.15)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role == 'admin'
                          ? PhosphorIcons.crown(PhosphorIconsStyle.fill)
                          : PhosphorIcons.user(PhosphorIconsStyle.fill),
                      size: 16,
                      color: role == 'admin'
                          ? Colors.amber.shade700
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: role == 'admin'
                            ? Colors.amber.shade700
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          // Form card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.personalInfo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),

                _field(
                  _nameCtrl,
                  AppLocalizations.of(context)!.fullName,
                  PhosphorIcons.user(),
                  isDark,
                ),
                const SizedBox(height: 14),
                _field(
                  _usernameCtrl,
                  AppLocalizations.of(context)!.username,
                  PhosphorIcons.at(),
                  isDark,
                ),

                const SizedBox(height: 24),

                // Saved banner
                if (_saved)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.profileSaved,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF7C4DFF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.saveProfile,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

          const SizedBox(height: 20),

          // Contact Support
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final unreadCountAsync = ref.watch(
                      userUnreadCountStreamProvider,
                    );
                    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.chatCircleDots(),
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.contactSupport,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              trailing: Icon(
                PhosphorIcons.caretRight(),
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onTap: () => context.push('/chat'),
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 12),

          // Sign Out
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.signOut(),
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.signOutLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                ),
              ),
              trailing: Icon(
                PhosphorIcons.caretRight(),
                size: 18,
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onTap: _signOut,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark,
  ) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _loading = true;
      _saved = false;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty
            ? null
            : _usernameCtrl.text.trim(),
      );
      ref.invalidate(userProfileProvider);
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    // GoRouter's refreshListenable detects auth state change
    // and automatically redirects to /login
  }
}
