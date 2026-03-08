import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';

/// Shown ONCE on the very first app launch, for 4 seconds,
/// before the onboarding flow begins.
class WelcomeSplashScreen extends StatefulWidget {
  const WelcomeSplashScreen({super.key});

  @override
  State<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends State<WelcomeSplashScreen>
    with SingleTickerProviderStateMixin {
  // ── countdown progress ──────────────────────────────────────────────────────
  static const Duration _displayDuration = Duration(seconds: 20);

  late final AnimationController _progressCtrl;
  Timer? _navTimer;

  // ── fade-out overlay ────────────────────────────────────────────────────────
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();

    // The circular ring fills over exactly 4 seconds
    _progressCtrl = AnimationController(vsync: this, duration: _displayDuration)
      ..forward();

    // Mark first launch done so this never shows again
    SettingsRepository().setHasSeenWelcomeScreen(true);

    // Navigate away after 4 s (tiny extra buffer for fade-out)
    _navTimer = Timer(_displayDuration, _leaveScreen);
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  Future<void> _leaveScreen() async {
    if (!mounted) return;
    setState(() => _fadingOut = true);
    // Let the fade-out animate (400 ms) then navigate
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) context.go('/dashboard');
  }

  // Web stub: skip the splash on web immediately
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) {
      SettingsRepository().setHasSeenWelcomeScreen(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/dashboard');
      });
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
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
              // ── decorative blobs ─────────────────────────────────────────
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

              // ── main content ────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Welcome Image — zoom + fade in
                    _buildWelcomeImage(size, isDark),

                    const Spacer(flex: 2),

                    // Countdown ring
                    _buildCountdownRing(isDark),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── welcome image with glass card effect ─────────────────────────────────
  Widget _buildWelcomeImage(Size size, bool isDark) {
    return Container(
          width: size.width * 0.82,
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: size.height * 0.55,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(
                  alpha: isDark ? 0.35 : 0.2,
                ),
                blurRadius: 48,
                spreadRadius: 4,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                blurRadius: 24,
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
        .animate()
        // Entrance: fade + scale up from slightly smaller
        .fadeIn(duration: 700.ms, curve: Curves.easeOut)
        .scaleXY(
          begin: 0.78,
          end: 1.0,
          duration: 900.ms,
          curve: Curves.elasticOut,
        )
        // Floating idle pulse (runs forever)
        .then(delay: 100.ms)
        .shimmer(
          delay: 400.ms,
          duration: 1800.ms,
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12),
        );
  }

  // ── animated progress ring with tap-to-skip ──────────────────────────────
  Widget _buildCountdownRing(bool isDark) {
    return GestureDetector(
          onTap: _leaveScreen,
          child: AnimatedBuilder(
            animation: _progressCtrl,
            builder: (_, _) {
              return SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Track ring (dimmed)
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 3.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    // Progress ring
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progressCtrl.value,
                        strokeWidth: 3.5,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white70 : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    // Inner skip icon
                    Icon(
                      Icons.skip_next_rounded,
                      size: 26,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.65)
                          : AppTheme.primaryColor.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              );
            },
          ),
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 500.ms)
        .slideY(
          begin: 0.3,
          end: 0,
          delay: 600.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ── helper: decorative background blob ───────────────────────────────────
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
