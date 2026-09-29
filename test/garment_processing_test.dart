import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:outfit/services/background_removal_service.dart';
import 'package:outfit/services/garment_fit_service.dart';

void main() {
  test(
    'Transparent margins are cropped without removing pale garment pixels',
    () {
      final source = img.Image(width: 100, height: 120, numChannels: 4);
      for (int y = 30; y < 90; y++) {
        for (int x = 25; x < 75; x++) {
          source.setPixelRgba(x, y, 250, 250, 250, 255);
        }
      }
      source.setPixelRgba(24, 60, 250, 250, 250, 80);
      final result = img.decodePng(
        trimGarmentImage(Uint8List.fromList(img.encodePng(source))),
      )!;
      expect(result.width, 59);
      expect(result.height, 68);
      expect(result.getPixel(0, 0).a, 0);
      expect(result.getPixel(5, 20).a, 255);
      expect(result.getPixel(4, 34).a, 80);
    },
  );
  test('An empty segmentation is rejected', () {
    final source = img.Image(width: 40, height: 40, numChannels: 4);
    expect(
      () => trimGarmentImage(Uint8List.fromList(img.encodePng(source))),
      throwsFormatException,
    );
  });
  test('Large input retains aspect ratio and gains a real alpha channel', () {
    final source = img.Image(width: 2000, height: 1000, numChannels: 3);
    final result = img.decodePng(
      normalizeGarmentImage(Uint8List.fromList(img.encodeJpg(source))),
    )!;
    expect(result.width, 1600);
    expect(result.height, 800);
    expect(result.numChannels, 4);
  });
  test(
    'Each garment retains its own fitting across storage reopening',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'stylo-fitting-test-',
      );
      Hive.init(folder.path);
      try {
        await GarmentFitService.save(
          'shirt.png',
          const GarmentFit(x: .12, y: -.05, scale: 1.3, rotation: .2),
        );
        await GarmentFitService.save('pants.png', const GarmentFit(scale: .8));
        await Hive.close();
        expect((await GarmentFitService.load('shirt.png')).toMap(), {
          'x': .12,
          'y': -.05,
          'scale': 1.3,
          'rotation': .2,
        });
        expect((await GarmentFitService.load('pants.png')).scale, .8);
        expect((await GarmentFitService.load('new.png')).scale, 1);
      } finally {
        await Hive.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
