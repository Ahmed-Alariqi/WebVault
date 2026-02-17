import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/auth_providers.dart';

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
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

  String _strengthLabel() {
    final s = _passwordStrength();
    if (s == 0) return '';
    if (s < 0.3) return 'Weak';
    if (s < 0.6) return 'Fair';
    if (s < 0.8) return 'Good';
    return 'Strong';
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
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
        username: _usernameCtrl.text.trim().isEmpty
            ? null
            : _usernameCtrl.text.trim(),
      );
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _parseSignUpError(e.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseSignUpError(String error) {
    if (error.contains('already registered')) {
      return 'This email is already registered. Try signing in.';
    }
    if (error.contains('email_address_invalid') ||
        error.contains('is invalid')) {
      return 'Email address is invalid. Please use a real email.';
    }
    if (error.contains('rate limit') || error.contains('429')) {
      return 'Too many attempts. Please wait a few minutes.';
    }
    if (error.contains('weak_password') || error.contains('too short')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (error.contains('network') || error.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return 'Sign up failed: ${error.replaceAll('AuthException(message: ', '').replaceAll(')', '')}';
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
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFFC5CAE9),
                    const Color(0xFFE8EAF6),
                    const Color(0xFFE1BEE7),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),
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
            'Account Created!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a verification email to\n${_emailCtrl.text.trim()}\n\nPlease verify your email, then sign in.',
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
              child: const Text(
                'Go to Sign In',
                style: TextStyle(
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
          'Create Account',
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
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white12 : Colors.white60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
              'Full Name',
              'John Doe',
              PhosphorIcons.user(),
              isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              _usernameCtrl,
              'Username (optional)',
              'johndoe',
              PhosphorIcons.at(),
              isDark,
            ),
            const SizedBox(height: 14),
            _buildField(
              _emailCtrl,
              'Email',
              'you@email.com',
              PhosphorIcons.envelope(),
              isDark,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              _passwordCtrl,
              'Password',
              '••••••••',
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
                  return 'Password must be at least 6 characters';
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
                    _strengthLabel(),
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
              'Confirm Password',
              '••••••••',
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
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            const SizedBox(height: 28),

            _buildGradientButton(
              label: _loading ? 'Creating account...' : 'Create Account',
              icon: _loading ? null : PhosphorIcons.userPlus(),
              onPressed: _loading ? null : _signUp,
              loading: _loading,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
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
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: (_) {
        if (ctrl == _passwordCtrl) setState(() {});
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
