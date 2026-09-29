import 'package:flutter_test/flutter_test.dart';
import 'package:outfit/services/anchor_fit_service.dart';

void main() {
  test(
    'All five points match independently, including deformed lower corners',
    () {
      final initial = AnchorFit.initial('Tricou');
      final target = List<Offset>.of(initial.target);
      target[3] += const Offset(-.04, .03);
      target[4] += const Offset(.05, -.02);
      final fit = initial.copyWith(target: target);
      expect(fit.valid, isTrue);
      final warp = fit.warp;
      for (var i = 0; i < 5; i++) {
        expect((warp.map(fit.source[i]) - target[i]).distance, lessThan(1e-8));
      }
      expect(AnchorFit.fromMap(fit.toMap()).toMap(), fit.toMap());
    },
  );
  test('Expanding legacy fits preserves their entire affine placement', () {
    final old = AnchorFit(
      source: const [Offset(.1, .1), Offset(.9, .15), Offset(.4, .9)],
      target: const [Offset(.2, .2), Offset(.7, .23), Offset(.5, .5)],
    );
    final upgraded = old.withFiveAnchors();
    expect(upgraded.source.length, 5);
    expect(upgraded.valid, isTrue);
    final oldWarp = old.warp, newWarp = upgraded.warp;
    for (var x = 0; x <= 10; x++) {
      for (var y = 0; y <= 10; y++) {
        final p = Offset(x / 10, y / 10);
        expect((oldWarp.map(p) - newWarp.map(p)).distance, lessThan(1e-8));
      }
    }
  });
}
