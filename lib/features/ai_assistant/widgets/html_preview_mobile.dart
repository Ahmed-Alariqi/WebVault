import 'package:flutter/material.dart';

/// Mobile stub — web preview is only available on Flutter Web.
/// Shows a disabled placeholder instead.
class HtmlPreviewWidget extends StatelessWidget {
  final String htmlContent;
  final bool isDark;
  const HtmlPreviewWidget({
    super.key,
    required this.htmlContent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Center(
        child: Text(
          'معاينة الويب متاحة فقط في نسخة الويب',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }
}
