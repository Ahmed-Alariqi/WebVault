import '../../presentation/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // GoRouter's refreshListenable detects auth state change
      // and automatically redirects to /dashboard
    } catch (e) {
      if (mounted) setState(() => _error = _parseError(e.toString(), context));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    final localAuth = LocalAuthentication();
    final localizedReason = AppLocalizations.of(context)!.authToSignIn;

    final canCheck = await localAuth.canCheckBiometrics;
    if (!canCheck) return;

    final didAuth = await localAuth.authenticate(
      localizedReason: localizedReason,
    );
    if (didAuth && mounted) {
      // Biometric just unlocks if session already exists
      final authService = ref.read(authServiceProvider);
      if (authService.isAuthenticated) {
        context.go('/dashboard');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      // GoRouter handles the rest automatically
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) setState(() => _error = _parseError(e.toString(), context));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseError(String error, BuildContext context) {
    if (error.contains('Invalid login credentials')) {
      return AppLocalizations.of(context)!.invalidEmailOrPassword;
    }
    if (error.contains('Email not confirmed')) {
      return AppLocalizations.of(context)!.verifyEmailFirst;
    }
    if (error.contains('network')) {
      return AppLocalizations.of(context)!.networkErrorCheckConnection;
    }
    return AppLocalizations.of(context)!.loginFailedTryAgain;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final bgWidget = Stack(
      children: [
        // 1. Background Gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [
                      const Color(0xFF0F172A), // Slate 900
                      const Color(0xFF020617), // Slate 950
                    ]
                  : [
                      const Color(0xFFF8FAFC), // Slate 50
                      const Color(0xFFF1F5F9), // Slate 100
                      const Color(0xFFEFF6FF), // Very soft blue (Indigo 50 equivalent)
                    ],
            ),
          ),
        ),

        // 2. Decorative Blobs
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: size.width * 0.9,
            height: size.width * 0.9,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppTheme.primaryColor.withValues(alpha: 0.05)
                  : AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: -50,
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                  : AppTheme.primaryColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Center-ish blue glow behind the card for Light Mode
        if (!isDark) ...[
          Positioned(
            top: size.height * 0.3,
            left: size.width * 0.1,
            right: size.width * 0.1,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Extra top-right spot for Light Mode
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Extra bottom-left spot for Light Mode
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
        // New Top-Right subtle bubble
        Positioned(
          top: 40,
          right: -20,
          child: Container(
            width: size.width * 0.4,
            height: size.width * 0.4,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  isDark ? Colors.purpleAccent.withValues(alpha: 0.15) : Colors.purpleAccent.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );

    return ResponsiveLayout(
      maxWidth: 460,
      background: bgWidget,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (size.width <= 900) bgWidget,
          // 3. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.01),

                  // Logo / Branding
                  _buildLogo(isDark),
                  const SizedBox(height: 12),

                  // Login Card
                  _buildLoginCard(isDark),
                  const SizedBox(height: 12),

                  // Sign Up Link
                  _buildSignUpLink(isDark),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        // Sign In heading
        Text(
          AppLocalizations.of(context)!.signIn,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ).animate().fadeIn(duration: 400.ms),

        // Welcome image
        Image.asset(
              isDark
                  ? 'assets/onboarding/welcome_image_light.png'
                  : 'assets/onboarding/welcome_image_dark.png',
              height: 190,
              fit: BoxFit.contain,
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              curve: Curves.elasticOut,
              duration: 800.ms,
            ),
      ],
    );
  }

  Widget _buildLoginCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.4) 
                    : AppTheme.primaryColor.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.signIn,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Error Banner
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
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.warningCircle(),
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shakeX(amount: 4, duration: 400.ms),

                // Email
                _buildTextField(
                  controller: _emailCtrl,
                  label: AppLocalizations.of(context)!.email,
                  hint: AppLocalizations.of(context)!.emailHint,
                  icon: PhosphorIcons.envelope(),
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.required;
                    }
                    if (!v.contains('@')) {
                      return AppLocalizations.of(context)!.required;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordCtrl,
                  label: AppLocalizations.of(context)!.password,
                  hint: AppLocalizations.of(context)!.passwordHint,
                  icon: PhosphorIcons.lock(),
                  isDark: isDark,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                      size: 20,
                      color: isDark ? Colors.white38 : const Color(0xFF334155),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.required;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Remember / Forgot
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? true),
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.rememberMe,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: Text(
                        AppLocalizations.of(context)!.forgotPassword,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sign In Button
                _buildGradientButton(
                  label: _loading
                      ? AppLocalizations.of(context)!.loading
                      : AppLocalizations.of(context)!.signIn,
                  icon: _loading ? null : PhosphorIcons.signIn(),
                  onPressed: _loading ? null : _signIn,
                  loading: _loading,
                ),
                const SizedBox(height: 16),

                // Biometric Button
                Center(
                  child: GestureDetector(
                    onTap: _biometricLogin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.fingerprint(),
                            size: 20,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.useBiometrics,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Google Button
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 32),
                  label: Text(
                    AppLocalizations.of(context)!.continueWithGoogle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildSignUpLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.dontHaveAccount,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: Text(
            AppLocalizations.of(context)!.signUp,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white38 : const Color(0xFF334155),
        ),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF334155),
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white24 : const Color(0xFF64748B),
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
          colors: [AppTheme.primaryColor, Color(0xFF4285F4)],
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
