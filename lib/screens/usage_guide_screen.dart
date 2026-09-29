import 'package:flutter/material.dart';

class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ghid utilizare')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Fotografii bune. Potriviri mai simple.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Fotografiile și potrivirile se păstrează pe acest dispozitiv. Previzualizarea este 2D: arată poziția pieselor, nu măsoară mărimea reală sau felul în care cade materialul.',
        ),
        _section(
          context,
          0,
          '1. Pregătește fotografia',
          'Întinde o singură haină pe un fundal simplu, mat, în contrast cu ea: închis pentru haine deschise, deschis pentru haine închise. Îndreaptă umerii, mânecile și tivul; nu suprapune pantalonii.\n\nȚine camera paralelă cu haina, direct deasupra ei, nu în diagonală. Include toate marginile și lasă aproximativ 5–10% spațiu în jur. Folosește lumină difuză, fără umbre puternice. Fotografia trebuie să fie clară, ideal de cel puțin 1.000 px pe latura scurtă. Evită hainele purtate, colajele, capturile cu texte și fotografiile tăiate.',
        ),
        _section(
          context,
          1,
          '2. Verifică decuparea',
          'În „Adaugă o piesă”, alege fotografia, numele și categoria. Compară decupajul cu originalul: mânecile, tivul, curelele și marginile subțiri trebuie să rămână întregi.\n\n„Păstrează” reține mai multe detalii; „Curăță” elimină mai mult fundal. Apasă „Reaplică decuparea” după schimbarea reglajului. Dacă rezultatul este slab, alege „Folosește originalul” sau o fotografie mai clară. Fundalul original va rămâne vizibil și în cabină.',
        ),
        _section(
          context,
          2,
          '3. Marchează și salvează ancorele',
          'În cabină, selectează piesa și apasă „1. Ancore pe fotografie”. Pentru tricou sau geacă: 1 la umărul din stânga imaginii, 2 la cel din dreapta, 3 la mijlocul tivului. Pentru pantaloni: 1 și 2 la capetele taliei, 3 jos, la mijloc între terminațiile picioarelor.\n\nPentru papuci, genți și inele: 1 sus-stânga, 2 sus-dreapta, 3 jos, la mijloc. Punctele 4 și 5 controlează separat marginea de jos, în stânga și în dreapta. Primele trei puncte formează un triunghi, nu o linie. Alege numărul și atinge fotografia sau trage cercul.\n\n„Aplică pe manechin” aliniază automat cele cinci repere. Apoi „2. Ajustează pe corp” permite corecțiile: selectează ancora și atinge corpul sau folosește săgețile. „Salvează potrivirea” ascunde ancorele și păstrează reglajele pentru aceeași piesă, pe acest manechin. O fotografie adăugată din nou ca piesă nouă are propria potrivire.',
        ),
        _section(
          context,
          3,
          '4. Papucul 1 și Papucul 2',
          'Fotografiază fiecare papuc singur, de sus, cu vârful spre partea de jos a imaginii. Păstrează întreaga talpă în cadru; nu folosi o fotografie laterală sau cu perechea lipită.\n\nAdaugă prima fotografie la „Pantofi”, loc „Papucul 1”; aceasta apare în stânga imaginii. Adaugă a doua separat, loc „Papucul 2”; apare în dreapta. În cabină, butoanele cu aceste nume selectează piesa deja montată sau deschid adăugarea dacă locul este gol. Alege apoi piesa din lista de jos și salvează potrivirea fiecăreia.\n\nFotografiile vechi cu ambii papuci nu sunt despărțite automat: adaugă două fotografii individuale.',
        ),
        _section(
          context,
          4,
          '5. Genți și inele',
          'Alege categoria „Accesorii”, apoi tipul „Geantă” sau „Inel”. Poți purta o geantă și un inel împreună cu hainele și cei doi papuci.\n\nGeantă: fotografie frontală, mânere și curele întregi, fără mâini care acoperă produsul. Inel: un singur inel, clar și apropiat, fotografiat din direcția în care vrei să apară; fundalul să fie vizibil și în centru.\n\nAșază accesoriul cu ancorele; pentru inel, selectează numărul ancorei și folosește săgețile pentru deplasări mici. Previzualizarea suprapune accesoriul peste corp; nu îl înfășoară în jurul degetului și nu trece automat curelele în spatele mâinii.',
        ),
      ],
    ),
  );
  Widget _section(BuildContext context, int kind, String title, String text) =>
      Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Semantics(
              image: true,
              label: [
                'Haină întinsă, completă în cadru; cameră paralelă deasupra',
                'Tricou pe fundal contrastant și decupaj pe caroiaj',
                'Trei ancore: umeri stânga și dreapta, apoi mijlocul tivului',
                'Două fotografii separate, câte un papuc în fiecare',
                'Geantă frontală cu mâner complet și inel separat',
              ][kind],
              child: AspectRatio(
                aspectRatio: 1.5,
                child: CustomPaint(
                  painter: GuideIllustration(
                    kind,
                    Theme.of(context).colorScheme,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}

/// Vector diagrams remain sharp on small screens and follow the app theme.
class GuideIllustration extends CustomPainter {
  final int kind;
  final ColorScheme colors;
  final String? fontFamily;
  GuideIllustration(this.kind, this.colors, {this.fontFamily});
  void _label(
    Canvas c,
    String text,
    Offset p, {
    double size = 12,
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          color: color ?? colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 285);
    painter.paint(c, p);
  }

  Path _shirt(double x, double y, double scale) {
    final pts = [
      Offset(.28, .05),
      Offset(.40, .10),
      Offset(.60, .10),
      Offset(.72, .05),
      Offset(1, .25),
      Offset(.85, .43),
      Offset(.73, .35),
      Offset(.73, 1),
      Offset(.27, 1),
      Offset(.27, .35),
      Offset(.15, .43),
      Offset(0, .25),
    ];
    return Path()..addPolygon(
      pts.map((p) => Offset(x + p.dx * scale, y + p.dy * scale)).toList(),
      true,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 200);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 300, 200),
        const Radius.circular(18),
      ),
      Paint()..color = colors.surfaceContainerHighest,
    );
    final fill = Paint()..color = colors.primary;
    final line = Paint()
      ..color = colors.onSurfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (kind == 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(16, 24, 154, 156),
          const Radius.circular(8),
        ),
        line,
      );
      canvas.drawPath(_shirt(35, 38, 118), fill);
      _label(canvas, '5–10% spațiu', const Offset(24, 178), size: 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(208, 35, 60, 38),
          const Radius.circular(8),
        ),
        line,
      );
      canvas.drawCircle(const Offset(238, 54), 10, line);
      canvas.drawLine(const Offset(238, 82), const Offset(238, 130), line);
      canvas.drawLine(const Offset(230, 120), const Offset(238, 130), line);
      canvas.drawLine(const Offset(246, 120), const Offset(238, 130), line);
      canvas.drawLine(const Offset(195, 142), const Offset(281, 142), line);
      _label(canvas, 'De sus', const Offset(214, 150));
      _label(canvas, 'Complet în cadru', const Offset(25, 7), size: 11);
    } else if (kind == 1) {
      for (var y = 30; y < 165; y += 12) {
        for (var x = 165; x < 285; x += 12) {
          if ((x + y) % 24 == 3) {
            canvas.drawRect(
              Rect.fromLTWH(x.toDouble(), y.toDouble(), 12, 12),
              Paint()..color = colors.outlineVariant,
            );
          }
        }
      }
      canvas.drawPath(_shirt(20, 38, 105), fill);
      canvas.drawPath(_shirt(172, 38, 105), fill);
      _label(canvas, 'Original', const Offset(44, 170));
      _label(canvas, 'Decupaj', const Offset(195, 170));
      canvas.drawLine(const Offset(135, 100), const Offset(157, 100), line);
    } else if (kind == 2) {
      canvas.drawPath(_shirt(70, 15, 155), fill);
      final points = [
        const Offset(113, 23),
        const Offset(182, 23),
        const Offset(147, 170),
        const Offset(108, 170),
        const Offset(190, 170),
      ];
      canvas.drawPath(
        Path()..addPolygon([
          points[0],
          points[1],
          points[4],
          points[2],
          points[3],
        ], true),
        line,
      );
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(points[i], 14, Paint()..color = colors.surface);
        _label(canvas, '${i + 1}', points[i] - const Offset(4, 8));
      }
      _label(canvas, 'Umăr', const Offset(30, 18));
      _label(canvas, 'Umăr', const Offset(230, 18));
      _label(canvas, 'Tiv', const Offset(171, 177));
    } else if (kind == 3) {
      for (var i = 0; i < 2; i++) {
        final x = 30.0 + i * 145;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 15, 95, 150),
            const Radius.circular(12),
          ),
          line,
        );
        final shoe = Path()
          ..moveTo(x + 32, 40)
          ..quadraticBezierTo(x + 52, 28, x + 62, 48)
          ..lineTo(x + 72, 121)
          ..quadraticBezierTo(x + 72, 149, x + 38, 145)
          ..quadraticBezierTo(x + 21, 140, x + 27, 119)
          ..close();
        canvas.drawPath(shoe, fill);
        for (var j = 0; j < 4; j++) {
          canvas.drawLine(
            Offset(x + 35, 65.0 + j * 10),
            Offset(x + 59, 65.0 + j * 10),
            Paint()
              ..color = colors.onPrimary
              ..strokeWidth = 2,
          );
        }
        _label(canvas, 'Papucul ${i + 1}', Offset(x + 6, 175));
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(25, 75, 120, 86),
          const Radius.circular(14),
        ),
        fill,
      );
      canvas.drawArc(
        const Rect.fromLTWH(58, 32, 55, 85),
        3.14,
        3.14,
        false,
        line..strokeWidth = 7,
      );
      canvas.drawOval(
        const Rect.fromLTWH(195, 70, 60, 77),
        Paint()
          ..color = colors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      );
      canvas.drawPath(
        Path()
          ..moveTo(225, 45)
          ..lineTo(239, 61)
          ..lineTo(225, 77)
          ..lineTo(211, 61)
          ..close(),
        fill,
      );
      _label(canvas, 'Geantă', const Offset(64, 175));
      _label(canvas, 'Inel', const Offset(211, 175));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GuideIllustration oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.colors != colors;
}
