import 'dart:math' as math;

/// Fizica barei cu umerașe: derulare cu inerție, snap pe o piesă și
/// legănarea fiecărui umeraș ca un pendul, cu cuplaj între vecini.
///
/// Dart pur (fără Flutter), ca să poată fi testat direct.
class RailPhysics {
  RailPhysics({this.spacing = 140});

  /// Distanța în pixeli dintre două umerașe.
  final double spacing;

  int count = 0;

  /// Poziția barei, în „locuri” (0 = prima piesă în centru).
  double scroll = 0;

  /// Viteza barei, în locuri pe secundă.
  double velocity = 0;
  bool dragging = false;
  double? target;

  List<double> angle = <double>[];
  List<double> omega = <double>[];
  List<double> lengths = <double>[];
  double _prevRail = 0;

  /// Cât poate depăși bara capetele (în locuri), cu efect elastic.
  static const double maxOverscroll = 0.9;

  double get pixelsPerSlot => spacing * .92;

  int get index =>
      count == 0 ? 0 : scroll.round().clamp(0, count - 1).toInt();

  /// Reface lista de umerașe. [pendulumLengths] sunt lungimile hainelor (px).
  void configure(List<double> pendulumLengths, {bool keepScroll = false}) {
    count = pendulumLengths.length;
    lengths = List<double>.from(pendulumLengths);
    angle = List<double>.filled(count, 0);
    omega = List<double>.filled(count, 0);
    if (keepScroll && count > 0) {
      scroll = scroll.clamp(0, count - 1).toDouble();
    } else {
      scroll = 0;
    }
    velocity = 0;
    target = null;
    _prevRail = 0;
  }

  void beginDrag() {
    dragging = true;
    velocity = 0;
    target = null;
  }

  void dragBy(double dx, double dtSeconds) {
    var slots = -dx / pixelsPerSlot;
    final maxSlot = count == 0 ? 0.0 : (count - 1).toDouble();
    final over = scroll < 0
        ? -scroll
        : scroll > maxSlot
        ? scroll - maxSlot
        : 0.0;
    final outward = (scroll <= 0 && slots < 0) || (scroll >= maxSlot && slots > 0);
    if (over > 0 && outward) slots /= 1 + over * 4;
    scroll = (scroll + slots).clamp(-maxOverscroll, maxSlot + maxOverscroll).toDouble();
    if (dtSeconds > 0) {
      final instant = -dx / dtSeconds / pixelsPerSlot;
      velocity = velocity * .55 + instant * .45;
    }
  }

  /// [flingPixelsPerSecond] vine de la gest (pozitiv = spre dreapta).
  void endDrag(double flingPixelsPerSecond) {
    dragging = false;
    velocity = (-flingPixelsPerSecond / pixelsPerSlot)
        .clamp(-16.0, 16.0)
        .toDouble();
  }

  void glideTo(int slot) {
    if (count == 0) return;
    target = slot.clamp(0, count - 1).toDouble();
  }

  bool get settled {
    if (dragging || target != null) return false;
    if (velocity.abs() > .005) return false;
    if (count > 0) {
      final maxSlot = (count - 1).toDouble();
      if (scroll < -.002 || scroll > maxSlot + .002) return false;
    }
    if ((scroll - scroll.round()).abs() > .002) return false;
    for (var i = 0; i < count; i++) {
      if (angle[i].abs() > .002 || omega[i].abs() > .01) return false;
    }
    return true;
  }

  void step(double dt) {
    if (dt <= 0 || count == 0) return;
    final maxSlot = (count - 1).toDouble();

    if (!dragging) {
      velocity *= math.exp(-2.4 * dt);
      scroll += velocity * dt;
      final goal = target;
      if (goal != null) {
        velocity += ((goal - scroll) * 46 - velocity * 9) * dt;
        if ((goal - scroll).abs() < .002 && velocity.abs() < .02) {
          scroll = goal;
          velocity = 0;
          target = null;
        }
      } else if (velocity.abs() < 2.4) {
        final nearest = scroll.round().clamp(0, count - 1).toDouble();
        velocity += ((nearest - scroll) * 46 - velocity * 9) * dt;
      }
      if (scroll < 0) {
        velocity += (-scroll * 70 - velocity * 17) * dt;
        if (scroll < -maxOverscroll) {
          scroll = -maxOverscroll;
          if (velocity < 0) velocity = 0;
        }
      }
      if (scroll > maxSlot) {
        velocity += ((maxSlot - scroll) * 70 - velocity * 17) * dt;
        if (scroll > maxSlot + maxOverscroll) {
          scroll = maxSlot + maxOverscroll;
          if (velocity > 0) velocity = 0;
        }
      }
      if (velocity.abs() < .0008 && (scroll - scroll.round()).abs() < .0008) {
        scroll = scroll.roundToDouble().clamp(0, maxSlot).toDouble();
        velocity = 0;
      }
    }

    final rail = -velocity * spacing;
    var acceleration = (rail - _prevRail) / dt;
    _prevRail = rail;
    acceleration = acceleration.clamp(-60000.0, 60000.0).toDouble();

    for (var i = 0; i < count; i++) {
      final length = lengths[i] + 80;
      final stiffness = 9500 / length;
      final damping = 2.1 + .5 * (1 - length / 400);
      final left = i > 0 ? angle[i - 1] : 0.0;
      final right = i < count - 1 ? angle[i + 1] : 0.0;
      final torque =
          -stiffness * angle[i] -
          damping * omega[i] +
          14 * (left + right - 2 * angle[i]) +
          acceleration * .00085 * (300 / length) +
          rail * .00004;
      omega[i] += torque * dt;
      angle[i] = (angle[i] + omega[i] * dt).clamp(-.6, .6).toDouble();
    }
  }
}
