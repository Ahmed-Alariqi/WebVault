import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';

enum _Step { email, otp, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  /// Flag to prevent router from redirecting during OTP recovery flow.
  /// When true, the router should NOT redirect away from /forgot-password.
  static bool isRecoveryInProgress = false;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  _Step _step = _Step.email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    ForgotPasswordScreen.isRecoveryInProgress = false;
    super.dispose();
  }

  // ─── Step 1: Send OTP ───
  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.forgotPasswordEmptyEmail);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailCtrl.text.trim());
      setState(() => _step = _Step.otp);
    } catch (e) {
      setState(() => _error = l10n.forgotPasswordFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Step 2: Verify OTP ───
  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_otpCtrl.text.trim().length != 8) {
      setState(() => _error = l10n.otpInvalidCode);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Set flag BEFORE verifyOTP so the router doesn't redirect
      ForgotPasswordScreen.isRecoveryInProgress = true;
      final authService = ref.read(authServiceProvider);
      await authService.verifyRecoveryOtp(
        _emailCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );
      setState(() => _step = _Step.newPassword);
    } catch (e) {
      ForgotPasswordScreen.isRecoveryInProgress = false;
      setState(() => _error = l10n.otpInvalidCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Step 3: Update Password ───
  Future<void> _updatePassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _error = l10n.passwordMismatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updatePassword(_passwordCtrl.text);
      // Sign out the recovery session so the user logs in fresh
      ForgotPasswordScreen.isRecoveryInProgress = false;
      await authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Flexible(child: Text(l10n.passwordUpdatedSuccess)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() => _error = l10n.passwordUpdateFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0D0D1A), const Color(0xFF1A1A2E)]
                : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (_step == _Step.email) {
                        context.pop();
                      } else if (_step == _Step.otp) {
                        setState(() {
                          _step = _Step.email;
                          _error = null;
                          _otpCtrl.clear();
                        });
                      } else {
                        setState(() {
                          _step = _Step.otp;
                          _error = null;
                          _passwordCtrl.clear();
                          _confirmPasswordCtrl.clear();
                        });
                      }
                    },
                    icon: Icon(
                      PhosphorIcons.arrowLeft(),
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildIcon(),
                const SizedBox(height: 24),
                Text(
                  _stepTitle(l10n),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.white60,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: _buildStepContent(isDark, l10n),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (_step) {
      case _Step.email:
        icon = PhosphorIcons.key(PhosphorIconsStyle.fill);
        break;
      case _Step.otp:
        icon = PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill);
        break;
      case _Step.newPassword:
        icon = PhosphorIcons.lockKey(PhosphorIconsStyle.fill);
        break;
    }
    return Icon(
      icon,
      size: 56,
      color: AppTheme.primaryColor,
    ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5));
  }

  String _stepTitle(AppLocalizations l10n) {
    switch (_step) {
      case _Step.email:
        return l10n.forgotPasswordTitle;
      case _Step.otp:
        return l10n.forgotPasswordEmailSent;
      case _Step.newPassword:
        return l10n.newPassword;
    }
  }

  Widget _buildStepContent(bool isDark, AppLocalizations l10n) {
    switch (_step) {
      case _Step.email:
        return _buildEmailStep(isDark, l10n);
      case _Step.otp:
        return _buildOtpStep(isDark, l10n);
      case _Step.newPassword:
        return _buildPasswordStep(isDark, l10n);
    }
  }

  // ════════════════════════ Step 1: Email ════════════════════════
  Widget _buildEmailStep(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.forgotPasswordInstructions,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorBanner(),
        _buildTextField(
          controller: _emailCtrl,
          label: 'Email',
          hint: l10n.emailPlaceholder,
          icon: PhosphorIcons.envelope(),
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: l10n.forgotPasswordSendButton,
          icon: PhosphorIcons.paperPlaneTilt(),
          onPressed: _loading ? null : _sendOtp,
        ),
      ],
    );
  }

  // ════════════════════════ Step 2: OTP ════════════════════════
  Widget _buildOtpStep(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.forgotPasswordCheckEmail,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorBanner(),
        _buildTextField(
          controller: _otpCtrl,
          label: l10n.enterOtp,
          hint: l10n.enterOtpHint,
          icon: PhosphorIcons.shieldCheck(),
          isDark: isDark,
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: l10n.otpVerifyButton,
          icon: PhosphorIcons.checkCircle(),
          onPressed: _loading ? null : _verifyOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _sendOtp,
            child: Text(
              l10n.forgotPasswordSendButton,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════ Step 3: New Password ════════════════════════
  Widget _buildPasswordStep(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) _errorBanner(),
        _buildTextField(
          controller: _passwordCtrl,
          label: l10n.newPassword,
          hint: '••••••••',
          icon: PhosphorIcons.lock(),
          isDark: isDark,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
              size: 20,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordCtrl,
          label: l10n.confirmNewPassword,
          hint: '••••••••',
          icon: PhosphorIcons.lockKey(),
          isDark: isDark,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? PhosphorIcons.eye()
                  : PhosphorIcons.eyeSlash(),
              size: 20,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: l10n.updatePasswordButton,
          icon: PhosphorIcons.floppyDisk(),
          onPressed: _loading ? null : _updatePassword,
        ),
      ],
    );
  }

  // ════════════════════════ Shared Widgets ════════════════════════

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
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
        child: _loading
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
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
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
