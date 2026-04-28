import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/plantuml_encoder.dart';

/// Mobile counterpart of [ZadPlantUmlView]. PlantUML rendering is
/// server-side, so the mobile widget can simply use [Image.network] —
/// no WebView required, which keeps mobile lightweight and fast.
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
  final TransformationController _transformCtl = TransformationController();
  bool _panEnabled = false;

  /// Mobile uses PNG (rather than SVG) because Flutter's [Image.network]
  /// doesn't decode SVG natively. PlantUML's server returns 1× DPI PNGs
  /// which look fine after Flutter scales them inside InteractiveViewer.
  String get _imageUrl => plantUmlPngUrl(widget.code, server: widget.server);

  @override
  void initState() {
    super.initState();
    _transformCtl.addListener(_onTransformChanged);
    widget.controller?._attach(
      zoomIn: _zoomIn,
      zoomOut: _zoomOut,
      zoomReset: _zoomReset,
      getSvg: _getSvg,
      getPng: _getPng,
      transform: _transformCtl,
    );
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

  Future<String?> _getSvg() async {
    final url = plantUmlSvgUrl(widget.code, server: widget.server);
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? res.body : null;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _getPng({double scale = 2}) async {
    try {
      final res = await http
          .get(Uri.parse(_imageUrl))
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _transformCtl.removeListener(_onTransformChanged);
    _transformCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      _imageUrl,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) {
          // Notify ready on first successful frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onReady?.call();
          });
          return child;
        }
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        );
      },
      errorBuilder: (ctx, err, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onError?.call(err.toString());
        });
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'تعذّر تحميل المخطط من خادم PlantUML',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isDark ? Colors.white70 : Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );

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
      child: image,
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
