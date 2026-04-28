import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/plantuml_encoder.dart';

/// External controller exposing the same surface as `ZadMermaidController`
/// so existing UI code (zoom buttons, export menu, fullscreen) can drive
/// PlantUML diagrams uniformly.
///
/// Unlike Mermaid (rendered in-browser by JS), PlantUML is rendered on
/// the server — so getSvg/getPng simply re-fetch the configured URL.
class ZadPlantUmlController {
  Future<void> Function()? _zoomIn;
  Future<void> Function()? _zoomOut;
  Future<void> Function()? _zoomReset;
  Future<String?> Function()? _getSvg;
  Future<Uint8List?> Function({double scale})? _getPng;

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
  Future<String?> getSvg() async => _getSvg?.call();
  Future<Uint8List?> getPng({double scale = 2}) async =>
      _getPng?.call(scale: scale);
}

/// Renders a PlantUML diagram by encoding the source, requesting the SVG
/// from the configured PlantUML server, and embedding the result inside a
/// minimal HTML iframe styled to match the chat theme.
///
/// We deliberately use an `<img>` tag (with `crossorigin="anonymous"`)
/// instead of inlining the SVG, because the public plantuml.com server
/// returns CORS headers for resource-style requests but not always for
/// XHR. This keeps zero-config rendering working out of the box.
class ZadPlantUmlView extends StatefulWidget {
  final String code;
  final bool isDark;
  final bool nonInteractive;
  final ZadPlantUmlController? controller;
  final double height;
  final VoidCallback? onReady;
  final void Function(String error)? onError;
  final double minScale;
  final double maxScale;

  /// Override the default PlantUML server (e.g. point to a self-hosted
  /// instance or to Kroki). Defaults to the public plantuml.com server.
  final String server;

  const ZadPlantUmlView({
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
    this.server = kPlantUmlServer,
  });

  @override
  State<ZadPlantUmlView> createState() => _ZadPlantUmlViewState();
}

class _ZadPlantUmlViewState extends State<ZadPlantUmlView> {
  late String _viewId;
  final TransformationController _transformCtl = TransformationController();
  bool _panEnabled = false;
  html.IFrameElement? _iframe;
  Timer? _reloadDebounce;

  /// Cached SVG URL for the current code — recomputed in [_buildHtml].
  String _currentUrl = '';

  String _buildHtml() {
    final url = plantUmlSvgUrl(widget.code, server: widget.server);
    _currentUrl = url;
    final bg = widget.isDark ? '#1E293B' : '#FFFFFF';
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body, html {
            margin: 0; padding: 0; background: $bg;
            width: 100%; height: 100%;
            overflow: hidden !important;
          }
          #wrap {
            width: 100%; height: 100%;
            display: flex; align-items: center; justify-content: center;
          }
          #wrap > img {
            max-width: 100%; max-height: 100%;
            user-select: none; -webkit-user-drag: none;
          }
          #err {
            display: none;
            color: #EF4444; font-family: system-ui, sans-serif;
            font-size: 13px; text-align: center; padding: 16px;
          }
        </style>
      </head>
      <body>
        <div id="wrap">
          <img id="diagram" src="$url" alt="PlantUML diagram"
               onload="parent.postMessage({type:'zad-plantuml-event',event:'ready'},'*')"
               onerror="document.getElementById('err').style.display='block';
                        document.getElementById('diagram').style.display='none';
                        parent.postMessage({type:'zad-plantuml-event',event:'error',message:'Failed to load PlantUML SVG'},'*')">
          <div id="err">تعذّر تحميل المخطط من خادم PlantUML.</div>
        </div>
      </body>
      </html>
    ''';
  }

  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _viewId =
        'plantuml-view-${identityHashCode(this)}-${widget.nonInteractive ? 'ni' : 'i'}';
    _transformCtl.addListener(_onTransformChanged);

    _eventSub = html.window.onMessage.listen((ev) {
      try {
        final data = ev.data;
        if (data is! Map) return;
        if (data['type'] == 'zad-plantuml-event') {
          final event = data['event'];
          if (event == 'ready') {
            widget.onReady?.call();
          } else if (event == 'error') {
            widget.onError?.call(
                (data['message'] as String?) ?? 'PlantUML error');
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
        zoomIn: _zoomIn,
        zoomOut: _zoomOut,
        zoomReset: _zoomReset,
        getSvg: _getSvg,
        getPng: _getPng,
        transform: _transformCtl,
      );
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant ZadPlantUmlView oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  /// Re-fetches the current diagram as raw SVG text. Used by the export menu.
  Future<String?> _getSvg() async {
    if (_currentUrl.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse(_currentUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return utf8.decode(res.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the diagram as PNG bytes via the server's `/png/` endpoint.
  /// `scale` is ignored — PlantUML's server picks the best resolution.
  Future<Uint8List?> _getPng({double scale = 2}) async {
    final url = plantUmlPngUrl(widget.code, server: widget.server);
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _eventSub?.cancel();
    _transformCtl.removeListener(_onTransformChanged);
    _transformCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = HtmlElementView(viewType: _viewId);
    final isolated = IgnorePointer(ignoring: true, child: view);

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
