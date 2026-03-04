import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ModernFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Widget? label;
  final String? tooltip;

  const ModernFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  }) : label = null;

  const ModernFab.extended({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExtended = label != null;

    final child = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: isDark ? 0.85 : 0.95),
            AppTheme.primaryDark.withValues(alpha: isDark ? 0.9 : 1.0),
          ],
        ),
        borderRadius: BorderRadius.circular(isExtended ? 100 : 30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isExtended ? 100 : 30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              highlightColor: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.1),
              splashColor: Colors.white.withValues(alpha: 0.2),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isExtended ? 16 : 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: const IconThemeData(color: Colors.white, size: 20),
                      child: icon,
                    ),
                    if (isExtended) ...[
                      const SizedBox(width: 8),
                      DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                        child: label!,
                      ),
                      const SizedBox(width: 4), // extra breathing room
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }

    return child;
  }
}
