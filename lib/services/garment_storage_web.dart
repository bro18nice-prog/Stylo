import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';

Future<void> initGarmentStorage() async {
  await Hive.openBox('garment_images_v1');
}

Uint8List _bytes(String path) {
  final data = Hive.box('garment_images_v1').get(path);
  if (data == null) throw StateError('Fotografia nu mai este disponibilă.');
  return data is Uint8List ? data : Uint8List.fromList(List<int>.from(data));
}

ImageProvider garmentImage(String path) => MemoryImage(_bytes(path));
Future<Uint8List> readGarment(String path) async => _bytes(path);
Future<String> saveGarment(Uint8List bytes, String extension) async {
  final key = 'web:${DateTime.now().microsecondsSinceEpoch}.$extension';
  await Hive.box('garment_images_v1').put(key, bytes);
  return key;
}

@JS('styloRemoveBackground')
external JSPromise<JSUint8Array> _removeBackground(
  JSUint8Array bytes,
  JSNumber threshold,
);
Future<Uint8List> cutoutGarment(Uint8List bytes, double threshold) async {
  final result = await _removeBackground(bytes.toJS, threshold.toJS).toDart;
  return result.toDart;
}
