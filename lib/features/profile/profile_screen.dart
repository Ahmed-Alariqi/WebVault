import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../presentation/providers/username_check_provider.dart';
import '../../presentation/providers/referral_providers.dart';
import '../../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'referral_share_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _loading = false;

  // Username validation state
  Timer? _usernameDebounce;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;

  // Track original values to detect changes
  String _originalName = '';
  String _originalUsername = '';
  bool _initialized = false;

  final _referralCodeCtrl = TextEditingController();
  bool _submittingReferral = false;
  String? _referralErrorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _referralCodeCtrl.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  bool get _hasChanges {
    return _nameCtrl.text.trim() != _originalName ||
        _usernameCtrl.text.trim() != _originalUsername;
  }

  bool get _canSave {
    return _hasChanges &&
        !_loading &&
        _usernameStatus != _UsernameStatus.checking &&
        _usernameStatus != _UsernameStatus.taken;
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    final trimmed = value.trim();

    // If empty or same as original, reset
    if (trimmed.isEmpty || trimmed == _originalUsername) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
      return;
    }

    // Check format first
    if (trimmed.length < 5) {
      setState(() => _usernameStatus = _UsernameStatus.tooShort);
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      setState(() => _usernameStatus = _UsernameStatus.invalid);
      return;
    }

    // Debounce the server check
    setState(() => _usernameStatus = _UsernameStatus.checking);
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final userId = SupabaseConfig.client.auth.currentUser?.id;
        final isAvailable = await ref.read(
          usernameAvailableProvider((
            username: trimmed,
            currentUserId: userId,
          )).future,
        );
        if (mounted && _usernameCtrl.text.trim() == trimmed) {
          setState(() {
            _usernameStatus = isAvailable
                ? _UsernameStatus.available
                : _UsernameStatus.taken;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _usernameStatus = _UsernameStatus.idle);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final user = SupabaseConfig.client.auth.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ───
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
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
                child: SafeArea(
                  child: profile.when(
                    data: (p) => _buildHeroContent(p, user, isDark),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (_, _) => _buildHeroContent(null, user, isDark),
                  ),
                ),
              ),
            ),
          ),

          // ─── Body ───
          SliverToBoxAdapter(
            child: profile.when(
              data: (p) {
                _initControllers(p);
                return _buildBody(isDark, p, l10n);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Header Content ───
  Widget _buildHeroContent(Map<String, dynamic>? p, dynamic user, bool isDark) {
    final fullName = p?['full_name'] as String? ?? '';
    final username = p?['username'] as String? ?? '';
    final role = p?['role'] as String? ?? 'user';
    final email = user?.email ?? '';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative background elements
        Positioned(
          top: -30,
          left: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(),
        ),
        Positioned(
          bottom: -50,
          right: -20,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ).animate().fadeIn(duration: 1000.ms).scale(),
        ),

        // Main content
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            // Header Title
            const Text(
              "Account Profile",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),

            // Full name
            if (fullName.isNotEmpty)
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 6),

            // @username + role badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (username.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (username.isNotEmpty) const SizedBox(width: 8),
                _buildRoleBadge(role),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

            const SizedBox(height: 8),

            // Email
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.amber.withValues(alpha: 0.25) : Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin
                ? PhosphorIcons.crown(PhosphorIconsStyle.fill)
                : PhosphorIcons.user(PhosphorIconsStyle.fill),
            size: 12,
            color: isAdmin ? Colors.amber.shade200 : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isAdmin ? Colors.amber.shade200 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Initialize controllers once ───
  void _initControllers(Map<String, dynamic>? p) {
    if (_initialized || p == null) return;
    _nameCtrl.text = p['full_name'] as String? ?? '';
    _usernameCtrl.text = p['username'] as String? ?? '';
    _originalName = _nameCtrl.text.trim();
    _originalUsername = _usernameCtrl.text.trim();
    _initialized = true;
  }

  // ─── Body ───
  Widget _buildBody(
    bool isDark,
    Map<String, dynamic>? profile,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Personal Info Section ───
          _buildPersonalInfoSection(isDark, l10n),

          const SizedBox(height: 16),

          // ─── Contact & Support Section ───
          _buildContactSupportTile(isDark, l10n),

          const SizedBox(height: 12),

          // ─── Referral Input Section (24 hours window) ───
          _buildReferralInputCard(isDark, profile, l10n),

          const SizedBox(height: 12),

          // ─── Referral Share Section ───
          _buildReferralCard(isDark, l10n),

          const SizedBox(height: 12),

          // ─── Account Section ───
          _buildAccountSection(isDark, l10n),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Personal Information Card ───
  Widget _buildPersonalInfoSection(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              l10n.personalInfo,
              PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
              isDark,
            ),
            const SizedBox(height: 24),

            // Full Name field
            _buildValidatedField(
              controller: _nameCtrl,
              label: l10n.fullName,
              icon: PhosphorIcons.user(),
              isDark: isDark,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.fullNameRequired;
                if (v.trim().length < 2) return l10n.fullNameRequired;
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Username field
            _buildValidatedField(
              controller: _usernameCtrl,
              label: l10n.username,
              icon: PhosphorIcons.at(),
              isDark: isDark,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.usernameRequired;
                if (v.trim().length < 5) return l10n.usernameTooShort;
                if (v.trim().length > 10) return l10n.usernameTooLong;
                if (RegExp(r'^\d+$').hasMatch(v.trim())) {
                  return l10n.usernameNumbersOnly;
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                  return l10n.usernameInvalid;
                }
                if (_usernameStatus == _UsernameStatus.taken) {
                  return l10n.usernameTaken;
                }
                return null;
              },
              onChanged: (v) {
                setState(() {});
                _onUsernameChanged(v);
              },
            ),

            // Username status indicator
            if (_usernameStatus != _UsernameStatus.idle &&
                _usernameCtrl.text.trim() != _originalUsername)
              _buildUsernameStatusWidget(l10n),

            const SizedBox(height: 32),

            // Save button
            _buildSaveButton(isDark, l10n),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildUsernameStatusWidget(AppLocalizations l10n) {
    IconData icon;
    Color color;
    String text;

    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.checkingUsername,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      case _UsernameStatus.available:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        text = l10n.usernameAvailable;
        break;
      case _UsernameStatus.taken:
        icon = Icons.cancel_outlined;
        color = AppTheme.errorColor;
        text = l10n.usernameTaken;
        break;
      case _UsernameStatus.tooShort:
        icon = Icons.info_outline;
        color = Colors.orange;
        text = l10n.usernameTooShort;
        break;
      case _UsernameStatus.invalid:
        icon = Icons.info_outline;
        color = Colors.orange;
        text = l10n.usernameInvalid;
        break;
      case _UsernameStatus.idle:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSaveButton(bool isDark, AppLocalizations l10n) {
    return AnimatedOpacity(
      opacity: _canSave ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF7C4DFF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _canSave
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: _canSave ? _saveProfile : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
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
                  l10n.saveProfile,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Referral Share Card ───
  Widget _buildReferralCard(bool isDark, AppLocalizations l10n) {
    final campaignAsync = ref.watch(activeReferralCampaignProvider);
    return campaignAsync.when(
      data: (campaign) {
        if (campaign == null || !campaign.isVisible) {
          return GestureDetector(
            onTap: () {
              final text = l10n.localeName.startsWith('ar')
                  ? 'أهلاً! 👋\n\nاكتشفت تطبيق WebVault وصراحةً غيّر طريقتي بحفظ الروابط والملاحظات — كل شي منظّم ومرتّب بمكان واحد 🔖✨\n\nإذا حسيت إنه بيفيدك، جربه وشارك الفائدة 🚀\n\nحمّل التطبيق من هنا:\nhttps://webvault.app/download'
                  : 'Hello! 👋\n\nI discovered the WebVault app and it really changed how I save links and notes — everything is organized in one place 🔖✨\n\nIf you think it might be useful, try it out 🚀\n\nDownload the app here:\nhttps://webvault.app/download';
              Share.share(text);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.accentColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.localeName.startsWith('ar')
                              ? 'شارك الفائدة 💡'
                              : 'Share the app 💡',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.localeName.startsWith('ar')
                              ? 'هل تعرف أحداً قد يستفيد من التطبيق؟ ساعده يكتشف WebVault ✨'
                              : 'Know someone who could use the app? Help them discover WebVault ✨',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
        }
        final hasUsername = _originalUsername.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (!hasUsername) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'يرجى حفظ اسم المستخدم الخاص بك أولاً لتمكين إنشاء و مشاركة كود الإحالة.',
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReferralShareScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasUsername
                    ? [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        AppTheme.accentColor.withValues(alpha: 0.08),
                      ]
                    : [
                        Colors.grey.withValues(alpha: 0.15),
                        Colors.grey.withValues(alpha: 0.08),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasUsername
                    ? AppTheme.primaryColor.withValues(alpha: 0.25)
                    : Colors.grey.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.referralShareTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.referralShareSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  // ─── Contact Support Tile ───
  Widget _buildContactSupportTile(bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final unreadCountAsync = ref.watch(userUnreadCountStreamProvider);
              final unreadCount = unreadCountAsync.valueOrNull ?? 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    PhosphorIcons.chatTeardropDots(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        title: Text(
          l10n.contactSupport,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          l10n.messageAdmin,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIcons.caretRight(),
            size: 16,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onTap: () => context.push('/chat'),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  // ─── Account Section ───
  Widget _buildAccountSection(bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              top: 24,
              right: 24,
              bottom: 8,
            ),
            child: _buildSectionHeader(
              l10n.accountActions,
              PhosphorIcons.gear(PhosphorIconsStyle.fill),
              isDark,
            ),
          ),

          // Change Password
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.blue,
                size: 22,
              ),
            ),
            title: Text(
              l10n.changePassword,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            trailing: Icon(
              PhosphorIcons.caretRight(),
              size: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onTap: _changePassword,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              height: 16,
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),

          // Sign Out
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.signOut(PhosphorIconsStyle.fill),
                color: AppTheme.errorColor,
                size: 22,
              ),
            ),
            title: Text(
              l10n.signOutLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
            trailing: Icon(
              PhosphorIcons.caretRight(),
              size: 16,
              color: AppTheme.errorColor.withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onTap: _confirmSignOut,
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  // ─── Helpers ───
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : AppTheme.primaryColor.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  // ─── Actions ───
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final newUsername = _usernameCtrl.text.trim();
    final usernameChanged =
        newUsername != _originalUsername && newUsername.isNotEmpty;

    // ─── Username cooldown check ───
    if (usernameChanged) {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final changedAtRaw = profile?['username_changed_at'];
      if (changedAtRaw != null) {
        final changedAt = DateTime.parse(changedAtRaw as String);
        final nextAllowed = changedAt.add(const Duration(days: 30));
        if (DateTime.now().toUtc().isBefore(nextAllowed)) {
          final dateStr =
              '${nextAllowed.year}-${nextAllowed.month.toString().padLeft(2, '0')}-${nextAllowed.day.toString().padLeft(2, '0')}';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.usernameCooldownError),
                    const SizedBox(height: 4),
                    Text(
                      l10n.usernameNextChangeDate(dateStr),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return;
        }
      }
    }

    setState(() => _loading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(
        fullName: _nameCtrl.text.trim(),
        username: newUsername.isEmpty ? null : newUsername,
        updateUsernameTimestamp: usernameChanged,
      );
      ref.invalidate(userProfileProvider);

      // Update original values
      _originalName = _nameCtrl.text.trim();
      _originalUsername = _usernameCtrl.text.trim();
      _usernameStatus = _UsernameStatus.idle;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(l10n.profileUpdated),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user?.email == null) return;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Step 1: Send OTP
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(user!.email!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.forgotPasswordFailed),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Step 2: Show OTP + New Password bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChangePasswordSheet(
        email: user.email!,
        isDark: isDark,
        l10n: l10n,
        ref: ref,
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.signOutLabel,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          l10n.signOutConfirm,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.signOutLabel,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    }
  }

  // ─── Referral Input Card (24h window) ───
  Widget _buildReferralInputCard(
    bool isDark,
    Map<String, dynamic>? profile,
    AppLocalizations l10n,
  ) {
    if (profile == null) return const SizedBox();
    final referredBy = profile['referred_by'] as String?;
    if (referredBy != null) return const SizedBox();

    final authUser = SupabaseConfig.client.auth.currentUser;
    if (authUser == null || authUser.createdAt.isEmpty) return const SizedBox();

    if (DateTime.now().difference(DateTime.parse(authUser.createdAt)).inHours >=
        24) {
      return const SizedBox();
    }

    final campaignAsync = ref.watch(activeReferralCampaignProvider);
    return campaignAsync.when(
      data: (campaign) {
        if (campaign == null || !campaign.isVisible) return const SizedBox();

        String rewardText = '';
        switch (campaign.referredRewardType) {
          case 'giveaway_entry':
            rewardText =
                'تذكرة دخول مجانية في سحب ${campaign.referredRewardDescription ?? "الجوائز"} 🎟️';
            break;
          case 'giveaway_boost':
            rewardText = 'تعزيز فرصتك في السحب بـ 3 مشاركات إضافية ⚡';
            break;
          case 'collection_access':
            rewardText = 'صلاحية فتح المجموعات المميزة 🔓';
            break;
          case 'custom':
          default:
            rewardText = campaign.referredRewardDescription?.isNotEmpty == true
                ? campaign.referredRewardDescription!
                : 'مزايا حصرية 🎁';
        }
        final String dynamicDesc = 'أدخل الكود الآن واحصل على:\n$rewardText';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.gift(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هل تمتلك رمز دعوة؟',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dynamicDesc,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _referralCodeCtrl,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.referralEnterCodeHint,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submittingReferral
                        ? null
                        : () async {
                            final code = _referralCodeCtrl.text.trim();
                            if (code.isEmpty) return;
                            setState(() {
                              _submittingReferral = true;
                              _referralErrorMsg = null;
                            });
                            try {
                              final result = await submitReferralCode(
                                code,
                                ref,
                              );
                              if (result == null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.referralCodeSuccess),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              } else {
                                if (mounted) {
                                  setState(() => _referralErrorMsg = result);
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(
                                  () => _referralErrorMsg = 'حدث خطأ غير متوقع',
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _submittingReferral = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: _submittingReferral
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.referralSubmitCode,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
              if (_referralErrorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _referralErrorMsg == 'invalid'
                        ? 'رمز دعوة غير صحيح'
                        : _referralErrorMsg == 'self'
                        ? 'لا يمكنك استخدام رمزك الخاص'
                        : 'حدث خطأ. حاول مجددا',
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05);
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }
}

/// Username validation states
enum _UsernameStatus { idle, checking, available, taken, tooShort, invalid }

/// Bottom sheet for OTP-verified password change
class _ChangePasswordSheet extends StatefulWidget {
  final String email;
  final bool isDark;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _ChangePasswordSheet({
    required this.email,
    required this.isDark,
    required this.l10n,
    required this.ref,
  });

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _otpVerified = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 8) {
      setState(() => _error = widget.l10n.otpInvalidCode);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = widget.ref.read(authServiceProvider);
      await authService.verifyRecoveryOtp(widget.email, _otpCtrl.text.trim());
      setState(() => _otpVerified = true);
    } catch (_) {
      setState(() => _error = widget.l10n.otpInvalidCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = widget.l10n.passwordTooShort);
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = widget.l10n.passwordMismatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = widget.ref.read(authServiceProvider);
      await authService.updatePassword(_passwordCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Flexible(child: Text(widget.l10n.passwordUpdatedSuccess)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      setState(() => _error = widget.l10n.passwordUpdateFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final l10n = widget.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _otpVerified ? l10n.newPassword : l10n.enterOtp,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _otpVerified ? '' : l10n.forgotPasswordCheckEmail,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 24),

            // Error
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 13,
                  ),
                ),
              ),

            if (!_otpVerified) ...[
              // OTP input
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 8,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSheetButton(
                label: l10n.otpVerifyButton,
                onPressed: _loading ? null : _verifyOtp,
              ),
            ] else ...[
              // New Password
              _sheetPasswordField(
                controller: _passwordCtrl,
                label: l10n.newPassword,
                obscure: _obscure1,
                toggle: () => setState(() => _obscure1 = !_obscure1),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _sheetPasswordField(
                controller: _confirmCtrl,
                label: l10n.confirmNewPassword,
                obscure: _obscure2,
                toggle: () => setState(() => _obscure2 = !_obscure2),
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildSheetButton(
                label: l10n.updatePasswordButton,
                onPressed: _loading ? null : _updatePassword,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sheetPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          PhosphorIcons.lock(),
          size: 20,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
            size: 20,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSheetButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF7C4DFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
