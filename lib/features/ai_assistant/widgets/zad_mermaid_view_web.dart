import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web parity of the mobile [ZadMermaidController].
///
/// Zoom and export are routed to the iframe via `postMessage`; the iframe
/// listens and posts results back through the same channel. This keeps the
/// public API identical on both platforms.
class ZadMermaidController {
  html.IFrameElement? _iframe;
  // Pending one-shot futures for postMessage round-trips.
  final Map<int, Completer<dynamic>> _pending = {};
  int _nextId = 1;
  StreamSubscription? _sub;

  // Flutter-side zoom hooks installed by the State on attach.
  Future<void> Function()? _zoomIn;
  Future<void> Function()? _zoomOut;
  Future<void> Function()? _zoomReset;

  /// See mobile counterpart — exposed for live percent indicators, etc.
  TransformationController? transformationController;

  void _attach({
    required html.IFrameElement iframe,
    required Future<void> Function() zoomIn,
    required Future<void> Function() zoomOut,
    required Future<void> Function() zoomReset,
    required TransformationController transform,
  }) {
    _iframe = iframe;
    _zoomIn = zoomIn;
    _zoomOut = zoomOut;
    _zoomReset = zoomReset;
    transformationController = transform;
    _sub ??= html.window.onMessage.listen((ev) {
      try {
        final data = ev.data;
        if (data is! Map) return;
        if (data['type'] == 'zad-mermaid-result') {
          final id = data['id'] as int?;
          if (id != null && _pending.containsKey(id)) {
            _pending.remove(id)!.complete(data['value']);
          }
        }
      } catch (_) {}
    });
  }

  void _post(Map<String, Object?> payload) {
    final w = _iframe?.contentWindow;
    if (w != null) w.postMessage(payload, '*');
  }

  Future<dynamic> _request(String action, [Map<String, Object?>? args]) {
    final id = _nextId++;
    final c = Completer<dynamic>();
    _pending[id] = c;
    _post({
      'type': 'zad-mermaid',
      'action': action,
      'id': id,
      if (args != null) ...args,
    });
    return c.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  Future<void> zoomIn() async => _zoomIn?.call();
  Future<void> zoomOut() async => _zoomOut?.call();
  Future<void> zoomReset() async => _zoomReset?.call();

  Future<String?> getSvg() async {
    final res = await _request('getSvg');
    return res is String && res.isNotEmpty ? res : null;
  }

  Future<Uint8List?> getPng({double scale = 2}) async {
    final res = await _request('getPng', {'scale': scale});
    if (res is! String) return null;
    const prefix = 'data:image/png;base64,';
    if (!res.startsWith(prefix)) return null;
    return base64Decode(res.substring(prefix.length));
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _pending.clear();
    _iframe = null;
  }
}

class ZadMermaidView extends StatefulWidget {
  final String code;
  final bool isDark;
  final bool nonInteractive;
  final ZadMermaidController? controller;
  final double height;
  final VoidCallback? onReady;
  final void Function(String error)? onError;

  /// Minimum / maximum zoom factor (see mobile variant for rationale).
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
  late String _viewId;
  StreamSubscription? _eventSub;

  // Flutter-side InteractiveViewer state, mirrors mobile.
  final TransformationController _transformCtl = TransformationController();
  bool _panEnabled = false;

  /// Held locally so [didUpdateWidget] can swap `srcdoc` in place when the
  /// diagram code mutates during streaming.
  html.IFrameElement? _iframe;
  Timer? _reloadDebounce;

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
        <script type="module">
          import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

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

