import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';
import 'package:path_provider/path_provider.dart';

class BackgroundRemovalService {
  static Future<void>? _initializing;
  static bool _busy = false;
  static Future<File> removeBackground(
    File input, {
    double threshold = .45,
  }) async {
    if (_busy) throw StateError('O altă fotografie este încă procesată.');
    _busy = true;
    try {
      final normalized = await compute(
        normalizeGarmentImage,
        await input.readAsBytes(),
      );
      _initializing ??= BackgroundRemover.instance.initializeOrt();
      try {
        await _initializing;
      } catch (_) {
        _initializing = null;
        rethrow;
      }
      final result = await BackgroundRemover.instance.removeBgBytes(
        normalized,
        threshold: threshold,
        smoothMask: true,
        enhanceEdges: true,
      );
      final trimmed = await compute(trimGarmentImage, result);
      final folder = await getTemporaryDirectory();
      final output = File(
        '${folder.path}/stylo_cutout_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await output.writeAsBytes(trimmed, flush: true);
      return output;
    } finally {
      _busy = false;
    }
  }
}

Uint8List normalizeGarmentImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Fotografia nu poate fi citită.');
  }
  var image = img.bakeOrientation(decoded).convert(numChannels: 4);
  if (image.width > 1600 || image.height > 1600) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 1600 : null,
      height: image.height > image.width ? 1600 : null,
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List trimGarmentImage(Uint8List bytes) {
  final image = img.decodePng(bytes);
  if (image == null) {
    throw const FormatException('Decuparea nu poate fi citită.');
  }
  int left = image.width,
      top = image.height,
      right = -1,
      bottom = -1,
      visible = 0;
  for (final pixel in image) {
    if (pixel.a > 24) {
      visible++;
      if (pixel.x < left) left = pixel.x;
      if (pixel.y < top) top = pixel.y;
      if (pixel.x > right) right = pixel.x;
      if (pixel.y > bottom) bottom = pixel.y;
    }
  }
  if (visible < image.width * image.height * .003 || right < left) {
    throw const FormatException('Haina nu a fost detectată.');
  }
  left = (left - 4).clamp(0, image.width - 1);
  top = (top - 4).clamp(0, image.height - 1);
  right = (right + 4).clamp(0, image.width - 1);
  bottom = (bottom + 4).clamp(0, image.height - 1);
  return Uint8List.fromList(
    img.encodePng(
      img.copyCrop(
        image,
        x: left,
        y: top,
        width: right - left + 1,
        height: bottom - top + 1,
      ),
    ),
  );
}
