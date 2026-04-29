import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsing hero header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            stretch: true,
            backgroundColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFF5C6BC0),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
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
                                const Color(0xFF3949AB),
                                const Color(0xFF5C6BC0),
                                const Color(0xFF7986CB),
                              ],
                      ),
                    ),
                  ),

                  // Decorative circles
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  // Logo + name — wrapped in LayoutBuilder to prevent overflow
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  isDark
                                      ? 'assets/onboarding/welcome_image_light.png'
                                      : 'assets/onboarding/welcome_image_dark.png',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                curve: Curves.elasticOut,
                                duration: 900.ms,
                              ),
                        
                          const Text(
                            'ZaadTech',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '${loc.version} $kAppVersion',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ).animate().fadeIn(delay: 350.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tagline card
                _GlassCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.aboutTaglineTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          loc.aboutTaglineSubtitle,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.aboutTaglineBody,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Section title
                _SectionTitle(
                  title: loc.aboutFeaturesTitle,
                  isDark: isDark,
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 12),

                // Feature cards
                _FeatureCard(
                  emoji: '🔎',
                  title: loc.aboutFeature1Title,
                  body: loc.aboutFeature1Body,
                  accent: AppTheme.primaryColor,
                  isDark: isDark,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '🤖',
                  title: loc.aboutFeatureZadExpertTitle,
                  body: loc.aboutFeatureZadExpertBody,
                  accent: const Color(0xFF7C4DFF),
                  isDark: isDark,
                ).animate().fadeIn(delay: 230.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '✨',
                  title: loc.aboutFeatureExplorerAiTitle,
                  body: loc.aboutFeatureExplorerAiBody,
                  accent: const Color(0xFFEC407A),
                  isDark: isDark,
                ).animate().fadeIn(delay: 245.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '🪄',
                  title: loc.aboutFeatureBrowserAiTitle,
                  body: loc.aboutFeatureBrowserAiBody,
                  accent: const Color(0xFF26A69A),
                  isDark: isDark,
                ).animate().fadeIn(delay: 255.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '📋',
                  title: loc.aboutFeature2Title,
                  body: loc.aboutFeature2Body,
                  accent: const Color(0xFF009688),
                  isDark: isDark,
                ).animate().fadeIn(delay: 260.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '🔖',
                  title: loc.aboutFeature3Title,
                  body: loc.aboutFeature3Body,
                  accent: const Color(0xFFFF7043),
                  isDark: isDark,
                ).animate().fadeIn(delay: 320.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '⚡',
                  title: loc.aboutFeature4Title,
                  body: loc.aboutFeature4Body,
                  accent: const Color(0xFFFFD600),
                  isDark: isDark,
                ).animate().fadeIn(delay: 380.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '🧠',
                  title: loc.aboutFeature5Title,
                  body: loc.aboutFeature5Body,
                  accent: const Color(0xFF9C27B0),
                  isDark: isDark,
                ).animate().fadeIn(delay: 440.ms).slideX(begin: 0.08),

                const SizedBox(height: 12),

                _FeatureCard(
                  emoji: '👥',
                  title: loc.aboutFeature6Title,
                  body: loc.aboutFeature6Body,
                  accent: const Color(0xFF2196F3),
                  isDark: isDark,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.08),

                const SizedBox(height: 24),

                // Goal card
                _GlassCard(
                  isDark: isDark,
                  accent: AppTheme.primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                PhosphorIcons.target(PhosphorIconsStyle.fill),
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loc.aboutGoalTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.aboutGoalBody,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Tagline banner
                _GlassCard(
                      isDark: isDark,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Text(
                          loc.aboutTaglineBanner,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 700.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 24),

                // Dev info card
                _GlassCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.accentColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            PhosphorIcons.code(PhosphorIconsStyle.fill),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc.version} $kAppVersion',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.aboutDevLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.accentColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
    required this.isDark,
  });

  final String emoji;
  final String title;
  final String body;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
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
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.isDark,
    required this.child,
    this.accent,
    this.gradient,
  });

  final bool isDark;
  final Widget child;
  final Color? accent;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.85))
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent != null && gradient == null
                  ? accent!.withValues(alpha: 0.3)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.6)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
