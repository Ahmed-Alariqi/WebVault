import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

/// Live HTML/CSS/JS preview rendered inside an iframe.
///
/// Works only on Flutter Web. Uses `srcdoc` to inject the full HTML document
/// into a sandboxed iframe — no external server needed.
class HtmlPreviewWidget extends StatefulWidget {
  final String htmlContent;
  final bool isDark;
  const HtmlPreviewWidget({
    super.key,
    required this.htmlContent,
    required this.isDark,
  });

  @override
  State<HtmlPreviewWidget> createState() => _HtmlPreviewWidgetState();
}

class _HtmlPreviewWidgetState extends State<HtmlPreviewWidget> {
  late final String _viewId;
  html.IFrameElement? _iframe;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'html-preview-${identityHashCode(this)}-${DateTime.now().millisecondsSinceEpoch}';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = widget.htmlContent
        // Allow scripts but sandbox everything else for safety
        ..setAttribute('sandbox', 'allow-scripts allow-same-origin');
      _iframe = iframe;
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant HtmlPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      _iframe?.srcdoc = widget.htmlContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final height = _expanded ? 420.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(top: 8),
      height: height + 36, // 36 for the header bar
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header bar ──
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                // 3 dots (browser look)
                ...List.generate(3, (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: [
                      const Color(0xFFEF4444),
                      const Color(0xFFFBBF24),
                      const Color(0xFF22C55E),
                    ][i].withValues(alpha: 0.7),
                  ),
                )),
                const SizedBox(width: 8),
                Icon(
                  Icons.language_rounded,
                  size: 13,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 4),
                Text(
                  'معاينة مباشرة',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const Spacer(),
                // Expand/collapse button
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                // Fullscreen button
                GestureDetector(
                  onTap: () => _openFullscreen(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.fullscreen_rounded,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── iframe body ──
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: HtmlElementView(viewType: _viewId),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              // Header
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fullscreen_exit_rounded,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'معاينة ملء الشاشة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: widget.isDark ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: HtmlPreviewWidget(
                    htmlContent: widget.htmlContent,
                    isDark: widget.isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
