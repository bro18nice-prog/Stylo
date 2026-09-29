import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// Thin-plate interpolation: each control point maps to its own target.
/// The affine term reproduces existing three-anchor fits exactly.
class AnchorWarp {
  final List<Offset> source;
  late final List<List<double>> _coefficients;
  AnchorWarp(this.source, List<Offset> target) {
    final n = source.length;
    final m = List.generate(n + 3, (_) => List.filled(n + 5, 0.0));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        m[i][j] = _kernel((source[i] - source[j]).distanceSquared);
      }
      m[i][n] = m[n][i] = 1;
      m[i][n + 1] = m[n + 1][i] = source[i].dx;
      m[i][n + 2] = m[n + 2][i] = source[i].dy;
      m[i][n + 3] = target[i].dx;
      m[i][n + 4] = target[i].dy;
    }
    for (var col = 0; col < n + 3; col++) {
      var pivot = col;
      for (var row = col + 1; row < n + 3; row++) {
        if (m[row][col].abs() > m[pivot][col].abs()) pivot = row;
      }
      if (m[pivot][col].abs() < 1e-12) {
        throw ArgumentError('Ancore suprapuse sau coliniare.');
      }
      final swap = m[col];
      m[col] = m[pivot];
      m[pivot] = swap;
      final scale = m[col][col];
      for (var k = col; k < n + 5; k++) {
        m[col][k] /= scale;
      }
      for (var row = 0; row < n + 3; row++) {
        if (row == col) continue;
        final factor = m[row][col];
        for (var k = col; k < n + 5; k++) {
          m[row][k] -= factor * m[col][k];
        }
      }
    }
    _coefficients = m.map((row) => [row[n + 3], row[n + 4]]).toList();
  }
  static double _kernel(double r2) => r2 < 1e-20 ? 0 : r2 * math.log(r2);
  Offset map(Offset p) {
    final n = source.length;
    var x =
        _coefficients[n][0] +
        p.dx * _coefficients[n + 1][0] +
        p.dy * _coefficients[n + 2][0];
    var y =
        _coefficients[n][1] +
        p.dx * _coefficients[n + 1][1] +
        p.dy * _coefficients[n + 2][1];
    for (var i = 0; i < n; i++) {
      final k = _kernel((p - source[i]).distanceSquared);
      x += k * _coefficients[i][0];
      y += k * _coefficients[i][1];
    }
    return Offset(x, y);
  }
}
