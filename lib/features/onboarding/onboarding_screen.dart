import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';

/// Data model for each onboarding page
class _OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
  // Screen 1 — المشكلة
  _OnboardingPage(
    title: 'كل شيء مفيد… يضيع بسهولة',
    description:
        'روابط، أدوات، مفاتيح API، أكواد، ومصادر تمر عليك يوميًا… لكن الوصول لها لاحقًا ليس دائمًا سهل.\n\nزاد التقني يجمعها لك في مكان واحد.',
    imagePath: 'assets/onboarding/onboarding_1.png',
  ),

  // Screen 2 — المستكشف
  _OnboardingPage(
    title: 'اكتشف ما يفيدك فعلًا',
    description:
        'أفضل الأدوات، المواقع، الكورسات، والعروض التقنية — مختارة بعناية بعيدًا عن التشتت والتكرار.',
    imagePath: 'assets/onboarding/onboarding_2.png',
  ),

  // Screen 3 — الحفظ والتنظيم
  _OnboardingPage(
    title: 'احفظ كل ما تحتاجه',
    description:
        'من روابطك المهمة إلى مفاتيح API، الأكواد، الحسابات، وأي قيمة تستخدمها… كل شيء منظم وسهل الوصول.',
    imagePath: 'assets/onboarding/onboarding_3.png',
  ),

  // Screen 4 — الحافظة الذكية
  _OnboardingPage(
    title: 'احفظ من أي مكان… فورًا',
    description:
        'حدد أي نص أو قيمة وشاركها مباشرة إلى زاد التقني.\nبدون خطوات معقدة، وبدون مغادرة ما تعمل عليه.',
    imagePath: 'assets/onboarding/onboarding_4.png',
  ),

  // Screen 5 — المجتمع
  _OnboardingPage(
    title: 'لست وحدك في رحلتك التقنية',
    description:
        'مجتمع تقني يشارك الأدوات، الخبرات، والتجارب — لتتعلم أسرع وتبقى دائمًا في المقدمة.',
    imagePath: 'assets/onboarding/onboarding_5.png',
  ),

  // Screen 6 — الشاشة الأخيرة
  _OnboardingPage(
    title: 'كل ما تحتاجه… في مكان واحد',
    description:
        'زاد التقني هو مركزك الذكي لتنظيم كل ما يهمك على الإنترنت والوصول إليه في أي وقت.',
    imagePath: 'assets/onboarding/onboarding_6.png',
  ),
];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _pages.length) return;

    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _nextPage() {
    _goToPage(_currentPage + 1);
  }

  void _prevPage() {
    _goToPage(_currentPage - 1);
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.lightImpact(); // Subtle satisfying feedback
    final settingsRepo = SettingsRepository();
    await settingsRepo.setOnboardingCompleted(true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == _pages.length - 1;
    final isFirstPage = _currentPage == 0;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A14)
          : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Subtle background decoration (Glassmorphism blobs)
          _buildBackgroundDecoration(isDark),

          SafeArea(
            child: Column(
              children: [
                // Header (Skip Button)
                _buildHeader(isDark, isLastPage),

                // Main Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPageContent(_pages[index], isDark, index);
                    },
                  ),
                ),

                // Footer (Dots + Navigation)
                _buildFooter(isDark, isFirstPage, isLastPage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration(bool isDark) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Top right subtle glow
          Positioned(
            top: -100,
            right: -50,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (isDark
                                    ? AppTheme.primaryColor
                                    : AppTheme.primaryLight)
                                .withValues(alpha: isDark ? 0.15 : 0.2),
                      ),
                    )
                    .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                    .scaleXY(
                      begin: 1.0,
                      end: 1.1,
                      duration: 8.seconds,
                      curve: Curves.easeInOutSine,
                    ),
          ),
          // Bottom left subtle glow
          Positioned(
            bottom: 100,
            left: -100,
            child:
                Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (isDark
                                    ? const Color(0xFF7C4DFF)
                                    : const Color(0xFFE8EAF6))
                                .withValues(alpha: isDark ? 0.1 : 0.5),
                      ),
                    )
                    .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                    .scaleXY(
                      begin: 0.9,
                      end: 1.05,
                      duration: 6.seconds,
                      curve: Curves.easeInOutSine,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Skip on top-right RTL
        children: [
          AnimatedOpacity(
            opacity: isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: TextButton(
              onPressed: isLastPage ? null : _completeOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white54 : Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'تخطي',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(_OnboardingPage page, bool isDark, int index) {
    final isActive = index == _currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Static Image
          Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 380),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(page.imagePath, fit: BoxFit.contain),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 600.ms, curve: Curves.easeOutSine)
              .slideY(
                begin: 0.05,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              )
              .scaleXY(
                begin: 0.95,
                end: 1.0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 32),

          // Title
          Text(
                page.title,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF1E1E2C),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(
                delay: 200.ms,
                duration: 600.ms,
                curve: Curves.easeOutSine,
              )
              .slideY(
                begin: 0.1,
                end: 0,
                delay: 200.ms,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 16),

          // Description
          Text(
                page.description,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(
                delay: 350.ms,
                duration: 600.ms,
                curve: Curves.easeOutSine,
              )
              .slideY(
                begin: 0.1,
                end: 0,
                delay: 350.ms,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, bool isFirstPage, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot Indicator (Static Size, Animated Color)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white24 : Colors.black12),
                  // Subtle glow ONLY on the active dot
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 40),

          // Navigation Buttons Container
          SizedBox(
            height: 52, // Fixed height for alignment
            child: isFirstPage
                ? Center(
                    child: _buildActionButton(
                      isDark: isDark,
                      isPrimary: true,
                      label: 'استكشف',
                      icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                      onPressed: _nextPage,
                      isNext: true,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Right side (RTL Start) — "رجوع" (Hidden on first page)
                      AnimatedOpacity(
                        opacity: isFirstPage ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: isFirstPage,
                          child: _buildActionButton(
                            isDark: isDark,
                            isPrimary: false,
                            label: 'رجوع',
                            icon: null,
                            onPressed: _prevPage,
                            isNext: false,
                          ),
                        ),
                      ),

                      // Left side (RTL End) — "التالي / ابدأ"
                      _buildActionButton(
                        isDark: isDark,
                        isPrimary: true,
                        label: isLastPage ? 'تسجيل الدخول' : 'التالي',
                        icon: isLastPage
                            ? PhosphorIcons.signIn(PhosphorIconsStyle.bold)
                            : PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                        onPressed: isLastPage ? _completeOnboarding : _nextPage,
                        isNext: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required bool isDark,
    required bool isPrimary,
    required String label,
    IconData? icon,
    required VoidCallback onPressed,
    required bool isNext,
  }) {
    return _AnimatedPressButton(
      onPressed: onPressed,
      child: Container(
        height: 48, // Smaller height
        padding: EdgeInsets.symmetric(horizontal: isPrimary ? 24 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Pill-shaped
          // Primary: Stylish gradient | Secondary: Subtle outline/transparent
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    Color(0xFF651FFF),
                  ], // Modern Indigo-Purple
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isPrimary
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03))
              : null,
          border: !isPrimary
              ? Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                )
              : null,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null && !isNext) ...[
              Icon(
                icon,
                size: 18,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF4A4A6A)),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 15, // Smaller font
                fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF4A4A6A)),
              ),
            ),
            if (icon != null && isNext) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

/// A widget that adds a satisfying scale-down press effect to any button
class _AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _AnimatedPressButton({required this.child, required this.onPressed});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Snappier interaction
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: widget.child,
      ),
    );
  }
}
