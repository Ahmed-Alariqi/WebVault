import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../presentation/providers/providers.dart';
import 'pin_lock_screen.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (_canCheckBiometrics) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
    } catch (e) {
      _canCheckBiometrics = false;
    }
    if (mounted) setState(() {});
  }

  String _getBiometricName() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometrics';
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return PhosphorIcons.smiley();
    }
    return PhosphorIcons.fingerprint();
  }

  String _formatTimeout(int seconds) {
    if (seconds == 0) return 'Immediately';
    if (seconds < 60) return '$seconds seconds';
    return '${seconds ~/ 60} minutes';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final pinEnabled = settings['pinEnabled'] == true;
    final biometricEnabled = settings['biometricEnabled'] == true;
    final screenshotPrevention = settings['screenshotPrevention'] == true;
    final autoLockTimeout = settings['autoLockTimeout'] as int? ?? 0;
    final secureModeEnabled = settings['secureModeEnabled'] == true;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium AppBar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.caretLeft(),
                  size: 18,
                  color: isDark ? Colors.white : Colors.white,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Security & Privacy',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryDark,
                      const Color(0xFF1A237E),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    // Shield icon
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child:
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                PhosphorIcons.shield(PhosphorIconsStyle.fill),
                                color: Colors.white,
                                size: 32,
                              ),
                            ).animate().scale(
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Security Status Card
                _buildSecurityStatusCard(isDark, pinEnabled, biometricEnabled),
                const SizedBox(height: 28),

                // PIN Section
                _buildSectionHeader(
                  'PIN Protection',
                  PhosphorIcons.numpad(),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: PhosphorIcons.lockKey(),
                      iconColor: AppTheme.primaryColor,
                      title: 'PIN Lock',
                      subtitle: pinEnabled ? 'Enabled' : 'Off',
                      value: pinEnabled,
                      onChanged: (value) {
                        if (value) {
                          context.push('/pin-setup');
                        } else {
                          _showRemovePinDialog(settingsNotifier);
                        }
                      },
                    ),
                    if (pinEnabled) ...[
                      _buildDivider(isDark),
                      _buildActionTile(
                        icon: PhosphorIcons.pencilSimple(),
                        iconColor: AppTheme.accentColor,
                        title: 'Change PIN',
                        subtitle: 'Update your security PIN',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProviderScope(
                                child: _PinVerifyThenChange(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // Biometric Section
                _buildSectionHeader(
                  'Biometric Authentication',
                  _getBiometricIcon(),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: _getBiometricIcon(),
                      iconColor: AppTheme.accentColor,
                      title: _getBiometricName(),
                      subtitle: _canCheckBiometrics
                          ? (biometricEnabled
                                ? 'Enabled — Quick unlock'
                                : 'Tap to enable')
                          : 'Not available on this device',
                      value: biometricEnabled,
                      onChanged: _canCheckBiometrics && pinEnabled
                          ? (value) async {
                              if (value) {
                                try {
                                  final authenticated = await _localAuth
                                      .authenticate(
                                        localizedReason:
                                            'Verify to enable biometric unlock',
                                        options: const AuthenticationOptions(
                                          biometricOnly: true,
                                        ),
                                      );
                                  if (authenticated) {
                                    settingsNotifier.setBiometric(true);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Biometric setup failed: $e',
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                settingsNotifier.setBiometric(false);
                              }
                            }
                          : null,
                    ),
                    if (!pinEnabled) ...[
                      _buildDivider(isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.info(),
                              size: 16,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Set up a PIN first to enable biometric authentication',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // Advanced Protection
                _buildSectionHeader(
                  'Advanced Protection',
                  PhosphorIcons.shieldCheck(),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: PhosphorIcons.screencast(),
                      iconColor: const Color(0xFFE91E63),
                      title: 'Screenshot Prevention',
                      subtitle: screenshotPrevention
                          ? 'Screenshots are blocked'
                          : 'Screenshots allowed',
                      value: screenshotPrevention,
                      onChanged: (value) {
                        settingsNotifier.setScreenshotPrevention(value);
                      },
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      icon: PhosphorIcons.lockKey(PhosphorIconsStyle.fill),
                      iconColor: const Color(0xFFFF6F00),
                      title: 'Secure Mode',
                      subtitle: secureModeEnabled
                          ? 'Clipboard data encrypted'
                          : 'Standard storage',
                      value: secureModeEnabled,
                      onChanged: (value) {
                        settingsNotifier.setSecureMode(value);
                      },
                    ),
                    _buildDivider(isDark),
                    _buildDropdownTile(
                      icon: PhosphorIcons.timer(),
                      iconColor: const Color(0xFF7C4DFF),
                      title: 'Auto-Lock Timeout',
                      subtitle: _formatTimeout(autoLockTimeout),
                      isDark: isDark,
                      value: autoLockTimeout,
                      items: kAutoLockOptions,
                      onChanged: pinEnabled
                          ? (value) {
                              if (value != null) {
                                settingsNotifier.setAutoLockTimeout(value);
                              }
                            }
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Security tip
                _buildSecurityTip(isDark),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusCard(
    bool isDark,
    bool pinEnabled,
    bool biometricEnabled,
  ) {
    final int securityLevel;
    final String securityText;
    final Color statusColor;

    if (pinEnabled && biometricEnabled) {
      securityLevel = 3;
      securityText = 'Maximum Protection';
      statusColor = AppTheme.successColor;
    } else if (pinEnabled) {
      securityLevel = 2;
      securityText = 'Good Protection';
      statusColor = AppTheme.warningColor;
    } else {
      securityLevel = 1;
      securityText = 'Basic Protection';
      statusColor = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.05),
                ]
              : [
                  statusColor.withValues(alpha: 0.08),
                  statusColor.withValues(alpha: 0.02),
                ],
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              pinEnabled
                  ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill)
                  : PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  securityText,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(3, (index) {
                    return Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index < securityLevel
                            ? statusColor
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDivider.withValues(alpha: 0.5)
              : AppTheme.lightDivider.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    void Function(bool)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
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
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required int value,
    required List<int> items,
    void Function(int?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<int>(
              value: value,
              underline: const SizedBox(),
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              items: items.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(
                    _formatTimeout(s),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }

  void _showRemovePinDialog(SettingsNotifier settingsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.warning(PhosphorIconsStyle.fill),
              color: AppTheme.warningColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Remove PIN?'),
          ],
        ),
        content: const Text(
          'This will disable PIN lock and biometric authentication. Your app will no longer be protected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              settingsNotifier.removePin();
              settingsNotifier.setBiometric(false);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? AppTheme.accentColor.withValues(alpha: 0.08)
            : AppTheme.accentColor.withValues(alpha: 0.05),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Tip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable both PIN and biometrics for maximum protection of your saved pages and clipboard data.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PIN verify then change flow
// ============================================================

class _PinVerifyThenChange extends ConsumerStatefulWidget {
  const _PinVerifyThenChange();

  @override
  ConsumerState<_PinVerifyThenChange> createState() =>
      _PinVerifyThenChangeState();
}

class _PinVerifyThenChangeState extends ConsumerState<_PinVerifyThenChange> {
  bool _verified = false;

  @override
  Widget build(BuildContext context) {
    if (!_verified) {
      return _PinVerifyScreen(
        onVerified: () {
          setState(() => _verified = true);
        },
      );
    }
    return const PinLockScreen(isSetup: false, isChanging: true);
  }
}

class _PinVerifyScreen extends ConsumerStatefulWidget {
  final VoidCallback onVerified;

  const _PinVerifyScreen({required this.onVerified});

  @override
  ConsumerState<_PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<_PinVerifyScreen> {
  String _pin = '';
  bool _hasError = false;

  void _onTap(int n) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += n.toString();
      _hasError = false;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), () {
        final settingsNotifier = ref.read(settingsProvider.notifier);
        if (settingsNotifier.verifyPin(_pin)) {
          widget.onVerified();
        } else {
          setState(() {
            _hasError = true;
            _pin = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Current PIN'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _hasError ? 'Incorrect PIN' : 'Enter current PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _hasError ? AppTheme.errorColor : null,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: filled ? 18 : 14,
                  height: filled ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? AppTheme.errorColor
                        : (filled ? AppTheme.primaryColor : Colors.transparent),
                    border: Border.all(
                      color: _hasError
                          ? AppTheme.errorColor
                          : (filled
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.white24 : Colors.black26)),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            _buildMiniPad(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPad(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          for (int r = 0; r < 4; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: r < 3
                    ? List.generate(3, (c) => _key(r * 3 + c + 1, isDark))
                    : [
                        const SizedBox(width: 64, height: 64),
                        _key(0, isDark),
                        GestureDetector(
                          onTap: () {
                            if (_pin.isNotEmpty) {
                              setState(
                                () => _pin = _pin.substring(0, _pin.length - 1),
                              );
                            }
                          },
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Icon(
                              Icons.backspace_outlined,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(int n, bool isDark) {
    return GestureDetector(
      onTap: () => _onTap(n),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        child: Center(
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
