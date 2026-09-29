import 'package:flutter/material.dart';

/// Original garment silhouettes, drawn on a transparent canvas.
class GarmentIllustration extends StatelessWidget {
  final int kind;
  const GarmentIllustration({super.key, required this.kind});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GarmentPainter(kind, Theme.of(context).colorScheme.primary),
    child: const SizedBox.expand(),
  );
}

class _GarmentPainter extends CustomPainter {
  final int kind;
  final Color accent;
  _GarmentPainter(this.kind, this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2 - size.height * .5, 0);
    canvas.scale(size.height / 100);
    final path = Path();
    switch (kind) {
      case 0:
        path.moveTo(34, 18);
        path.lineTo(20, 24);
        path.lineTo(10, 43);
        path.lineTo(25, 50);
        path.lineTo(30, 40);
        path.lineTo(30, 84);
        path.lineTo(70, 84);
        path.lineTo(70, 40);
        path.lineTo(75, 50);
        path.lineTo(90, 43);
        path.lineTo(80, 24);
        path.lineTo(66, 18);
        path.quadraticBezierTo(50, 35, 34, 18);
        path.close();
      case 1:
        path.moveTo(30, 14);
        path.lineTo(70, 14);
        path.lineTo(76, 87);
        path.lineTo(55, 87);
        path.lineTo(50, 44);
        path.lineTo(45, 87);
        path.lineTo(24, 87);
        path.close();
      case 2:
        path.moveTo(17, 47);
        path.lineTo(34, 42);
        path.lineTo(50, 57);
        path.lineTo(78, 64);
        path.quadraticBezierTo(90, 66, 88, 80);
        path.lineTo(13, 80);
        path.lineTo(13, 62);
        path.close();
      default:
        path.moveTo(36, 16);
        path.lineTo(20, 26);
        path.lineTo(11, 79);
        path.lineTo(25, 82);
        path.lineTo(32, 42);
        path.lineTo(29, 86);
        path.lineTo(71, 86);
        path.lineTo(68, 42);
        path.lineTo(75, 82);
        path.lineTo(89, 79);
        path.lineTo(80, 26);
        path.lineTo(64, 16);
        path.lineTo(50, 25);
        path.close();
    }
    canvas.drawShadow(path, Colors.black, 7, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: .55),
            const Color(0xFF283448),
            const Color(0xFF111923),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final seam = Paint()
      ..color = accent.withValues(alpha: .45)
      ..strokeWidth = .8;
    if (kind == 1) {
      canvas.drawLine(const Offset(31, 23), const Offset(69, 23), seam);
    }
    if (kind == 2) {
      canvas.drawLine(const Offset(15, 74), const Offset(87, 74), seam);
    }
    if (kind == 3) {
      canvas.drawLine(const Offset(50, 25), const Offset(50, 85), seam);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GarmentPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.accent != accent;
}
