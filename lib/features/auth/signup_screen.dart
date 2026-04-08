import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/username_check_provider.dart';
import '../../l10n/app_localizations.dart';

enum _UsernameStatus { idle, checking, available, taken, tooShort, invalid }

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  bool _success = false;

  // Username validation
  Timer? _usernameDebounce;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
      return;
    }
    if (trimmed.length < 3) {
      setState(() => _usernameStatus = _UsernameStatus.tooShort);
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      setState(() => _usernameStatus = _UsernameStatus.invalid);
      return;
    }

    setState(() => _usernameStatus = _UsernameStatus.checking);
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final isAvailable = await ref.read(
          usernameAvailableProvider((
            username: trimmed,
            currentUserId: null,
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
        if (mounted) setState(() => _usernameStatus = _UsernameStatus.idle);
      }
    });
  }

  Widget _buildUsernameStatus(AppLocalizations l10n, bool isDark) {
    if (_usernameStatus == _UsernameStatus.idle) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String text;

    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
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
      padding: const EdgeInsets.only(top: 6, left: 4),
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

  double _passwordStrength() {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.2;
    if (p.length >= 8) s += 0.1;
    if (p.length >= 12) s += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[a-z]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s += 0.15;
    return s.clamp(0.0, 1.0);
  }

  Color _strengthColor() {
    final s = _passwordStrength();
    if (s < 0.3) return AppTheme.errorColor;
    if (s < 0.6) return Colors.orange;
    if (s < 0.8) return Colors.amber;
    return Colors.green;
  }

  String _strengthLabel(BuildContext context) {
    final s = _passwordStrength();
    if (s == 0) return '';
    if (s < 0.3) return AppLocalizations.of(context)!.passwordStrengthWeak;
    if (s < 0.6) return AppLocalizations.of(context)!.passwordStrengthFair;
    if (s < 0.8) return AppLocalizations.of(context)!.passwordStrengthGood;
    return AppLocalizations.of(context)!.passwordStrengthStrong;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Block if username is taken
    if (_usernameStatus == _UsernameStatus.taken) {
      setState(() => _error = AppLocalizations.of(context)!.usernameTaken);
      return;
    }

    // Wait for the check to complete if it's currently checking
    if (_usernameStatus == _UsernameStatus.checking) {
      setState(() => _loading = true);
      while (_usernameStatus == _UsernameStatus.checking) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      if (_usernameStatus == _UsernameStatus.taken) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context)!.usernameTaken;
        });
        return;
      }
    }

    if (_usernameStatus == _UsernameStatus.idle ||
        _usernameStatus == _UsernameStatus.invalid ||
        _usernameStatus == _UsernameStatus.tooShort) {
      // the validator would have caught it, but just in case
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
      );
      if (mounted) setState(() => _success = true);
    } catch (e) {
      setState(() {
        _error = _parseSignUpError(e.toString(), context);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      // GoRouter will pick up the valid session and route safely
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _parseSignUpError(e.toString(), context);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseSignUpError(String error, BuildContext context) {
    if (error.contains('already registered')) {
      return AppLocalizations.of(context)!.emailAlreadyRegistered;
    }
    if (error.contains('email_address_invalid') ||
        error.contains('is invalid')) {
      return AppLocalizations.of(context)!.invalidEmailAddress;
    }
    if (error.contains('rate limit') || error.contains('429')) {
      return AppLocalizations.of(context)!.tooManyAttempts;
    }
    if (error.contains('weak_password') || error.contains('too short')) {
      return AppLocalizations.of(context)!.passwordTooWeak;
    }
    if (error.contains('network') || error.contains('SocketException')) {
      return AppLocalizations.of(context)!.networkErrorCheckConnection;
    }
    return AppLocalizations.of(context)!.signUpFailed(
      error.replaceAll('AuthException(message: ', '').replaceAll(')', ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFF1F5F9),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      PhosphorIcons.arrowLeft(),
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                if (_success) ...[
                  _buildSuccessCard(isDark),
                ] else ...[
                  _buildHeader(isDark),
                  const SizedBox(height: 32),
                  _buildFormCard(isDark),
                  const SizedBox(height: 24),
                  _buildLoginLink(isDark),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white12 : Colors.white60),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 40,
            ),
          ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.accountCreated,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(
              context,
            )!.verifyEmailDesc(_emailCtrl.text.trim()),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.goToSignIn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.15);
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Icon(
          PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
          size: 48,
          color: AppTheme.primaryColor,
        ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5)),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.createAccount,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildFormCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ).animate().shakeX(amount: 4),

                _buildField(
                  _nameCtrl,
                  AppLocalizations.of(context)!.fullName,
                  AppLocalizations.of(context)!.nameHint,
                  PhosphorIcons.user(),
                  isDark,
                  validator: (v) => v == null || v.isEmpty
                      ? AppLocalizations.of(context)!.nameRequired
                      : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  _usernameCtrl,
                  AppLocalizations.of(context)!.username,
                  AppLocalizations.of(context)!.usernameHint,
                  PhosphorIcons.at(),
                  isDark,
                  onChanged: (v) {
                    _onUsernameChanged(v);
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return AppLocalizations.of(context)!.usernameRequired;
                    }
                    if (v.trim().length < 5) {
                      return AppLocalizations.of(context)!.usernameTooShort;
                    }
                    if (v.trim().length > 10) {
                      return AppLocalizations.of(context)!.usernameTooLong;
                    }
                    if (RegExp(r'^\d+$').hasMatch(v.trim())) {
                      return AppLocalizations.of(context)!.usernameNumbersOnly;
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return AppLocalizations.of(context)!.usernameInvalid;
                    }
                    if (_usernameStatus == _UsernameStatus.taken) {
                      return AppLocalizations.of(context)!.usernameTaken;
                    }
                    return null;
                  },
                ),
                _buildUsernameStatus(AppLocalizations.of(context)!, isDark),
                const SizedBox(height: 14),
                _buildField(
                  _emailCtrl,
                  AppLocalizations.of(context)!.email,
                  AppLocalizations.of(context)!.emailHint,
                  PhosphorIcons.envelope(),
                  isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.emailRequired;
                    }
                    if (!v.contains('@')) {
                      return AppLocalizations.of(context)!.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildField(
                  _passwordCtrl,
                  AppLocalizations.of(context)!.password,
                  AppLocalizations.of(context)!.passwordHint,
                  PhosphorIcons.lock(),
                  isDark,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return AppLocalizations.of(context)!.passwordMinLength;
                    }
                    return null;
                  },
                ),

                // Password strength indicator
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength(),
                            backgroundColor: isDark
                                ? Colors.white12
                                : Colors.black12,
                            color: _strengthColor(),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _strengthLabel(context),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _strengthColor(),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                _buildField(
                  _confirmCtrl,
                  AppLocalizations.of(context)!.confirmPasswordLabel,
                  AppLocalizations.of(context)!.passwordHint,
                  PhosphorIcons.lockKey(),
                  isDark,
                  obscure: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? PhosphorIcons.eye()
                          : PhosphorIcons.eyeSlash(),
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) {
                      return AppLocalizations.of(context)!.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                _buildGradientButton(
                  label: _loading
                      ? AppLocalizations.of(context)!.creatingAccount
                      : AppLocalizations.of(context)!.createAccount,
                  icon: _loading ? null : PhosphorIcons.userPlus(),
                  onPressed: _loading ? null : _signUp,
                  loading: _loading,
                ),
                const SizedBox(height: 16),

                // Google Button
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signUpWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 32),
                  label: Text(
                    AppLocalizations.of(context)!.signUpWithGoogle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.alreadyHaveAccount,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            AppLocalizations.of(context)!.signIn,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon,
    bool isDark, {
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: (v) {
        if (ctrl == _passwordCtrl) setState(() {});
        onChanged?.call(v);
      },
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Container(
      height: 54,
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
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
