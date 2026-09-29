import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'background_removal_service.dart';

Future<void> initGarmentStorage() async {}
ImageProvider garmentImage(String path) => FileImage(File(path));
Future<Uint8List> readGarment(String path) => File(path).readAsBytes();
Future<String> saveGarment(Uint8List bytes, String extension) async {
  final dir = await getApplicationSupportDirectory();
  final folder = await Directory(
    '${dir.path}/garments',
  ).create(recursive: true);
  final path =
      '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.$extension';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

Future<Uint8List> cutoutGarment(Uint8List bytes, double threshold) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/stylo_input_${DateTime.now().microsecondsSinceEpoch}',
  );
  File? result;
  try {
    await file.writeAsBytes(bytes);
    result = await BackgroundRemovalService.removeBackground(
      file,
      threshold: threshold,
    );
    return await result.readAsBytes();
  } finally {
    if (await file.exists()) await file.delete();
    if (result != null && await result.exists()) await result.delete();
  }
}
