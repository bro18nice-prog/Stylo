import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../models/clothing_item.dart';
import '../../services/garment_storage.dart';
import 'hanger_rail_physics.dart';

/// Garderoba pe umerașe: hainele tale reale atârnă pe o bară și se
/// derulează stânga-dreapta cu inerție. Umerașele se leagănă, iar piesa din
/// centru se răsucește când o atingi.
class HangerRail extends StatefulWidget {
  const HangerRail({
    super.key,
    required this.items,
    this.onIndexChanged,
    this.onOpen,
  });

  final List<ClothingItem> items;

  /// Se apelează când se schimbă piesa din centru.
  final ValueChanged<int>? onIndexChanged;

  /// Apăsare lungă pe piesa din centru.
  final ValueChanged<int>? onOpen;

  @override
  State<HangerRail> createState() => _HangerRailState();
}

class _ImageSub {
  _ImageSub(this.stream, this.listener);
  final ImageStream stream;
  final ImageStreamListener listener;
}

class _HangerRailState extends State<HangerRail>
    with SingleTickerProviderStateMixin {
  final RailPhysics _physics = RailPhysics();
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  final Map<String, ui.Image> _images = <String, ui.Image>{};
  final Map<String, _ImageSub> _subs = <String, _ImageSub>{};

  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  Duration? _lastDragStamp;
  int _reported = -1;
  double _flip = -1;
  int _flipIndex = -1;
  double _width = 390;

  @override
  void initState() {
    super.initState();
    _configure(keepScroll: false);
    _loadImages();
    _wake();
  }

  @override
  void didUpdateWidget(HangerRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.items.length != widget.items.length ||
        !_sameItems(oldWidget.items, widget.items);
    if (changed) {
      final sameLength = oldWidget.items.length == widget.items.length;
      _configure(keepScroll: sameLength);
      _loadImages();
      _reported = -1;
      _wake();
    }
  }

  bool _sameItems(List<ClothingItem> a, List<ClothingItem> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].imagePath != b[i].imagePath) return false;
    }
    return true;
  }

  void _configure({required bool keepScroll}) {
    _physics.configure(
      widget.items.map((item) => _style(item.category).pendulum).toList(),
      keepScroll: keepScroll,
    );
    _flip = -1;
  }

  void _loadImages() {
    for (final item in widget.items) {
      final key = item.imagePath;
      if (_subs.containsKey(key)) continue;
      final stream = garmentImage(key).resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener((info, _) {
        _images[key]?.dispose();
        _images[key] = info.image.clone();
        _repaint.value++;
      }, onError: (_, _) {});
      stream.addListener(listener);
      _subs[key] = _ImageSub(stream, listener);
    }
  }

  void _wake() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final raw = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    var dt = raw.clamp(0.0, 1 / 30).toDouble();
    final frame = dt;
    while (dt > 1e-6) {
      final h = math.min(dt, 1 / 120);
      _physics.step(h);
      dt -= h;
    }
    if (_flip >= 0) {
      _flip += frame / 1.15;
      if (_flip >= 1) _flip = -1;
    }
    final index = _physics.index;
    if (index != _reported && widget.items.isNotEmpty) {
      final dragging = _physics.dragging && _reported != -1;
      _reported = index;
      if (dragging) HapticFeedback.selectionClick();
      widget.onIndexChanged?.call(index);
    }
    _repaint.value++;
    if (_physics.settled && _flip < 0) {
      _ticker.stop();
      _lastTick = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    for (final sub in _subs.values) {
      sub.stream.removeListener(sub.listener);
    }
    for (final image in _images.values) {
      image.dispose();
    }
    _repaint.dispose();
    super.dispose();
  }

  void _tap(double x) {
    if (widget.items.isEmpty) return;
    final d = (x - _width / 2) / _physics.spacing;
    if (d.abs() < .52) {
      _flip = 0;
      _flipIndex = _physics.index;
      HapticFeedback.lightImpact();
    } else {
      _physics.glideTo((_physics.scroll + d).round());
    }
    _wake();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Garderoba pe umerașe. Glisează stânga sau dreapta pentru a '
          'răsfoi hainele, atinge piesa din centru pentru a o răsuci.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              _physics.beginDrag();
              _lastDragStamp = details.sourceTimeStamp;
              _wake();
            },
            onHorizontalDragUpdate: (details) {
              final stamp = details.sourceTimeStamp;
              var dt = 1 / 60;
              if (stamp != null && _lastDragStamp != null) {
                final measured = (stamp - _lastDragStamp!).inMicroseconds / 1e6;
                if (measured > 0) dt = measured;
              }
              _lastDragStamp = stamp;
              _physics.dragBy(details.delta.dx, dt);
            },
            onHorizontalDragEnd: (details) {
              _physics.endDrag(details.velocity.pixelsPerSecond.dx);
              _wake();
            },
            onHorizontalDragCancel: () {
              _physics.endDrag(0);
              _wake();
            },
            onTapUp: (details) => _tap(details.localPosition.dx),
            onLongPress: () {
              if (widget.items.isEmpty) return;
              HapticFeedback.mediumImpact();
              widget.onOpen?.call(_physics.index);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _RailPainter(
                physics: _physics,
                items: widget.items,
                images: _images,
                flip: _flip,
                flipIndex: _flipIndex,
                repaint: _repaint,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Cum atârnă o categorie de haine.
enum _Hang { top, trousers, cord }

class _Style {
  const _Style(this.hang, this.maxW, this.maxH, this.pendulum);
  final _Hang hang;
  final double maxW;
  final double maxH;
  final double pendulum;
}

_Style _style(String category) {
  switch (category) {
    case 'Pantaloni':
      return const _Style(_Hang.trousers, 150, 285, 270);
    case 'Pantofi':
      return const _Style(_Hang.cord, 150, 120, 140);
    case 'Accesorii':
      return const _Style(_Hang.cord, 130, 170, 160);
    case 'Geacă':
      return const _Style(_Hang.top, 215, 300, 250);
    default:
      return const _Style(_Hang.top, 200, 270, 210);
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.physics,
    required this.items,
    required this.images,
    required this.flip,
    required this.flipIndex,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final RailPhysics physics;
  final List<ClothingItem> items;
  final Map<String, ui.Image> images;
  final double flip;
  final int flipIndex;

  static const double railY = 54;
  static const double baseScale = 1.12;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintWall(canvas, size);
    _paintRail(canvas, size);

    final order = <int>[];
    for (var i = 0; i < items.length; i++) {
      if ((i - physics.scroll).abs() < 3.2) order.add(i);
    }
    order.sort(
      (a, b) =>
          (b - physics.scroll).abs().compareTo((a - physics.scroll).abs()),
    );

    for (final i in order) {
      final d = i - physics.scroll;
      final ad = d.abs();
      final double scale = (baseScale * math.max(.62, 1 - .15 * ad)).toDouble();
      final double x =
          size.width / 2 +
          d * physics.spacing * (1 - .08 * math.min(ad, 2.0)).toDouble();
      final double shade = (1 - math.min(.6, ad * .24)).toDouble();
      final angle = i < physics.angle.length ? physics.angle[i] : 0.0;

      canvas.save();
      canvas.translate(x, railY);
      canvas.scale(scale);
      canvas.rotate(angle);
      var back = false;
      if (flip >= 0 && flipIndex == i) {
        final e = flip < .5
            ? 4 * flip * flip * flip
            : 1 - math.pow(-2 * flip + 2, 3) / 2;
        final cs = math.cos(e * math.pi * 2);
        back = cs < 0;
        canvas.scale(cs.abs() < .05 ? .05 : cs, 1);
      }
      _paintItem(canvas, items[i], shade, back);
      canvas.restore();
    }

    final vignette = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        const [
          Color(0x80000000),
          Color(0x00000000),
          Color(0x00000000),
          Color(0x80000000),
        ],
        const [0, .18, .82, 1],
      );
    canvas.drawRect(Offset.zero & size, vignette);
    canvas.restore();
  }

  void _paintWall(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          const [Color(0xFF1B1A20), Color(0xFF09090C)],
        ),
    );
    final line = Paint()
      ..color = const Color(0x08FFFFFF)
      ..strokeWidth = 1;
    final offset = -((physics.scroll * physics.spacing * .25) % 78);
    for (var x = offset; x < size.width + 78; x += 78) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, 190),
          380,
          const [Color(0x42FFE8C8), Color(0x00FFE8C8)],
        ),
    );
  }

  void _paintRail(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, railY + 5, size.width, 17),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, railY + 5),
          Offset(0, railY + 22),
          const [Color(0x80000000), Color(0x00000000)],
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, railY - 5, size.width, 10),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, railY - 5),
          Offset(0, railY + 5),
          const [
            Color(0xFF5A5E68),
            Color(0xFFF1F3F8),
            Color(0xFF8A8E98),
            Color(0xFF2C2E36),
          ],
          const [0, .25, .6, 1],
        ),
    );
    final bracket = Paint()..color = const Color(0xFF1F2027);
    canvas.drawRect(Rect.fromLTWH(0, railY - 12, 12, 26), bracket);
    canvas.drawRect(Rect.fromLTWH(size.width - 12, railY - 12, 12, 26), bracket);
  }

  Color _dim(Color color, double shade) =>
      Color.lerp(const Color(0xFF09090C), color, shade) ?? color;

  Paint _wood(Rect rect, double shade) => Paint()
    ..shader = ui.Gradient.linear(
      rect.topLeft,
      rect.topRight,
      [
        _dim(const Color(0xFFB9854F), shade),
        _dim(const Color(0xFFE6B97E), shade),
        _dim(const Color(0xFF7A5230), shade),
      ],
      const [0, .5, 1],
    );

  void _hook(Canvas canvas, double shade) {
    final path = Path()
      ..moveTo(0, 12)
      ..lineTo(0, 2)
      ..cubicTo(0, -11, 11, -11, 10, -3);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          const Offset(-4, 0),
          const Offset(10, 0),
          [
            _dim(const Color(0xFF8E929C), shade),
            _dim(const Color(0xFFF4F6FA), shade),
            _dim(const Color(0xFF5A5E68), shade),
          ],
          const [0, .5, 1],
        ),
    );
  }

  void _paintItem(Canvas canvas, ClothingItem item, double shade, bool back) {
    final style = _style(item.category);
    final image = images[item.imagePath];
    _hook(canvas, shade);

    // Dimensiuni imagine, păstrând proporțiile.
    var w = style.maxW;
    var h = style.maxH;
    if (image != null) {
      final k = math.min(
        style.maxW / image.width,
        style.maxH / image.height,
      );
      w = image.width * k;
      h = image.height * k;
    }

    double top;
    switch (style.hang) {
      case _Hang.top:
        {
        top = 40;
        final stem = Rect.fromLTWH(-3.5, 6, 7, 34);
        canvas.drawRRect(
          RRect.fromRectAndRadius(stem, const Radius.circular(2)),
          _wood(stem, shade),
        );
        final bar = Path()
          ..moveTo(-w * .36, 56)
          ..quadraticBezierTo(0, 28, w * .36, 56);
        canvas.drawPath(
          bar,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..color = _dim(const Color(0xFFC89560), shade),
        );
        }
        break;
      case _Hang.trousers:
        {
        top = 60;
        final stem = Rect.fromLTWH(-3.5, 6, 7, 30);
        canvas.drawRRect(
          RRect.fromRectAndRadius(stem, const Radius.circular(2)),
          _wood(stem, shade),
        );
        final bar = Path()
          ..moveTo(-66, 42)
          ..quadraticBezierTo(0, 31, 66, 42)
          ..lineTo(66, 49)
          ..quadraticBezierTo(0, 39, -66, 49)
          ..close();
        canvas.drawPath(bar, _wood(const Rect.fromLTWH(-66, 31, 132, 18), shade));
        }
        break;
      case _Hang.cord:
        {
        top = 58;
        canvas.drawLine(
          const Offset(0, 8),
          Offset(0, top + 4),
          Paint()
            ..strokeWidth = 2
            ..color = _dim(const Color(0xFF8E929C), shade),
        );
        }
        break;
    }

    final dst = Rect.fromLTWH(-w / 2, top, w, h);

    if (image == null) {
      // Până se încarcă poza: un contur discret.
      canvas.drawRRect(
        RRect.fromRectAndRadius(dst, const Radius.circular(14)),
        Paint()..color = _dim(const Color(0xFF2A2B33), shade),
      );
    } else {
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      // Umbra aruncată pe peretele din spate.
      canvas.drawImageRect(
        image,
        src,
        dst.shift(const Offset(14, 12)),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = const ColorFilter.mode(
            Color(0x8C000000),
            BlendMode.srcIn,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
      );
      final b = shade * (back ? .62 : 1.0);
      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.high
          ..colorFilter = ColorFilter.matrix(<double>[
            b, 0, 0, 0, 0, //
            0, b, 0, 0, 0, //
            0, 0, b, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
      );
    }

    if (style.hang == _Hang.trousers) {
      // Clemele metalice peste talia pantalonilor.
      for (final cx in const [-26.0, 26.0]) {
        final clip = Rect.fromLTWH(cx - 5, 38, 10, 28);
        canvas.drawRRect(
          RRect.fromRectAndRadius(clip, const Radius.circular(2)),
          Paint()
            ..shader = ui.Gradient.linear(
              clip.topLeft,
              clip.topRight,
              [
                _dim(const Color(0xFF8E929C), shade),
                _dim(const Color(0xFFF4F6FA), shade),
                _dim(const Color(0xFF5A5E68), shade),
              ],
              const [0, .5, 1],
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) => true;
}
