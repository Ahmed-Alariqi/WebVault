import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Lightweight controller exposed to parents so they can drive zoom and
/// retrieve the rendered diagram (SVG/PNG) from the outside.
///
/// Since v2 the zoom logic lives at the **Flutter** layer (via
/// [InteractiveViewer] inside [ZadMermaidView]) — the WebView simply renders
/// the static SVG once and stays idle. This eliminates the 100% CPU loop we
/// previously saw with svg-pan-zoom and gives us GPU-accelerated pinch/pan
/// for free.
class ZadMermaidController {
  Future<void> Function()? _zoomIn;
  Future<void> Function()? _zoomOut;
  Future<void> Function()? _zoomReset;
  Future<String?> Function()? _getSvg;
  Future<Uint8List?> Function({double scale})? _getPng;

  /// Live transform matrix. Exposed so external UIs (e.g. the fullscreen
  /// scaffold) can react to the current zoom — typically by showing a
  /// percentage badge or driving custom indicators. `null` until the inner
  /// `ZadMermaidView` mounts.
  TransformationController? transformationController;

  void _attach({
    required Future<void> Function() zoomIn,
    required Future<void> Function() zoomOut,
    required Future<void> Function() zoomReset,
    required Future<String?> Function() getSvg,
    required Future<Uint8List?> Function({double scale}) getPng,
    required TransformationController transform,
  }) {
    _zoomIn = zoomIn;
    _zoomOut = zoomOut;
    _zoomReset = zoomReset;
    _getSvg = getSvg;
    _getPng = getPng;
    transformationController = transform;
  }

  Future<void> zoomIn() async => _zoomIn?.call();
  Future<void> zoomOut() async => _zoomOut?.call();
  Future<void> zoomReset() async => _zoomReset?.call();

  /// Returns the rendered `<svg>` outerHTML, or null if not ready / errored.
  Future<String?> getSvg() async => (await _getSvg?.call());

  /// Returns the rendered diagram as PNG bytes at [scale]× the SVG's natural
  /// size. Use 2× or 3× for high-DPI export.
  Future<Uint8List?> getPng({double scale = 2}) async =>
      (await _getPng?.call(scale: scale));
}

class ZadMermaidView extends StatefulWidget {
  final String code;
  final bool isDark;

  /// When true, the diagram renders in **inline** mode:
  ///  - The WebView is wrapped in an [InteractiveViewer] that handles pinch /
  ///    pan natively at the Flutter layer (no CPU drain inside the WebView).
  ///  - Single-finger drag passes through to the parent ListView when the
  ///    diagram is at base scale; once zoomed-in, drag pans the diagram.
  ///  - The +/− buttons in the parent header drive the same Flutter-side
  ///    transform, so all zoom paths share state and focal point.
  ///
  /// When false (fullscreen), the surrounding parent already provides its own
  /// [InteractiveViewer], so we just render the SVG flat.
  final bool nonInteractive;

  /// External controller used to trigger zoom and export from outside.
  final ZadMermaidController? controller;

  /// Render height. Defaults to a compact size that does not dominate the
  /// chat reply.
  final double height;

  /// Called once when Mermaid finishes rendering successfully.
  final VoidCallback? onReady;

  /// Called when Mermaid fails to parse or render the code. Receives the
  /// raw error message.
  final void Function(String error)? onError;

  /// Minimum / maximum zoom factor. Inline previews keep a moderate range
  /// (0.5 – 5×); fullscreen mode opens it wide (0.2 – 10×) for "absolute
  /// control" over very large diagrams.
  final double minScale;
  final double maxScale;

  const ZadMermaidView({
    super.key,
    required this.code,
    required this.isDark,
    this.nonInteractive = true,
    this.controller,
    this.height = 300,
    this.onReady,
    this.onError,
    this.minScale = 0.5,
    this.maxScale = 5.0,
  });

  @override
  State<ZadMermaidView> createState() => _ZadMermaidViewState();
}

