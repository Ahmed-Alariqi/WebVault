import 'package:flutter/material.dart';
import 'dart:ui';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool showFrame;
  final Widget? background;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.showFrame = true,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Mobile view (width <= 900): return child directly
    if (screenWidth <= 900) {
      return child;
    }

    // Wide screen (Desktop/Web): show framed centered content
    final outerBgColor = isDark 
        ? const Color(0xFF0B0F19) 
        : const Color(0xFFF1F5F9);
    
    final frameBorderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: background != null ? Colors.transparent : outerBgColor,
      body: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          // Ambient glow elements for desktop premium aesthetic
          if (showFrame && background == null) ...[
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: isDark ? 0.04 : 0.02),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9C27B0).withValues(alpha: isDark ? 0.03 : 0.015),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: showFrame 
                  ? BoxDecoration(
                      color: background != null
                          ? (isDark 
                              ? const Color(0xFF1E293B).withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.55))
                          : (isDark ? const Color(0xFF020617) : Colors.white),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: background != null
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.6))
                            : frameBorderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    )
                  : null,
              clipBehavior: showFrame ? Clip.antiAlias : Clip.none,
              child: background != null && showFrame
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: child,
                      ),
                    )
                  : child,
            ),
          ),
        ],
      ),
    );
  }
}
