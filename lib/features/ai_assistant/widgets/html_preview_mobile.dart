import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mobile HTML/CSS/JS preview rendered inside a native WebView.
///
/// Uses `webview_flutter` to load HTML content via `loadHtmlString`.
/// Provides expand/collapse and fullscreen controls matching the web version.
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
  late final WebViewController _controller;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        widget.isDark ? const Color(0xFF0F172A) : Colors.white,
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  void didUpdateWidget(covariant HtmlPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      _controller.loadHtmlString(widget.htmlContent);
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
            color: const Color(0xFF3B82F6)
                .withValues(alpha: isDark ? 0.08 : 0.05),
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
                ...List.generate(
                  3,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        const Color(0xFFEF4444),
                        const Color(0xFFFBBF24),
                        const Color(0xFF22C55E),
                      ][i]
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
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
                      _expanded
                          ? Icons.unfold_less_rounded
                          : Icons.unfold_more_rounded,
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
          // ── WebView body ──
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _FullscreenPreviewDialog(
        htmlContent: widget.htmlContent,
        isDark: widget.isDark,
      ),
    );
  }
}

/// Fullscreen dialog with its own [WebViewController] so it renders
/// independently from the inline preview.
class _FullscreenPreviewDialog extends StatefulWidget {
  final String htmlContent;
  final bool isDark;
  const _FullscreenPreviewDialog({
    required this.htmlContent,
    required this.isDark,
  });

  @override
  State<_FullscreenPreviewDialog> createState() =>
      _FullscreenPreviewDialogState();
}

class _FullscreenPreviewDialogState extends State<_FullscreenPreviewDialog> {
  late final WebViewController _fsController;

  @override
  void initState() {
    super.initState();
    _fsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        widget.isDark ? const Color(0xFF0F172A) : Colors.white,
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'معاينة بشاشة كاملة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 20,
                    color: isDark ? Colors.white54 : Colors.black45,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: WebViewWidget(controller: _fsController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
