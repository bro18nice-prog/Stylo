import 'package:hive/hive.dart';

class GarmentFit {
  final double x, y, scale, rotation;
  const GarmentFit({this.x = 0, this.y = 0, this.scale = 1, this.rotation = 0});
  GarmentFit copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) => GarmentFit(
    x: (x ?? this.x).clamp(-.5, .5),
    y: (y ?? this.y).clamp(-.4, .4),
    scale: (scale ?? this.scale).clamp(.4, 2.2),
    rotation: (rotation ?? this.rotation).clamp(-.6, .6),
  );
  Map<String, double> toMap() => {
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
  };
  factory GarmentFit.fromMap(Map map) => const GarmentFit().copyWith(
    x: (map['x'] as num?)?.toDouble(),
    y: (map['y'] as num?)?.toDouble(),
    scale: (map['scale'] as num?)?.toDouble(),
    rotation: (map['rotation'] as num?)?.toDouble(),
  );
}

class GarmentFitService {
  static Future<Box> _box() => Hive.openBox('garment_fits');
  static Future<GarmentFit> load(String path) async {
    final values =
        (await _box()).get('mannequin_v1', defaultValue: <String, dynamic>{})
            as Map;
    final data = values[path];
    return data is Map ? GarmentFit.fromMap(data) : const GarmentFit();
  }

  static Future<void> save(String path, GarmentFit fit) async {
    final box = await _box();
    final values = Map<String, dynamic>.from(
      box.get('mannequin_v1', defaultValue: <String, dynamic>{}) as Map,
    );
    values[path] = fit.toMap();
    await box.put('mannequin_v1', values);
  }
}
