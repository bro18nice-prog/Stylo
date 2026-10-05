import 'package:flutter_test/flutter_test.dart';
import 'package:outfit/ui/components/hanger_rail_physics.dart';

void _run(RailPhysics physics, int frames) {
  for (var i = 0; i < frames; i++) {
    physics.step(1 / 120);
  }
}

void main() {
  test('o aruncare cu inerție se oprește exact pe o piesă', () {
    final physics = RailPhysics()..configure(List<double>.filled(6, 200));
    physics.beginDrag();
    physics.dragBy(-120, 1 / 60);
    physics.endDrag(-1800);
    _run(physics, 2400);
    expect(physics.settled, isTrue);
    expect(physics.scroll, closeTo(physics.scroll.roundToDouble(), 0.01));
    expect(physics.scroll, inInclusiveRange(0, 5));
    expect(physics.index, greaterThan(0));
  });

  test('bara nu iese din capete și revine elastic', () {
    final physics = RailPhysics()..configure(List<double>.filled(4, 200));
    physics.beginDrag();
    physics.dragBy(300, 1 / 60);
    physics.endDrag(2500);
    _run(physics, 2400);
    expect(physics.scroll, closeTo(0, 0.01));
    expect(physics.settled, isTrue);

    physics.beginDrag();
    physics.dragBy(-2000, 1 / 60);
    physics.endDrag(-6000);
    _run(physics, 2400);
    expect(physics.scroll, closeTo(3, 0.01));
  });

  test('umerașele se leagănă la mișcare și se liniștesc după aceea', () {
    final physics = RailPhysics()..configure(List<double>.filled(5, 240));
    physics.beginDrag();
    physics.dragBy(-80, 1 / 60);
    physics.endDrag(-2200);
    var maxAngle = 0.0;
    for (var i = 0; i < 400; i++) {
      physics.step(1 / 120);
      for (final a in physics.angle) {
        if (a.abs() > maxAngle) maxAngle = a.abs();
      }
    }
    expect(maxAngle, greaterThan(0.03));
    expect(maxAngle, lessThanOrEqualTo(0.6));
    _run(physics, 6000);
    for (final a in physics.angle) {
      expect(a.abs(), lessThan(0.003));
    }
  });

  test('glideTo duce bara la piesa cerută', () {
    final physics = RailPhysics()..configure(List<double>.filled(7, 200));
    physics.glideTo(4);
    _run(physics, 3000);
    expect(physics.index, 4);
    expect(physics.scroll, closeTo(4, 0.01));
    expect(physics.target, isNull);
  });

  test('o listă goală nu aruncă erori', () {
    final physics = RailPhysics()..configure(<double>[]);
    _run(physics, 10);
    expect(physics.index, 0);
    expect(physics.settled, isTrue);
  });
}
