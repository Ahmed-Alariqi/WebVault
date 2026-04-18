import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class CoachMark extends StatelessWidget {
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLast;
  final int currentStep;
  final int totalSteps;

  const CoachMark({
    super.key,
    required this.title,
    required this.description,
    this.targetKey,
    required this.onNext,
    required this.onSkip,
    this.isLast = false,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final viewPadding = MediaQuery.of(context).padding;
    
    // Calculate target position and size
    Rect targetRect = Rect.fromLTWH(
      screenSize.width / 2 - 40,
      screenSize.height / 2 - 40,
      80,
      80,
    );

    if (targetKey != null && targetKey!.currentContext != null) {
      final box = targetKey!.currentContext!.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      targetRect = offset & box.size;
    }

    final double holeLeft = targetRect.left;
    final double holeTop = targetRect.top;
    final double holeWidth = targetRect.width;
    final double holeHeight = targetRect.height;

    // Enhanced Tooltip positioning logic with increased clearance
    double tooltipTop;
    const double clearance = 45; // Increased clearance to prevent overlap
    
    if (holeTop > screenSize.height * 0.55) {
      // Target is in the bottom half, show tooltip ABOVE the target
      tooltipTop = holeTop - 220; // Increased distance
    } else {
      // Target is in the top half, show tooltip BELOW the target
      tooltipTop = holeTop + holeHeight + clearance;
    }

    // Constraints to keep tooltip fully on screen
    tooltipTop = tooltipTop.clamp(viewPadding.top + 20, screenSize.height - 240);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 💎 Glassmorphism Background Blur
          Positioned.fill(
            child: GestureDetector(
              onTap: onSkip,
              child: ClipPath(
                clipper: _InvertedClipper(targetRect.inflate(8)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),

          // Subdued dim layer
          Positioned.fill(
            child: IgnorePointer(
              child: ClipPath(
                clipper: _InvertedClipper(targetRect.inflate(8)),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // 🌟 Animated Pulse Ring
          Positioned(
            left: holeLeft - 8,
            top: holeTop - 8,
            width: holeWidth + 16,
            height: holeHeight + 16,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: boxSizeIsCircle(targetRect) ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: boxSizeIsCircle(targetRect) ? null : BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.6), width: 4),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1200.ms, curve: Curves.easeOut)
              .fadeOut(begin: 0.8, duration: 1200.ms),
            ),
          ),

          // Static focus border
          Positioned(
            left: holeLeft - 8,
            top: holeTop - 8,
            width: holeWidth + 16,
            height: holeHeight + 16,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: boxSizeIsCircle(targetRect) ? null : BorderRadius.circular(18),
                  shape: boxSizeIsCircle(targetRect) ? BoxShape.circle : BoxShape.rectangle,
                  border: Border.all(color: AppTheme.primaryColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🚀 Modern Premium Tooltip
          Positioned(
            top: tooltipTop,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF2D2D44), const Color(0xFF1E1E2E)]
                    : [Colors.white, const Color(0xFFF9FAFF)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(
                  color: (isDark ? Colors.white : AppTheme.primaryColor).withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Indicator & Close
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor.withValues(alpha: 0.2), AppTheme.primaryColor.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${currentStep + 1} / $totalSteps',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onSkip,
                        icon: const Icon(Icons.close_rounded, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                       if (!isLast)
                        TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white30 : Colors.black38,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.tutSkip,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: Text(
                            isLast ? AppLocalizations.of(context)!.tutGotIt : AppLocalizations.of(context)!.tutNext,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  bool boxSizeIsCircle(Rect rect) {
    return (rect.width - rect.height).abs() < 5;
  }
}

class _InvertedClipper extends CustomClipper<Path> {
  final Rect hole;

  _InvertedClipper(this.hole);

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular((hole.width - hole.height).abs() < 5 ? 100 : 18)))
      ..fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(_InvertedClipper oldClipper) => oldClipper.hole != hole;
}
