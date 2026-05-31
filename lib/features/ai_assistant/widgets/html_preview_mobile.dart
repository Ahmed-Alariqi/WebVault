import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mobile/Desktop HTML/CSS/JS preview.
///
/// Uses `webview_flutter` on mobile and falls back to a clean external browser viewer on Windows.
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
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || !Platform.isWindows) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(
          widget.isDark ? const Color(0xFF0F172A) : Colors.white,
        )
        ..loadHtmlString(widget.htmlContent);
    }
  }

  @override
  void didUpdateWidget(covariant HtmlPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb || !Platform.isWindows) {
      if (oldWidget.htmlContent != widget.htmlContent) {
        _controller.loadHtmlString(widget.htmlContent);
      }
    }
  }

  Future<void> _openHtmlExternally() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.html');
      await tempFile.writeAsString(widget.htmlContent);
      await launchUrl(Uri.file(tempFile.path), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، فشل فتح المعاينة الخارجية')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isWindows = !kIsWeb && Platform.isWindows;
    final height = _expanded ? 420.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(top: 8),
      height: isWindows ? 180.0 : height + 36, // 36 for the header bar
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
                const Icon(
                  Icons.language_rounded,
                  size: 13,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 4),
                Text(
                  isWindows ? 'معاينة HTML المباشرة' : 'معاينة مباشرة',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const Spacer(),
                if (!isWindows) ...[
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
              ],
            ),
          ),
          // ── Body ──
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: isWindows
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'اضغط على الزر أدناه لفتح معاينة الصفحة التفاعلية مباشرة في متصفحك الافتراضي.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openHtmlExternally,
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.open_in_new_rounded, size: 16),
                              label: const Text(
                                'فتح المعاينة الخارجية',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _controller),
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
    if (kIsWeb || !Platform.isWindows) {
      _fsController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(
          widget.isDark ? const Color(0xFF0F172A) : Colors.white,
        )
        ..loadHtmlString(widget.htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isWindows = !kIsWeb && Platform.isWindows;

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
                  const Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'معاينة بشاشة كاملة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white70 : Colors.black87, // fallback to black87 if black87 is too harsh
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
            // WebView / Fallback
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: isWindows
                    ? Center(
                        child: Text(
                          'المعاينة التفاعلية بشاشة كاملة غير مدعومة على هذا النظام.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      )
                    : WebViewWidget(controller: _fsController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