class _ZadMermaidViewState extends State<ZadMermaidView> {
  late final WebViewController _webController;
  bool _isLoading = true;
  bool _ready = false;

  /// Drives the [InteractiveViewer] on the Flutter side.
  final TransformationController _transformCtl = TransformationController();

  /// Whether a single-finger pan should pan the diagram. We only enable it
  /// once the user has zoomed in past base scale, otherwise the gesture is
  /// passed through to the parent ListView for normal scrolling.
  bool _panEnabled = false;

  /// Debounces WebView reloads while the parent feeds us streaming code.
  /// Without this, every token would trigger a full page reload.
  Timer? _reloadDebounce;

  /// Pending export round-trips. JS can't return a `Promise` synchronously
  /// to `runJavaScriptReturningResult` (it stringifies as `[object Promise]`
  /// on Android), so we pass a [int] request id, JS posts the resolved
  /// value back through `MermaidBridge`, and we complete the matching
  /// future here.
  int _nextExportId = 1;
  final Map<int, Completer<String>> _pendingExports = {};

  /// Builds the full HTML page for the current `widget.code`. Extracted into
  /// its own method so [didUpdateWidget] can re-render the diagram in place
  /// when the code mutates (e.g. while the chat reply is still streaming).
  String _buildHtml() {
    final String themeName = widget.isDark ? 'dark' : 'default';
    final String primaryColor = widget.isDark ? '#10B981' : '#059669';
    final String textColor = widget.isDark ? '#F9FAFB' : '#111827';
    final String bgColor = widget.isDark ? '#1E293B' : '#FFFFFF';

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <script type="module">
          import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

          function notify(payload) {
            try {
              if (window.MermaidBridge && typeof window.MermaidBridge.postMessage === 'function') {
                window.MermaidBridge.postMessage(JSON.stringify(payload));
              }
            } catch (_) {}
          }

          mermaid.initialize({
            startOnLoad: false,
            theme: '$themeName',
            securityLevel: 'loose',
            fontFamily: 'system-ui, -apple-system, sans-serif',
            themeVariables: {
              'primaryColor': '$primaryColor',
              'primaryTextColor': '$textColor',
              'primaryBorderColor': '$primaryColor',
              'lineColor': '$primaryColor',
              'secondaryColor': '$bgColor',
              'tertiaryColor': '$bgColor'
            }
          });

          // Use mermaid.render() — the most stable v10 API. It takes the raw
          // code string and returns { svg }, which we inject ourselves. This
          // avoids the selector quirks of mermaid.run() that were causing
          // false "render error" reports for perfectly valid diagrams.
          const container = document.getElementById('mermaid-container');
          const rawCode = (container.textContent || '').trim();
          container.textContent = '';
          mermaid.render('mmd-' + Date.now(), rawCode).then(result => {
            container.innerHTML = result.svg;
            const svgElement = container.querySelector('svg');
            if (svgElement) {
              svgElement.removeAttribute('width');
              svgElement.removeAttribute('height');
              svgElement.style.width = '100%';
              svgElement.style.height = '100%';
              svgElement.style.maxWidth = '100%';
              svgElement.style.maxHeight = '100%';
            }
            notify({ type: 'ready' });
          }).catch((err) => {
            const msg = (err && err.message) ? err.message : String(err);
            notify({ type: 'error', message: msg });
          });

          // ── Export helpers ──
          // Both helpers post their result back through `MermaidBridge` so
          // Dart can await the value reliably. Returning Promises directly
          // from `runJavaScriptReturningResult` does not work on Android
          // (it stringifies the Promise object instead of awaiting it).
          window.requestSvgExport = function(reqId) {
            try {
              const svg = document.querySelector('#mermaid-container svg');
              if (!svg) {
                notify({ type: 'export', kind: 'svg', id: reqId, value: '' });
                return;
              }
              const xml = new XMLSerializer().serializeToString(svg.cloneNode(true));
              const value = '<?xml version="1.0" encoding="UTF-8"?>\\n' + xml;
              notify({ type: 'export', kind: 'svg', id: reqId, value: value });
            } catch (e) {
              notify({ type: 'export', kind: 'svg', id: reqId, value: '', error: String(e) });
            }
          };

          window.requestPngExport = function(reqId, scale) {
            try {
              const svg = document.querySelector('#mermaid-container svg');
              if (!svg) {
                notify({ type: 'export', kind: 'png', id: reqId, value: '' });
                return;
              }
              const xml = new XMLSerializer().serializeToString(svg);
              const svg64 = btoa(unescape(encodeURIComponent(xml)));
              const image64 = 'data:image/svg+xml;base64,' + svg64;
              const bbox = svg.getBoundingClientRect();
              const w = Math.max(64, Math.floor(bbox.width * (scale || 2)));
              const h = Math.max(64, Math.floor(bbox.height * (scale || 2)));
              const canvas = document.createElement('canvas');
              canvas.width = w; canvas.height = h;
              const ctx = canvas.getContext('2d');
              ctx.fillStyle = '$bgColor';
              ctx.fillRect(0, 0, w, h);
              const img = new Image();
              img.onload = () => {
                try {
                  ctx.drawImage(img, 0, 0, w, h);
                  const dataUrl = canvas.toDataURL('image/png');
                  notify({ type: 'export', kind: 'png', id: reqId, value: dataUrl });
                } catch (drawErr) {
                  notify({ type: 'export', kind: 'png', id: reqId, value: '', error: String(drawErr) });
                }
              };
              img.onerror = (e) => {
                notify({ type: 'export', kind: 'png', id: reqId, value: '', error: 'image load failed' });
              };
              img.src = image64;
            } catch (e) {
              notify({ type: 'export', kind: 'png', id: reqId, value: '', error: String(e) });
            }
          };
        </script>
        <style>
          body, html {
            margin: 0;
            padding: 0;
            background: $bgColor;
            width: 100%;
            height: 100%;
            overflow: hidden !important;
          }
          #mermaid-container {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          #mermaid-container > svg {
            max-width: 100%;
            max-height: 100%;
          }
        </style>
      </head>
      <body>
        <div id="mermaid-container">
          ${widget.code}
        </div>
      </body>
      </html>
    ''';
  }

  @override
  void initState() {
    super.initState();
    _transformCtl.addListener(_onTransformChanged);

    final String htmlContent = _buildHtml();

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
          widget.isDark ? const Color(0xFF1E293B) : Colors.white)
      ..addJavaScriptChannel(
        'MermaidBridge',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    widget.controller?._attach(
      zoomIn: _zoomIn,
      zoomOut: _zoomOut,
      zoomReset: _zoomReset,
      getSvg: _getSvg,
      getPng: _getPng,
      transform: _transformCtl,
    );
  }

  @override
  void didUpdateWidget(covariant ZadMermaidView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The diagram code mutates in-place while the chat reply is streaming.
    // Without this hook the WebView keeps showing the very first partial
    // chunk forever (which usually fails to parse and triggers a false
    // "fix with AI" error). We reload the page with the latest code, but
    // debounce by 350ms so we don't thrash on every token.
    final codeChanged = oldWidget.code != widget.code;
    final themeChanged = oldWidget.isDark != widget.isDark;
    if (codeChanged || themeChanged) {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _isLoading = true;
          _ready = false;
        });
        _webController.loadHtmlString(_buildHtml());
      });
    }
  }

  // ───── Bridge from JS → Dart ─────
  void _handleBridgeMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'ready') {
        if (mounted) setState(() => _ready = true);
        widget.onReady?.call();
      } else if (type == 'error') {
        widget.onError?.call((data['message'] as String?) ?? 'Mermaid error');
      } else if (type == 'export') {
        // Resolve the matching pending exporter future. We deliberately
        // never throw here — empty string ⇒ caller treats as failure.
        final id = (data['id'] as num?)?.toInt();
        final value = (data['value'] as String?) ?? '';
        if (id != null) {
          final pending = _pendingExports.remove(id);
          if (pending != null && !pending.isCompleted) {
            pending.complete(value);
          }
        }
      }
    } catch (_) {/* best-effort */}
  }

  // ───── Flutter-side zoom (drives InteractiveViewer's matrix) ─────
  void _onTransformChanged() {
    final scale = _transformCtl.value.getMaxScaleOnAxis();
    final shouldPan = scale > 1.05;
    if (shouldPan != _panEnabled && mounted) {
      setState(() => _panEnabled = shouldPan);
    }
  }

  void _setScale(double newScale, {Offset? focal}) {
    final clamped = newScale.clamp(widget.minScale, widget.maxScale);
    // Compute matrix with focal point in widget coordinates.
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? Size(widget.height, widget.height);
    final f = focal ?? Offset(size.width / 2, size.height / 2);
    final m = Matrix4.identity()
      ..translate(f.dx, f.dy)
      ..scale(clamped)
      ..translate(-f.dx, -f.dy);
    _transformCtl.value = m;
  }

  Future<void> _zoomIn() async {
    final current = _transformCtl.value.getMaxScaleOnAxis();
    _setScale(current * 1.25);
  }

  Future<void> _zoomOut() async {
    final current = _transformCtl.value.getMaxScaleOnAxis();
    _setScale(current * 0.8);
  }

  Future<void> _zoomReset() async {
    _transformCtl.value = Matrix4.identity();
  }

  // ───── Export helpers (bridge round-trip) ─────

  /// Issues a fresh request id, registers a [Completer], and triggers the
  /// matching JS exporter. The completer resolves once JS posts the value
  /// back through `MermaidBridge`. Times out gracefully so the UI never
  /// hangs on a wedged WebView.
  Future<String> _exportViaBridge(String jsCallTemplate) async {
    final id = _nextExportId++;
    final completer = Completer<String>();
    _pendingExports[id] = completer;
    try {
      // Caller passes a JS template containing `$id` to substitute.
      await _webController.runJavaScript(jsCallTemplate.replaceAll(r'$id', '$id'));
    } catch (e) {
      _pendingExports.remove(id);
      return '';
    }
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingExports.remove(id);
        return '';
      },
    );
  }

  Future<String?> _getSvg() async {
    if (!_ready) return null;
    final value = await _exportViaBridge(r'window.requestSvgExport($id);');
    return value.isEmpty ? null : value;
  }

  Future<Uint8List?> _getPng({double scale = 2}) async {
    if (!_ready) return null;
    final value = await _exportViaBridge(
      'window.requestPngExport(\$id, $scale);',
    );
    const prefix = 'data:image/png;base64,';
    if (!value.startsWith(prefix)) return null;
    try {
      return base64Decode(value.substring(prefix.length));
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    for (final c in _pendingExports.values) {
      if (!c.isCompleted) c.complete('');
    }
    _pendingExports.clear();
    _transformCtl.removeListener(_onTransformChanged);
    _transformCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final webView = WebViewWidget(controller: _webController);

    // The WebView itself never receives gestures — they're consumed by the
    // surrounding InteractiveViewer (or absorbed in fullscreen by the parent).
    final isolatedWebView = IgnorePointer(ignoring: true, child: webView);

    // Both inline and fullscreen modes wrap the WebView in an
    // InteractiveViewer — the difference is the scale envelope and pan
    // behaviour. In fullscreen we open the range wide and let pan run free
    // so the user has absolute control over the diagram.
    final body = InteractiveViewer(
      transformationController: _transformCtl,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      scaleEnabled: true,
      panEnabled: widget.nonInteractive ? _panEnabled : true,
      boundaryMargin: widget.nonInteractive
          ? EdgeInsets.zero
          : const EdgeInsets.all(double.infinity),
      clipBehavior: Clip.hardEdge,
      child: isolatedWebView,
    );

    return Container(
      height: widget.height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            body,
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
