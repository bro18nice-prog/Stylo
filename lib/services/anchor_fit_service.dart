import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'anchor_warp.dart';

/// Coordinates are normalized to the photograph and fixed mannequin respectively.
class AnchorFit {
  final List<Offset> source;
  final List<Offset> target;
  AnchorFit({required List<Offset> source, required List<Offset> target})
    : source = List.unmodifiable(source),
      target = List.unmodifiable(target);
  static double area(List<Offset> p) =>
      (p[1].dx - p[0].dx) * (p[2].dy - p[0].dy) -
      (p[2].dx - p[0].dx) * (p[1].dy - p[0].dy);
  bool get valid =>
      (source.length == 3 || source.length == 5) &&
      target.length == source.length &&
      _separated(source) &&
      _separated(target) &&
      [...source, ...target].every(
        (p) =>
            p.dx.isFinite &&
            p.dy.isFinite &&
            p.dx >= 0 &&
            p.dy >= 0 &&
            p.dx <= 1 &&
            p.dy <= 1,
      ) &&
      area(source) > .00001 &&
      area(target) > .00001;
  static bool _separated(List<Offset> points) {
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        if ((points[i] - points[j]).distanceSquared < 1e-8) return false;
      }
    }
    return true;
  }

  AnchorFit withFiveAnchors() {
    if (source.length == 5) return this;
    List<Offset> expand(List<Offset> p) => [
      ...p,
      (p[0] + p[2]) / 2,
      (p[1] + p[2]) / 2,
    ];
    return AnchorFit(source: expand(source), target: expand(target));
  }

  AnchorWarp get warp => AnchorWarp(source, target);
  AnchorFit copyWith({List<Offset>? source, List<Offset>? target}) =>
      AnchorFit(source: source ?? this.source, target: target ?? this.target);
  factory AnchorFit.initial(String slot) {
    final rect = switch (slot) {
      'Tricou' => const Rect.fromLTWH(.18, .19, .64, .28),
      'Geacă' => const Rect.fromLTWH(.15, .18, .70, .32),
      'Pantaloni' => const Rect.fromLTWH(.28, .44, .44, .49),
      'Papucul 1' => const Rect.fromLTWH(.265, .895, .15, .065),
      'Papucul 2' => const Rect.fromLTWH(.585, .895, .15, .065),
      'Inel' => const Rect.fromLTWH(.79, .549, .023, .012),
      _ => const Rect.fromLTWH(.70, .40, .24, .18),
    };
    const source = [
      Offset(.2, .12),
      Offset(.8, .12),
      Offset(.5, .92),
      Offset(.2, .92),
      Offset(.8, .92),
    ];
    return AnchorFit(
      source: source,
      target: source
          .map(
            (p) => Offset(
              rect.left + p.dx * rect.width,
              rect.top + p.dy * rect.height,
            ),
          )
          .toList(),
    );
  }

  /// Affine transform: matches all three reference points without perspective.
  Matrix4 matrix(Size size) {
    if (!valid) return Matrix4.identity();
    final s = source
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    final t = target
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    final u = s[1] - s[0], v = s[2] - s[0], a = t[1] - t[0], b = t[2] - t[0];
    final d = u.dx * v.dy - v.dx * u.dy;
    final xx = (a.dx * v.dy - b.dx * u.dy) / d,
        xy = (b.dx * u.dx - a.dx * v.dx) / d;
    final yx = (a.dy * v.dy - b.dy * u.dy) / d,
        yy = (b.dy * u.dx - a.dy * v.dx) / d;
    return Matrix4.identity()
      ..setEntry(0, 0, xx)
      ..setEntry(0, 1, xy)
      ..setEntry(1, 0, yx)
      ..setEntry(1, 1, yy)
      ..setEntry(0, 3, t[0].dx - xx * s[0].dx - xy * s[0].dy)
      ..setEntry(1, 3, t[0].dy - yx * s[0].dx - yy * s[0].dy);
  }

  Map<String, dynamic> toMap() => {
    'source': source.map((p) => [p.dx, p.dy]).toList(),
    'target': target.map((p) => [p.dx, p.dy]).toList(),
  };
  factory AnchorFit.fromMap(Map data) => AnchorFit(
    source: (data['source'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
    target: (data['target'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
  );
}

class AnchorFitService {
  static Future<Box> _box() => Hive.openBox('anchor_fits_v1');
  static Future<AnchorFit?> load(
    String path, {
    String profile = 'Masculin',
  }) async {
    final data = (await _box()).get(
      profile == 'Feminin' ? 'female_v1::$path' : path,
    );
    if (data == null) return null;
    try {
      final fit = AnchorFit.fromMap(data as Map);
      return fit.valid ? fit : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    String path,
    AnchorFit fit, {
    String profile = 'Masculin',
  }) async {
    if (!fit.valid) {
      throw ArgumentError(
        'Punctele trebuie să fie distincte, iar primele trei să păstreze orientarea.',
      );
    }
    await (await _box()).put(
      profile == 'Feminin' ? 'female_v1::$path' : path,
      fit.toMap(),
    );
  }
}