          function notifyParent(msg) {
            try { parent.postMessage(msg, '*'); } catch (_) {}
          }

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
            notifyParent({ type: 'zad-mermaid-event', event: 'ready' });
          }).catch((err) => {
            const m = (err && err.message) ? err.message : String(err);
            notifyParent({ type: 'zad-mermaid-event', event: 'error', message: m });
          });

          function exportSvg() {
            const svg = document.querySelector('#mermaid-container svg');
            if (!svg) return '';
            const xml = new XMLSerializer().serializeToString(svg);
            return '<?xml version="1.0" encoding="UTF-8"?>\\n' + xml;
          }

          function exportPng(scale) {
            return new Promise((resolve) => {
              const svg = document.querySelector('#mermaid-container svg');
              if (!svg) { resolve(''); return; }
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
                ctx.drawImage(img, 0, 0, w, h);
                resolve(canvas.toDataURL('image/png'));
              };
              img.onerror = () => resolve('');
              img.src = image64;
            });
          }

          window.addEventListener('message', async (ev) => {
            const data = ev.data || {};
            if (data && data.type === 'zad-mermaid') {
              const id = data.id;
              if (data.action === 'getSvg') {
                parent.postMessage({ type: 'zad-mermaid-result', id, value: exportSvg() }, '*');
              } else if (data.action === 'getPng') {
                const dataUrl = await exportPng(data.scale || 2);
                parent.postMessage({ type: 'zad-mermaid-result', id, value: dataUrl }, '*');
              }
              // zoomIn/zoomOut/zoomReset are intentionally ignored on web;
              // Flutter's InteractiveViewer drives zoom now.
            }
          });
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
          #mermaid-container { width: 100%; height: 100%; display:flex; align-items:center; justify-content:center; }
          #mermaid-container > svg { max-width: 100%; max-height: 100%; }
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
    // viewId is stable across the State's lifetime; reloads happen by
    // mutating the iframe's srcdoc instead of re-registering.
    _viewId =
        'mermaid-view-${identityHashCode(this)}-${widget.nonInteractive ? 'ni' : 'i'}';

    _transformCtl.addListener(_onTransformChanged);

    // Listen for ready/error events from the iframe.
    _eventSub = html.window.onMessage.listen((ev) {
      try {
        final data = ev.data;
        if (data is! Map) return;
        if (data['type'] == 'zad-mermaid-event') {
          final event = data['event'];
          if (event == 'ready') {
            widget.onReady?.call();
          } else if (event == 'error') {
            widget.onError?.call(
                (data['message'] as String?) ?? 'Mermaid error');
          }
        }
      } catch (_) {}
    });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = _buildHtml();
      _iframe = iframe;
      widget.controller?._attach(
        iframe: iframe,
        zoomIn: _zoomIn,
        zoomOut: _zoomOut,
        zoomReset: _zoomReset,
        transform: _transformCtl,
      );
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant ZadMermaidView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mirror of mobile: refresh srcdoc when the diagram code mutates during
    // streaming so we never get stuck on a partial / failed first paint.
    final codeChanged = oldWidget.code != widget.code;
    final themeChanged = oldWidget.isDark != widget.isDark;
    if (codeChanged || themeChanged) {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _iframe?.srcdoc = _buildHtml();
      });
    }
  }

  void _onTransformChanged() {
    final scale = _transformCtl.value.getMaxScaleOnAxis();
    final shouldPan = scale > 1.05;
    if (shouldPan != _panEnabled && mounted) {
      setState(() => _panEnabled = shouldPan);
    }
  }

  // ───── Flutter-side zoom (drives the InteractiveViewer matrix) ─────
  void _setScale(double newScale) {
    final clamped = newScale.clamp(widget.minScale, widget.maxScale);
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? Size(widget.height, widget.height);
    final f = Offset(size.width / 2, size.height / 2);
    final m = Matrix4.identity()
      ..translate(f.dx, f.dy)
      ..scale(clamped)
      ..translate(-f.dx, -f.dy);
    _transformCtl.value = m;
  }

  Future<void> _zoomIn() async =>
      _setScale(_transformCtl.value.getMaxScaleOnAxis() * 1.25);
  Future<void> _zoomOut() async =>
      _setScale(_transformCtl.value.getMaxScaleOnAxis() * 0.8);
  Future<void> _zoomReset() async =>
      _transformCtl.value = Matrix4.identity();

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _eventSub?.cancel();
    _transformCtl.removeListener(_onTransformChanged);
    _transformCtl.dispose();
    widget.controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = HtmlElementView(viewType: _viewId);
    // The HtmlElementView always intercepts pointer events on web, so we wrap
    // it in IgnorePointer + InteractiveViewer for Flutter-side gestures.
    final isolated = IgnorePointer(ignoring: true, child: view);

    // Always wrap in an InteractiveViewer (inline + fullscreen). In
    // fullscreen we widen the scale envelope and let pan run freely so the
    // user has absolute control over the diagram.
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
      child: isolated,
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
        child: body,
      ),
    );
  }
}
