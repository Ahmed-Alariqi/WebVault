import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  final bool isChanging;

  const PinLockScreen({
    super.key,
    this.isSetup = false,
    this.isChanging = false,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  String _statusText = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const int pinLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    if (widget.isSetup || widget.isChanging) {
      _statusText = 'Create your PIN';
    } else {
      _statusText = 'Enter your PIN';
      _tryBiometric();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final settings = ref.read(settingsProvider);
    if (settings['biometricEnabled'] != true) return;

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isAvailable || !isDeviceSupported) return;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock WebVault Manager',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate && mounted) {
        ref.read(appLockedProvider.notifier).state = false;
        if (context.mounted) context.go('/dashboard');
      }
    } catch (e) {
      // Biometric failed, user can still enter PIN
    }
  }

  void _onNumberTap(int number) {
    if (_enteredPin.length >= pinLength) return;
    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin += number.toString();
      _hasError = false;
    });

    if (_enteredPin.length == pinLength) {
      Future.delayed(const Duration(milliseconds: 200), _processPin);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  void _processPin() {
    final settingsNotifier = ref.read(settingsProvider.notifier);

    if (widget.isSetup || widget.isChanging) {
      // Setup mode
      if (!_isConfirming) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
          _statusText = 'Confirm your PIN';
        });
      } else {
        if (_enteredPin == _firstPin) {
          // PINs match
          settingsNotifier.setPin(_enteredPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isChanging
                      ? 'PIN changed successfully'
                      : 'PIN set successfully',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            context.pop();
          }
        } else {
          _showError('PINs do not match');
          setState(() {
            _isConfirming = false;
            _firstPin = '';
            _statusText = 'Create your PIN';
          });
        }
      }
    } else {
      // Verify mode
      if (settingsNotifier.verifyPin(_enteredPin)) {
        ref.read(appLockedProvider.notifier).state = false;
        if (mounted) context.go('/dashboard');
      } else {
        _showError('Incorrect PIN');
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    _shakeController.forward();
    setState(() {
      _hasError = true;
      _statusText = message;
      _enteredPin = '';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          if (widget.isSetup || widget.isChanging) {
            _statusText = 'Create your PIN';
          } else {
            _statusText = 'Enter your PIN';
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final biometricEnabled = settings['biometricEnabled'] == true;
    final isUnlockMode = !widget.isSetup && !widget.isChanging;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A1A),
                    const Color(0xFF1A1A3E),
                    const Color(0xFF0F0F2A),
                  ]
                : [
                    const Color(0xFFF0F0FF),
                    const Color(0xFFE8E8FF),
                    const Color(0xFFF5F5FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with back button for setup
              if (widget.isSetup || widget.isChanging)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        PhosphorIcons.caretLeft(),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 2),

              // Lock icon with glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                      AppTheme.accentColor.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.lock(PhosphorIconsStyle.fill),
                  color: Colors.white,
                  size: 36,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),

              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _hasError
                        ? AppTheme.errorColor
                        : (isDark ? Colors.white : AppTheme.lightTextPrimary),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              if (isUnlockMode)
                Text(
                  'WebVault Manager',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1.2,
                  ),
                ),

              const SizedBox(height: 40),

              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final shakeOffset =
                      _shakeAnimation.value *
                      20 *
                      (_shakeAnimation.value > 0.5 ? -1 : 1);
                  return Transform.translate(
                    offset: Offset(shakeOffset, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pinLength, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: isFilled ? 20 : 16,
                      height: isFilled ? 20 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? AppTheme.errorColor
                            : (isFilled
                                  ? AppTheme.primaryColor
                                  : Colors.transparent),
                        border: Border.all(
                          color: _hasError
                              ? AppTheme.errorColor
                              : (isFilled
                                    ? AppTheme.primaryColor
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.black26)),
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color:
                                      (_hasError
                                              ? AppTheme.errorColor
                                              : AppTheme.primaryColor)
                                          .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(flex: 1),

              // Number pad
              _buildNumberPad(isDark),

              const SizedBox(height: 20),

              // Biometric button
              if (isUnlockMode && biometricEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        PhosphorIcons.fingerprint(),
                        color: AppTheme.accentColor,
                        size: 28,
                      ),
                    ),
                    label: const Text(
                      'Use Biometrics',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (row < 3)
                    for (int col = 0; col < 3; col++)
                      _buildKeyButton(
                        row * 3 + col + 1,
                        isDark,
                        label: '${row * 3 + col + 1}',
                      )
                  else ...[
                    // Bottom row: empty, 0, backspace
                    const SizedBox(width: 72, height: 72),
                    _buildKeyButton(0, isDark, label: '0'),
                    _buildBackspaceButton(isDark),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(int number, bool isDark, {required String label}) {
    return GestureDetector(
      onTap: () => _onNumberTap(number),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(bool isDark) {
    return GestureDetector(
      onTap: _onBackspace,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        setState(() => _enteredPin = '');
      },
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(
            PhosphorIcons.backspace(),
            size: 26,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
