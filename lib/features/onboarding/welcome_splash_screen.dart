import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';

/// Full-screen splash shown ONCE on the very first app launch.
/// Displays the welcome image beautifully for 5 seconds, then navigates away.
class WelcomeSplashScreen extends StatefulWidget {
  const WelcomeSplashScreen({super.key});

  @override
  State<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends State<WelcomeSplashScreen> {
  static const Duration _displayDuration = Duration(seconds: 5);

  Timer? _navTimer;
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();
    // Navigate away after 5 seconds
    _navTimer = Timer(_displayDuration, _leaveScreen);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  Future<void> _leaveScreen() async {
    if (!mounted) return;

    // Mark first launch done so this never shows again
    await SettingsRepository().setHasSeenWelcomeScreen(true);

    setState(() => _fadingOut = true);
    // Let the fade-out animate (500 ms) then navigate
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _fadingOut ? 0.0 : 1.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.darkBg,
                      AppTheme.darkSurface,
                      const Color(0xFF1A1440),
                    ]
                  : [
                      const Color(0xFFE8EAF6),
                      const Color(0xFFC5CAE9),
                      const Color(0xFFD5CCF5),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // ── Decorative background blobs ──
              _buildBlob(
                isDark: isDark,
                top: -size.height * 0.12,
                right: -size.width * 0.15,
                diameter: size.width * 0.65,
                colorDark: AppTheme.primaryColor,
                colorLight: AppTheme.primaryLight,
                opacityDark: 0.18,
                opacityLight: 0.35,
              ),
              _buildBlob(
                isDark: isDark,
                bottom: size.height * 0.08,
                left: -size.width * 0.25,
                diameter: size.width * 0.55,
                colorDark: const Color(0xFF7C4DFF),
                colorLight: const Color(0xFFEDE7F6),
                opacityDark: 0.12,
                opacityLight: 0.5,
              ),
              _buildBlob(
                isDark: isDark,
                bottom: -size.height * 0.05,
                right: -size.width * 0.1,
                diameter: size.width * 0.4,
                colorDark: const Color(0xFF448AFF),
                colorLight: const Color(0xFFBBDEFB),
                opacityDark: 0.10,
                opacityLight: 0.30,
              ),

              // ── Centered welcome image ──
              Center(child: _buildWelcomeImage(size, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Welcome image with glow and entrance animation ──
  Widget _buildWelcomeImage(Size size, bool isDark) {
    return Container(
          width: size.width * 0.85,
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: size.height * 0.6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              // Primary glow
              BoxShadow(
                color: AppTheme.primaryColor.withValues(
                  alpha: isDark ? 0.45 : 0.25,
                ),
                blurRadius: 64,
                spreadRadius: 8,
                offset: const Offset(0, 12),
              ),
              // Deeper shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              isDark
                  ? 'assets/onboarding/welcome_image_light.png'
                  : 'assets/onboarding/welcome_image_dark.png',
              fit: BoxFit.cover,
            ),
          ),
        )
        // Entrance: fade in + scale up from smaller
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .scaleXY(
          begin: 0.75,
          end: 1.0,
          duration: 1000.ms,
          curve: Curves.elasticOut,
        )
        // Subtle shimmer sweep after entrance
        .then(delay: 200.ms)
        .shimmer(
          delay: 500.ms,
          duration: 2000.ms,
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12),
        );
  }

  // ── Decorative background blob ──
  Widget _buildBlob({
    required bool isDark,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double diameter,
    required Color colorDark,
    required Color colorLight,
    required double opacityDark,
    required double opacityLight,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isDark ? colorDark : colorLight).withValues(
            alpha: isDark ? opacityDark : opacityLight,
          ),
        ),
      ),
    );
  }
}
