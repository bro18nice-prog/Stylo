import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../services/anchor_fit_service.dart';
import '../../services/garment_storage.dart';

class WarpedGarment extends StatefulWidget {
  final String path;
  final AnchorFit fit;
  const WarpedGarment({super.key, required this.path, required this.fit});
  @override
  State<WarpedGarment> createState() => _WarpedGarmentState();
}

class _WarpedGarmentState extends State<WarpedGarment> {
  ui.Image? _image;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WarpedGarment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _image?.dispose();
      _image = null;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final bytes = await readGarment(widget.path);
      final codec = await ui.instantiateImageCodec(bytes);
      late ui.Image image;
      try {
        image = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (!mounted || request != _request) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      /* An unavailable photo must not break the fitting room. */
    }
  }

  @override
  void dispose() {
    _request++;
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _image == null
      ? const SizedBox.shrink()
      : CustomPaint(painter: _GarmentPainter(_image!, widget.fit));
}

class _GarmentPainter extends CustomPainter {
  final ui.Image image;
  final AnchorFit fit;
  _GarmentPainter(this.image, this.fit);
  @override
  void paint(Canvas canvas, Size size) {
    if (!fit.valid) return;
    final warp = fit.warp;
    // Include each control coordinate so the displayed mesh hits every anchor.
    final xs = <double>{
      for (var i = 0; i <= 24; i++) i / 24,
      ...fit.source.map((p) => p.dx),
    }.toList()..sort();
    final ys = <double>{
      for (var i = 0; i <= 24; i++) i / 24,
      ...fit.source.map((p) => p.dy),
    }.toList()..sort();
    final positions = <Offset>[], texture = <Offset>[];
    for (final y in ys) {
      for (final x in xs) {
        final p = warp.map(Offset(x, y));
        positions.add(Offset(p.dx * size.width, p.dy * size.height));
        texture.add(Offset(x * image.width, y * image.height));
      }
    }
    final indices = <int>[];
    for (var y = 0; y < ys.length - 1; y++) {
      for (var x = 0; x < xs.length - 1; x++) {
        final a = y * xs.length + x, b = a + 1, c = a + xs.length, d = c + 1;
        indices.addAll([a, b, c, b, d, c]);
      }
    }
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texture,
      indices: indices,
    );
    final shader = ui.ImageShader(
      image,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      Matrix4.identity().storage,
    );
    canvas.drawVertices(
      vertices,
      BlendMode.srcOver,
      Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.medium,
    );
    vertices.dispose();
    shader.dispose();
  }

  @override
  bool shouldRepaint(_GarmentPainter old) =>
      old.image != image || old.fit != fit;
}
