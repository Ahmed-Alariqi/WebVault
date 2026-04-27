import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../data/models/ai_chat_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../presentation/providers/ai_assistant_providers.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/zad_mermaid_view.dart';
import 'widgets/chat_prompt_bridge.dart';


class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final BuildContext context;
  CodeElementBuilder(this.isDark, this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (!element.textContent.contains('\n')) {
      return null; // Inline code uses default style
    }
    var language = 'dart';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      }
    }
    final codeText = element.textContent.trim();

    // ── MERMAID RENDERING ──
    if (language == 'mermaid') {
      return _MermaidChartWidget(
        codeText: codeText,
        isDark: isDark,
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282C34) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Code block header: language + copy ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const Spacer(),
                  _CopyCodeButton(code: codeText, isDark: isDark),
                ],
              ),
            ),
            // ── Code body ──
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  codeText,
                  language: language,
                  theme: isDark ? atomOneDarkTheme : githubTheme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small copy button used inside code blocks
class _CopyCodeButton extends StatefulWidget {
  final String code;
  final bool isDark;
  const _CopyCodeButton({required this.code, required this.isDark});

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey('check'),
                size: 14,
                color: Colors.green,
              )
            : Icon(
                Icons.copy_rounded,
                key: const ValueKey('copy'),
                size: 14,
                color: widget.isDark ? Colors.white38 : Colors.black38,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mermaid Chart Widget — renders diagrams locally using flutter_mermaid
// ─────────────────────────────────────────────────────────────────────────────
class _MermaidChartWidget extends StatefulWidget {
  final String codeText;
  final bool isDark;

  const _MermaidChartWidget({
    required this.codeText,
    required this.isDark,
  });

  @override
  State<_MermaidChartWidget> createState() => _MermaidChartWidgetState();
}

class _MermaidChartWidgetState extends State<_MermaidChartWidget>
    with AutomaticKeepAliveClientMixin {
  /// Non-null when Mermaid failed to parse / render the code. Used to swap
  /// the WebView for a friendly Arabic error UI with a "fix with AI" action.
  String? _errorMessage;
  bool _showCode = false;
  final ZadMermaidController _mermaidCtl = ZadMermaidController();

  /// The last value of `widget.codeText` that has been stable (unchanged)
  /// for [_stabilizationDelay]. Mermaid is only ever asked to render this
  /// value — never the in-flight streaming code — so partial/half-typed
  /// diagrams cannot trigger false parse errors.
  String? _stableCode;
  Timer? _stabilizer;

  /// How long the code must stay unchanged before we consider it final and
  /// hand it off to Mermaid. 500ms covers normal token bursts comfortably
  /// while still feeling instant on a fully-streamed message.
  static const Duration _stabilizationDelay = Duration(milliseconds: 500);

  bool get _hasError => _errorMessage != null;
  bool get _isStabilizing => _stableCode != widget.codeText;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scheduleStabilize();
  }

  void _scheduleStabilize() {
    _stabilizer?.cancel();
    _stabilizer = Timer(_stabilizationDelay, () {
      if (!mounted) return;
      if (_stableCode != widget.codeText) {
        setState(() => _stableCode = widget.codeText);
      }
    });
  }

  void _handleMermaidError(String msg) {
    if (!mounted) return;
    // Ignore errors reported for non-stable code (defensive — shouldn't
    // happen since we never feed Mermaid a streaming snapshot).
    if (_isStabilizing) return;
    setState(() => _errorMessage = msg);
  }

  @override
  void didUpdateWidget(covariant _MermaidChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.codeText != widget.codeText) {
      // Code is mutating (streaming). Drop any stale error UI and re-arm
      // the stabilizer; rendering will resume once tokens stop flowing.
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
      _scheduleStabilize();
    }
  }

  @override
  void dispose() {
    _stabilizer?.cancel();
    super.dispose();
  }

  /// Prepares a structured prompt asking the AI to repair the broken Mermaid
  /// code and pushes it into the active chat input via the ancestor state.
  void _askAiToFix() {
    final bridge = ChatPromptBridge.of(context);
    if (bridge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحديد محادثة نشطة لإرسال طلب التصحيح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final prompt =
        'المخطط Mermaid التالي لا يُعرض بسبب خطأ في الصياغة. أعد كتابته بصياغة صحيحة فقط داخل ```mermaid``` بدون أي شرح إضافي.\n\n'
        'الخطأ:\n```\n${_errorMessage ?? ''}\n```\n\n'
        'الكود الأصلي:\n```mermaid\n${widget.codeText}\n```';
    bridge.inject(prompt);
  }

  /// Bottom sheet offering PNG (raster, ready to share) or SVG (vector,
  /// scalable for print). Both are rendered locally — no network roundtrip.
  Future<void> _showExportSheet() async {
    HapticFeedback.lightImpact();
    final isDark = widget.isDark;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'تصدير المخطط',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(PhosphorIcons.image(PhosphorIconsStyle.fill),
                  color: const Color(0xFF10B981)),
              title: const Text('صورة PNG (للمشاركة السريعة)'),
              subtitle: const Text('دقة عالية × 3 — جاهزة للنشر',
                  style: TextStyle(fontSize: 11)),
              onTap: () => Navigator.pop(ctx, 'png'),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.fileSvg(),
                  color: const Color(0xFF6366F1)),
              title: const Text('ملف SVG (متجهي قابل للتكبير)'),
              subtitle: const Text('مناسب للطباعة بدقة لا متناهية',
                  style: TextStyle(fontSize: 11)),
              onTap: () => Navigator.pop(ctx, 'svg'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    // Show progress
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('جارٍ تجهيز الملف...'),
        ]),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      if (choice == 'png') {
        final bytes = await _mermaidCtl.getPng(scale: 3);
        if (bytes == null || bytes.isEmpty) {
          throw Exception('فشل تجهيز الصورة');
        }
        await Share.shareXFiles(
          [
            XFile.fromData(
              bytes,
              name: 'mermaid_$ts.png',
              mimeType: 'image/png',
            ),
          ],
          text: 'مخطط من خبير زاد',
        );
      } else if (choice == 'svg') {
        final svg = await _mermaidCtl.getSvg();
        if (svg == null || svg.isEmpty) {
          throw Exception('فشل تجهيز ملف SVG');
        }
        await Share.shareXFiles(
          [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(svg)),
              name: 'mermaid_$ts.svg',
              mimeType: 'image/svg+xml',
            ),
          ],
          text: 'مخطط من خبير زاد',
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر التصدير: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.black26 : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIcons.treeStructure(PhosphorIconsStyle.bold),
                      size: 16, color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    'مخطط ذكي',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const Spacer(),

                  // Toggle code view
                  _MermaidActionButton(
                    icon: _showCode
                        ? PhosphorIcons.image()
                        : PhosphorIcons.code(),
                    tooltip: _showCode ? 'عرض المخطط' : 'عرض الكود',
                    isDark: widget.isDark,
                    onTap: () => setState(() => _showCode = !_showCode),
                  ),
                  const SizedBox(width: 4),

                  // Copy code
                  _MermaidActionButton(
                    icon: PhosphorIcons.copy(),
                    tooltip: 'نسخ الكود',
                    isDark: widget.isDark,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.codeText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم نسخ كود المخطط'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),

                  // Local export — renders directly from the in-memory SVG
                  // via the ZadMermaidController (no third-party round-trip,
                  // no internet required).
                  if (!_hasError && !_showCode)
                    _MermaidActionButton(
                      icon: PhosphorIcons.export(),
                      tooltip: 'تصدير كصورة (PNG / SVG)',
                      isDark: widget.isDark,
                      onTap: _showExportSheet,
                    ),
                  const SizedBox(width: 4),

                  // Zoom out
                  if (!_hasError && !_showCode) ...[
                    _MermaidActionButton(
                      icon: PhosphorIcons.minusCircle(),
                      tooltip: 'تصغير',
                      isDark: widget.isDark,
                      onTap: () => _mermaidCtl.zoomOut(),
                    ),
                    const SizedBox(width: 4),
                    _MermaidActionButton(
                      icon: PhosphorIcons.plusCircle(),
                      tooltip: 'تكبير',
                      isDark: widget.isDark,
                      onTap: () => _mermaidCtl.zoomIn(),
                    ),
                    const SizedBox(width: 4),
                    _MermaidActionButton(
                      icon: PhosphorIcons.cornersIn(),
                      tooltip: 'توسيط',
                      isDark: widget.isDark,
                      onTap: () => _mermaidCtl.zoomReset(),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Fullscreen
                  if (!_hasError && !_showCode)
                    _MermaidActionButton(
                      icon: PhosphorIcons.arrowsOut(),
                      tooltip: 'ملء الشاشة',
                      isDark: widget.isDark,
                      onTap: () => _showFullScreen(context),
                    ),
                ],
              ),
            ),

            // ── Body ──
            if (_showCode)
              _buildCodeView()
            else if (_hasError)
              _buildErrorFallback()
            else if (_isStabilizing || _stableCode == null)
              _buildStreamingSkeleton()
            else
              Container(
                padding: const EdgeInsets.all(4),
                color: widget.isDark ? Colors.black12 : Colors.white,
                child: GestureDetector(
                  onTap: () => _showFullScreen(context),
                  behavior: HitTestBehavior.translucent,
                  child: ZadMermaidView(
                    // Keyed on the stable code so a fully-changed diagram
                    // gets a clean WebView rather than an in-place reload.
                    key: ValueKey(_stableCode),
                    code: _stableCode!,
                    isDark: widget.isDark,
                    controller: _mermaidCtl,
                    nonInteractive: true,
                    height: 280,
                    onError: _handleMermaidError,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Compact placeholder shown while the diagram code is still streaming
  /// in. We deliberately avoid touching Mermaid until the code stabilizes,
  /// so partial syntax can never trigger a false parse error.
  Widget _buildStreamingSkeleton() {
    final isDark = widget.isDark;
    return Container(
      height: 120,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'جاري تجهيز المخطط…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeView() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: widget.isDark
            ? const Color(0xFF282C34)
            : const Color(0xFFF8F8F8),
        child: SelectableText(
          widget.codeText,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: widget.isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorFallback() {
    final amber = Colors.amber.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Friendly Arabic banner — no raw stack traces.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: Colors.amber.withValues(alpha: 0.08),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                  size: 18, color: amber),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعذّر رسم المخطط',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: amber,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'يبدو أن صياغة الكود غير صالحة. يمكنك مراجعة الكود أدناه أو طلب المساعدة من الذكاء الاصطناعي لتصحيحه تلقائياً.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: widget.isDark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Action row
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.015),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _askAiToFix,
                  icon: Icon(PhosphorIcons.magicWand(PhosphorIconsStyle.fill),
                      size: 16),
                  label: const Text(
                    'اطلب من AI تصحيح المخطط',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      widget.isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.15),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () =>
                    setState(() => _showCode = !_showCode),
                icon: Icon(
                    _showCode
                        ? PhosphorIcons.eyeSlash()
                        : PhosphorIcons.code(),
                    size: 14),
                label: Text(
                  _showCode ? 'إخفاء الكود' : 'الكود',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Always show the offending code below so the user can review / copy.
        _buildCodeView(),
      ],
    );
  }

  void _showFullScreen(BuildContext context) {
    final fsCtl = ZadMermaidController();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, _, _) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 56, 8, 16),
                    child: ZadMermaidView(
                      code: _stableCode ?? widget.codeText,
                      isDark: true,
                      controller: fsCtl,
                      nonInteractive: false,
                      // Wide scale envelope for "absolute control": from 10%
                      // (whole-graph overview) to 1000% (read tiny labels).
                      minScale: 0.1,
                      maxScale: 10.0,
                      height: MediaQuery.of(context).size.height,
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _MermaidActionButton(
                    icon: PhosphorIcons.x(),
                    tooltip: 'إغلاق',
                    isDark: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                // Floating zoom controls (bottom)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MermaidActionButton(
                            icon: PhosphorIcons.minusCircle(),
                            tooltip: 'تصغير',
                            isDark: true,
                            onTap: () => fsCtl.zoomOut(),
                          ),
                          const SizedBox(width: 8),
                          _MermaidActionButton(
                            icon: PhosphorIcons.cornersIn(),
                            tooltip: 'احتواء (Fit)',
                            isDark: true,
                            onTap: () => fsCtl.zoomReset(),
                          ),
                          const SizedBox(width: 8),
                          // Live zoom percentage — listens directly to the
                          // shared TransformationController so it updates as
                          // the user pinches.
                          if (fsCtl.transformationController != null)
                            ValueListenableBuilder<Matrix4>(
                              valueListenable:
                                  fsCtl.transformationController!,
                              builder: (_, m, _) {
                                final pct =
                                    (m.getMaxScaleOnAxis() * 100).round();
                                return GestureDetector(
                                  onTap: () => fsCtl.zoomReset(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$pct%',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(width: 8),
                          _MermaidActionButton(
                            icon: PhosphorIcons.plusCircle(),
                            tooltip: 'تكبير',
                            isDark: true,
                            onTap: () => fsCtl.zoomIn(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        transitionsBuilder: (_, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }
}

class _MermaidActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _MermaidActionButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              size: 14, color: isDark ? Colors.white54 : Colors.black45),
        ),
      ),
    );
  }
}



class AiChatScreen extends ConsumerStatefulWidget {
  final WebsiteModel site;
  final bool isFromBrowser;
  final bool showHeader;

  const AiChatScreen({
    super.key, 
    required this.site,
    this.isFromBrowser = false,
    this.showHeader = true,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller      = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode        = FocusNode();

  // ── Voice input (STT) ────────────────────────────────────────────────
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isRecording    = false; // mic is capturing audio
  bool _speechInitialized = false;

  bool _isScanningMode = true;
  Timer? _scanningTimer;

  @override
  void initState() {
    super.initState();
    _scanningTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isScanningMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanningTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _speechToText.cancel(); // release mic resources
    super.dispose();
  }

  // ── Voice Input Handlers ─────────────────────────────────────────────

  Future<bool> _initSpeech() async {
    if (_speechInitialized && _speechToText.isAvailable) return true;
    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isRecording = false);
          }
        },
        onError: (err) {
          debugPrint('STT Error: ${err.errorMsg} permanent=${err.permanent}');
          if (mounted) {
            setState(() => _isRecording = false);
            if (err.permanent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تعذّر الوصول للميكروفون: ${err.errorMsg}'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      );
      _speechInitialized = available;
      if (!available && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('التعرف على الصوت غير متاح. تأكد من إذن الميكروفون.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return available;
    } catch (e) {
      debugPrint('STT init exception: $e');
      _speechInitialized = false;
      return false;
    }
  }

  /// Starts microphone recording.
  Future<void> _startVoiceInput() async {
    HapticFeedback.mediumImpact();
    final ready = await _initSpeech();
    if (!ready) return;

    final currentText = _controller.text.trim();
    final prefix = currentText.isEmpty ? '' : '$currentText ';

    try {
      if (mounted) setState(() => _isRecording = true);
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _controller.text = prefix + result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            if (result.finalResult) {
              _isRecording = false;
            }
          });
        },
        localeId: 'ar_SA',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('STT listen exception: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في بدء التسجيل: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Stops recording.
  Future<void> _stopVoiceInput() async {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();
    await _speechToText.stop();
    if (mounted) setState(() => _isRecording = false);
  }

  /// Injects [prompt] into the input field, focuses it, and scrolls it into
  /// view so the user can review/edit before sending. Used by the Mermaid
  /// "fix with AI" flow and (future) "ask about this quote" flow.
  void injectPromptAndFocus(String prompt) {
    HapticFeedback.lightImpact();
    setState(() {
      _controller.text = prompt;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    Future.microtask(() {
      if (!mounted) return;
      _focusNode.requestFocus();
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    
    final pageContent = widget.isFromBrowser 
        ? ref.read(extractedBrowserContentProvider)
        : null;
        
    ref.read(aiChatProvider(widget.site).notifier).sendMessage(text, pageContent);
    _controller.clear();
    _scrollToBottom();
  }

  /// Detects whether [text] is primarily Arabic ('ar') or English ('en').
  String _detectLanguage(String text) {
    final arabicPattern = RegExp(r'[\u0600-\u06FF]');
    return arabicPattern.hasMatch(text) ? 'ar' : 'en';
  }

  /// Generates contextual follow-up suggestion chips based on the AI response.
  List<String> _generateDynamicSuggestions(
    String lastAiContent,
    String lastUserMessage,
  ) {
    final lang = _detectLanguage(lastUserMessage);
    final lower = lastAiContent.toLowerCase();
    final hasCode = lastAiContent.contains('```');
    final mentionsInstall = lower.contains('install') ||
        lower.contains('npm ') ||
        lower.contains('pip ') ||
        lower.contains('brew ') ||
        lower.contains('apt ') ||
        lower.contains('\u062a\u062b\u0628\u064a\u062a') ||
        lower.contains('setup');
    final mentionsUsage = lower.contains('how to use') ||
        lower.contains('usage') ||
        lower.contains('run the') ||
        lower.contains('execute') ||
        lower.contains('\u0643\u064a\u0641 \u062a\u0633\u062a\u062e\u062f\u0645') ||
        lower.contains('\u0637\u0631\u064a\u0642\u0629 \u0627\u0644\u0627\u0633\u062a\u062e\u062f\u0627\u0645');
    final mentionsFeature = lower.contains('feature') ||
        lower.contains('support') ||
        lower.contains('capability') ||
        lower.contains('\u0645\u064a\u0632\u0629') ||
        lower.contains('\u064a\u062f\u0639\u0645');

    if (lang == 'ar') {
      if (mentionsInstall && !hasCode) {
        return ['\u0623\u0639\u0637\u0646\u064a \u0643\u0648\u062f \u0627\u0644\u062a\u062b\u0628\u064a\u062a', '\u0645\u0627 \u0627\u0644\u0645\u062a\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0623\u0633\u0627\u0633\u064a\u0629\u061f', '\u0643\u064a\u0641 \u0623\u062a\u062d\u0642\u0642 \u0645\u0645\u0646 \u0627\u0644\u062a\u062b\u0628\u064a\u062a\u061f'];
      } else if (hasCode) {
        return ['\u0627\u0634\u0631\u062d \u0627\u0644\u0643\u0648\u062f \u0628\u0634\u0643\u0644 \u0623\u0628\u0633\u0637', '\u0647\u0644 \u0647\u0646\u0627\u0643 \u0623\u062e\u0637\u0627\u0621 \u0634\u0627\u0626\u0639\u0629\u061f', '\u0643\u064a\u0641 \u0623\u062b\u0628\u0651\u062a \u0647\u0630\u0647 \u0627\u0644\u0623\u062f\u0627\u0629\u061f'];
      } else if (mentionsUsage) {
        return ['\u0623\u0639\u0637\u0646\u064a \u0645\u062b\u0627\u0644 \u0639\u0645\u0644\u064a', '\u0645\u0627 \u0623\u0647\u0645 \u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a\u061f', '\u0645\u0627 \u0627\u0644\u0623\u062e\u0637\u0627\u0621 \u0627\u0644\u0634\u0627\u0626\u0639\u0629\u061f'];
      } else if (mentionsFeature) {
        return ['\u0643\u064a\u0641 \u0623\u0633\u062a\u062e\u062f\u0645\u0647\u0627\u061f', '\u0643\u064a\u0641 \u0623\u062b\u0628\u0651\u062a\u0647\u0627\u061f', '\u0647\u0644 \u062a\u0648\u062c\u062f \u0646\u0633\u062e\u0629 \u0645\u062c\u0627\u0646\u064a\u0629\u061f'];
      }
      return ['\u0643\u064a\u0641 \u0623\u0633\u062a\u062e\u062f\u0645\u0647\u0627\u061f', '\u0623\u0639\u0637\u0646\u064a \u0645\u062b\u0627\u0644 \u0643\u0648\u062f', '\u0647\u0644 \u0647\u0646\u0627\u0643 \u0623\u062f\u0627\u0629 \u0628\u062f\u064a\u0644\u0629\u061f'];
    } else {
      if (mentionsInstall && !hasCode) {
        return ['Show me the install code', 'What are the prerequisites?', 'How to verify installation?'];
      } else if (hasCode) {
        return ['Explain the code further', 'What are common errors?', 'How do I install this?'];
      } else if (mentionsUsage) {
        return ['Give me a practical example', 'What are key settings?', 'What are common pitfalls?'];
      } else if (mentionsFeature) {
        return ['How do I use it?', 'How do I install it?', 'Is there a free plan?'];
      }
      return ['How do I use it?', 'Show me a code example', 'Is there an alternative?'];
    }
  }

  /// Builds the animated follow-up suggestion chips shown after each AI reply.
  Widget _buildDynamicChips(
    BuildContext context,
    bool isDark,
    List<String> suggestions,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          return _SuggestionChip(
            label: label,
            isDark: isDark,
            onTap: () => _sendMessage(label),
          )
              .animate()
              .fadeIn(delay: (i * 90).ms, duration: 220.ms)
              .slideY(begin: 0.15, end: 0, delay: (i * 90).ms, duration: 220.ms);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final chatState = ref.watch(aiChatProvider(widget.site));

    // Auto-scroll when new messages arrive
    ref.listen(aiChatProvider(widget.site), (
      AiChatState? prev,
      AiChatState next,
    ) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    // Show error snackbar
    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatState.error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.read(aiChatProvider(widget.site).notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      // Lets descendants (mermaid widgets, selection toolbars) push prompts
      // back into this screen's input without needing a private state ref.
      body: ChatPromptBridge(
        inject: injectPromptAndFocus,
        child: Column(
        children: [
          // ── Premium Header (Hidden in Bottom Sheet) ──
          if (widget.showHeader)
            _buildHeader(context, isDark, loc),
          // ── Chat Body ──
          Expanded(
            child: _isScanningMode
                ? _buildScanningView(context, isDark, loc)
                : (chatState.messages.isEmpty
                      ? _buildWelcomeView(context, isDark, loc)
                      : _buildChatList(context, isDark, chatState)),
          ),
          // ── Input Bar ──
          _buildInputBar(
            context,
            isDark,
            loc,
            chatState.isLoading || _isScanningMode,
            chatState.messages.isEmpty,
          ),
        ],
        ),
      ),
    );
  }

  // ── Header with item context ──
  Widget _buildHeader(BuildContext context, bool isDark, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkBg]
              : [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: back + title + clear
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back / Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Clear chat button
                  GestureDetector(
                    onTap: () =>
                        ref.read(aiChatProvider(widget.site).notifier).clearChat(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        PhosphorIcons.trash(),
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              // AI badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.aiAssistant,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Item context card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Item icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.globe(PhosphorIconsStyle.fill),
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.site.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.linkSimple(),
                            size: 10,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              loc.aiContextLoaded,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  // ── Scanning view ──
  Widget _buildScanningView(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
  ) {
    // Show "Fetching data from [URL]"
    final domain = widget.site.url.isNotEmpty
        ? Uri.tryParse(widget.site.url)?.host ?? widget.site.url
        : widget.site.title;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing search/globe icon
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                          PhosphorIcons.scan(),
                          size: 64,
                          color: AppTheme.accentColor,
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .slideY(begin: -0.3, end: 0.3, duration: 1000.ms)
                        .fadeIn(duration: 500.ms),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1000.ms,
              )
              .shimmer(duration: 1500.ms, color: Colors.white24),

          const SizedBox(height: 32),

          // Scanning text
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'جاري جلب البيانات من $domain...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 16),

          Text(
            loc.aiContextLoaded, // Usually translates to something suitable
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    ).animate().fadeOut(delay: 1700.ms, duration: 300.ms);
  }

  // ── Welcome view with suggested questions ──
  Widget _buildWelcomeView(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
  ) {
    final suggestions = widget.isFromBrowser 
      ? [
          "لخص هذه الصفحة",
          "اشرح الفكرة الرئيسية",
          "ما هي أهم النقاط؟",
          "هل يوجد روابط أو مصادر هامة؟"
        ]
      : [
          loc.aiSuggestWhat,
          loc.aiSuggestHow,
          loc.aiSuggestFeatures,
          loc.aiSuggestUse,
          loc.aiSuggestFit,
          loc.aiSuggestSimplify,
        ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // AI Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              PhosphorIcons.robot(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 36,
            ),
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 20),
          Text(
            loc.aiAssistant,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            loc.aiPoweredBy,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          // Suggested questions grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: suggestions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return _SuggestionChip(
                    label: q,
                    isDark: isDark,
                    onTap: () => _sendMessage(q),
                  )
                  .animate()
                  .fadeIn(delay: (400 + i * 80).ms)
                  .slideY(begin: 0.2, end: 0, delay: (400 + i * 80).ms);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Chat message list ──
  Widget _buildChatList(
    BuildContext context,
    bool isDark,
    AiChatState chatState,
  ) {
    final messages = chatState.messages;
    final lastIsAssistant = messages.isNotEmpty && !messages.last.isUser;
    final showDynamicChips = lastIsAssistant && !chatState.isLoading;
    final chipsIndex = messages.length;
    final typingIndex = messages.length + (showDynamicChips ? 1 : 0);
    final totalCount =
        messages.length + (showDynamicChips ? 1 : 0) + (chatState.isLoading ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: totalCount,
      itemBuilder: (ctx, i) {
        // Regular message bubbles
        if (i < messages.length) {
          return _buildMessageBubble(context, messages[i], isDark, i);
        }
        // Dynamic follow-up chips after last AI reply
        if (showDynamicChips && i == chipsIndex) {
          final lastAiMsg = messages.last;
          final lastUserMsg = messages.lastWhere(
            (m) => m.isUser,
            orElse: () => lastAiMsg,
          );
          final suggestions = _generateDynamicSuggestions(
            lastAiMsg.content,
            lastUserMsg.content,
          );
          return _buildDynamicChips(context, isDark, suggestions);
        }
        // Typing indicator while loading
        if (chatState.isLoading && i == typingIndex) {
          return _buildTypingIndicator(isDark);
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Single message bubble ──
  Widget _buildMessageBubble(
    BuildContext context,
    AiChatMessage msg,
    bool isDark,
    int index,
  ) {
    final isUser = msg.isUser;
    if (isUser) {
      final chatState = ref.read(aiChatProvider(widget.site));
      final messages = chatState.messages;
      // Locate the most recent user-authored message so the edit affordance
      // surfaces there even after one or more assistant replies follow it.
      // Suppressed while streaming to avoid corrupting an in-flight reply.
      int lastUserIndex = -1;
      for (int i = messages.length - 1; i >= 0; i--) {
        if (messages[i].isUser) {
          lastUserIndex = i;
          break;
        }
      }
      final isLastUser = !chatState.isLoading &&
          lastUserIndex != -1 &&
          index == lastUserIndex;
      return _AiUserBubble(
        msg: msg,
        isDark: isDark,
        isLast: isLastUser,
        onEdit: isLastUser
            ? (newText) {
                HapticFeedback.mediumImpact();
                final pageContent = widget.isFromBrowser
                    ? ref.read(extractedBrowserContentProvider)
                    : null;
                ref
                    .read(aiChatProvider(widget.site).notifier)
                    .editAndResendLast(newText, pageContent);
                _scrollToBottom();
              }
            : null,
      );
    }
    return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.darkSurface : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isUser
                ? Text(
                    msg.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selection toolbar adds an "اسأل عن هذا" item that
                      // injects the highlighted passage as a markdown quote
                      // into the input bar for a precise follow-up question.
                      SelectionArea(
                        contextMenuBuilder: (ctx, sel) {
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            anchors: sel.contextMenuAnchors,
                            buttonItems: [
                              ContextMenuButtonItem(
                                label: 'نسخ',
                                onPressed: () {
                                  // ignore: deprecated_member_use
                                  sel.copySelection(
                                      SelectionChangedCause.toolbar);
                                },
                              ),
                              ContextMenuButtonItem(
                                label: 'اسأل عن هذا',
                                onPressed: () async {
                                  // ignore: deprecated_member_use
                                  sel.copySelection(
                                      SelectionChangedCause.toolbar);
                                  sel.hideToolbar();
                                  final cd = await Clipboard.getData(
                                      Clipboard.kTextPlain);
                                  final text = cd?.text ?? '';
                                  if (text.isEmpty || !mounted) return;
                                  final quoted = text
                                      .split('\n')
                                      .map((l) => '> $l')
                                      .join('\n');
                                  injectPromptAndFocus('$quoted\n\n');
                                },
                              ),
                            ],
                          );
                        },
                        child: _TypewriterMarkdown(
                          content: msg.content,
                          isDark: isDark,
                          animate: index ==
                              ref
                                      .read(aiChatProvider(widget.site))
                                      .messages
                                      .length -
                                  1,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
              ),
              if (!isUser) // Action buttons for AI messages
                Padding(
                  padding: const EdgeInsets.only(bottom: 14, right: 8, left: 8, top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'نسخ',
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('تم النسخ', style: TextStyle()),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppTheme.primaryColor,
                                duration: const Duration(seconds: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(PhosphorIcons.copy(), size: 14, color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'مشاركة',
                        child: GestureDetector(
                          onTap: () => Share.share(msg.content),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(PhosphorIcons.shareNetwork(), size: 14, color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else 
                const SizedBox(height: 14),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideX(begin: isUser ? 0.1 : -0.1, end: 0, duration: 250.ms);
  }

  // ── Typing indicator ──
  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0, isDark),
            const SizedBox(width: 5),
            _buildDot(1, isDark),
            const SizedBox(width: 5),
            _buildDot(2, isDark),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildDot(int index, bool isDark) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          delay: (index * 200).ms,
        )
        .fadeIn(begin: 0.3, duration: 600.ms, delay: (index * 200).ms);
  }

  // ── Input Bar ──
  Widget _buildInputBar(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
    bool isLoading,
    bool isChatEmpty,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The generic quick prompts above input bar have been removed to save space
          // and prevent duplication with the welcome screen suggestions.
          Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: loc.aiTypeMessage,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black26,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Microphone button (Voice Input / STT) ───────────────────
          GestureDetector(
            onTap: isLoading
                ? null
                : (_isRecording ? _stopVoiceInput : _startVoiceInput),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.shade500
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isRecording
                      ? Colors.red.shade400
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08)),
                ),
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _isRecording
                    ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                    : PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                color: _isRecording
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black45),
                size: 20,
              ),
            )
            .animate(target: _isRecording ? 1.0 : 0.0)
            .scaleXY(begin: 1.0, end: 1.08, duration: 600.ms, curve: Curves.easeInOut)
            .then()
            .scaleXY(begin: 1.08, end: 1.0, duration: 600.ms, curve: Curves.easeInOut),
          ),

          const SizedBox(width: 8),

          // ── Send button ─────────────────────────────────────────────
          GestureDetector(
            onTap: isLoading ? null : () => _sendMessage(_controller.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isLoading
                    ? (isDark ? Colors.white10 : Colors.black12)
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                color: isLoading ? Colors.grey : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      ],
      ),
    );
  }
  // _buildQuickPrompts was removed in favor of unified context-aware welcome view
}

// ── Typewriter Markdown Widget ──
class _TypewriterMarkdown extends StatefulWidget {
  final String content;
  final bool isDark;
  final bool animate;

  const _TypewriterMarkdown({
    required this.content,
    required this.isDark,
    this.animate = false,
  });

  @override
  State<_TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<_TypewriterMarkdown> {
  String _displayedText = '';
  Timer? _timer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.content.isNotEmpty) {
      _startTypewriter();
    } else {
      _displayedText = widget.content;
      _isComplete = true;
    }
  }

  @override
  void didUpdateWidget(covariant _TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      if (widget.animate && !_isComplete) {
        _startTypewriter();
      } else {
        _displayedText = widget.content;
        _isComplete = true;
      }
    }
  }

  void _startTypewriter() {
    _timer?.cancel();
    _displayedText = '';
    _isComplete = false;
    int charIndex = 0;
    final totalChars = widget.content.length;
    // Speed: ~1ms per char for ultra fast feeling
    _timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Add multiple characters per tick for longer texts
      final charsPerTick = totalChars > 500 ? 10 : (totalChars > 200 ? 5 : 3);
      charIndex += charsPerTick;
      if (charIndex >= totalChars) {
        charIndex = totalChars;
        timer.cancel();
        _isComplete = true;
      }
      setState(() {
        _displayedText = widget.content.substring(0, charIndex);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayedText,
      // SelectionArea wrapper at the bubble level handles selection so the
      // custom "اسأل عن هذا" toolbar item works. Keeping selectable:false
      // here avoids conflicting per-Text SelectableTexts.
      selectable: false,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
      builders: {'code': CodeElementBuilder(widget.isDark, context)},
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          height: 1.6,
          
        ),
        h1: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          
        ),
        h2: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          
        ),
        h3: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          
        ),
        strong: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          
        ),
        code: TextStyle(
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF282C34)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTheme.primaryColor,
              width: 3,
            ),
          ),
        ),
        listBullet: TextStyle(
          color: widget.isDark ? Colors.white70 : Colors.black54,
        ),
        a: TextStyle(
          color: AppTheme.primaryColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

/// Copy-entire-reply button shown at the bottom of AI responses
class _CopyReplyButton extends StatefulWidget {
  final String text;
  final bool isDark;
  const _CopyReplyButton({required this.text, required this.isDark});

  @override
  State<_CopyReplyButton> createState() => _CopyReplyButtonState();
}

class _CopyReplyButtonState extends State<_CopyReplyButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _copied
              ? Row(
                  key: const ValueKey('copied'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تم النسخ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade400,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('copy'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: widget.isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'نسخ',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Reusable animated suggestion chip with press effect + haptic
// ══════════════════════════════════════════════════════════════════
class _SuggestionChip extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _pressed
                ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.13)
                    : AppTheme.primaryColor.withValues(alpha: 0.09))
                : (widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? AppTheme.primaryColor.withValues(alpha: 0.45)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                size: 12,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
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

// ══════════════════════════════════════════════════════════════════
// User message bubble with inline edit & resend
// ══════════════════════════════════════════════════════════════════
class _AiUserBubble extends StatefulWidget {
  final AiChatMessage msg;
  final bool isDark;
  final bool isLast;
  final ValueChanged<String>? onEdit;

  const _AiUserBubble({
    required this.msg,
    required this.isDark,
    required this.isLast,
    this.onEdit,
  });

  @override
  State<_AiUserBubble> createState() => _AiUserBubbleState();
}

class _AiUserBubbleState extends State<_AiUserBubble> {
  bool _editing = false;
  TextEditingController? _editController;

  void _startEditing() {
    HapticFeedback.lightImpact();
    setState(() {
      _editController = TextEditingController(text: widget.msg.content);
      _editing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _editController?.dispose();
      _editController = null;
    });
  }

  void _submitEdit() {
    final newText = _editController?.text.trim() ?? '';
    if (newText.isEmpty) return;
    if (newText == widget.msg.content.trim()) {
      _cancelEditing();
      return;
    }
    final cb = widget.onEdit;
    setState(() {
      _editing = false;
      _editController?.dispose();
      _editController = null;
    });
    cb?.call(newText);
  }

  @override
  void dispose() {
    _editController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _editing
                ? _buildEditField()
                : Text(
                    widget.msg.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
          ),
          if (widget.isLast && widget.onEdit != null && !_editing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'تعديل وإعادة إرسال',
                    child: GestureDetector(
                      onTap: _startEditing,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(PhosphorIcons.pencilSimple(),
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!_editing)
            const SizedBox(height: 6),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.1, end: 0, duration: 250.ms);
  }

  Widget _buildEditField() {
    final controller = _editController!;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _DismissIntent(),
      },
      child: Actions(
        actions: {
          _DismissIntent: CallbackAction<_DismissIntent>(
            onInvoke: (_) {
              _cancelEditing();
              return null;
            },
          ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: small label so the user knows the bubble is now in
            // edit mode, not just a styled message.
            Row(
              children: [
                Icon(
                  PhosphorIcons.pencilSimpleLine(PhosphorIconsStyle.fill),
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  'تعديل الرسالة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            EditTextField(
              controller: controller,
              accent: AppTheme.primaryColor,
              hint: 'عدّل رسالتك ثم اضغط إعادة الإرسال…',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'سيتم استبدال الرد السابق وإعادة توليده',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _EditActionButton(
                  label: 'إلغاء',
                  icon: PhosphorIcons.x(),
                  onTap: _cancelEditing,
                  isPrimary: false,
                  primaryColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                _EditActionButton(
                  label: 'إعادة الإرسال',
                  icon: PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                  onTap: _submitEdit,
                  isPrimary: true,
                  primaryColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).scaleXY(begin: 0.97, end: 1, duration: 180.ms);
  }
}

/// Intent fired by the Esc key inside an edit field to abandon the edit.
class _DismissIntent extends Intent {
  const _DismissIntent();
}

/// Inset edit field used inside chat bubbles. We pin it to a fixed light
/// `Theme` so the surrounding app brightness never bleeds into the field's
/// background or text colors — the field always reads as a clean white
/// paper input regardless of dark mode.
class EditTextField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final String hint;

  const EditTextField({
    super.key,
    required this.controller,
    required this.accent,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: accent,
          selectionColor: accent.withValues(alpha: 0.25),
          selectionHandleColor: accent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            minLines: 1,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: accent,
            cursorWidth: 2,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact pill button used inside edit-mode bubbles. The primary variant
/// fills with the bubble's contrast color; the ghost variant uses a soft
/// translucent surface — together they form a clear hierarchy.
class _EditActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color primaryColor;

  const _EditActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.15);
    final fg = isPrimary ? primaryColor : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
