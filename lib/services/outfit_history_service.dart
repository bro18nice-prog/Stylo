import 'package:hive/hive.dart';

import '../models/clothing_item.dart';
import '../models/outfit_record.dart';

class OutfitHistoryService {
  static late Box<OutfitRecord> _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OutfitRecordAdapter());
    }
    _box = await Hive.openBox<OutfitRecord>('outfit_history');
  }

  static Future<void> markWorn(Iterable<ClothingItem?> items) async {
    final paths = items
        .whereType<ClothingItem>()
        .map((item) => item.imagePath)
        .toList();
    if (paths.isEmpty) return;
    await _box.add(OutfitRecord(wornAt: DateTime.now(), itemImagePaths: paths));
  }

  static DateTime? lastWornAt(String imagePath) {
    for (final record in _box.values.toList().reversed) {
      if (record.itemImagePaths.contains(imagePath)) return record.wornAt;
    }
    return null;
  }

  static String? lastWornLabel(String imagePath) {
    final date = lastWornAt(imagePath);
    if (date == null) return null;
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Purtat azi';
    if (days == 1) return 'Purtat ieri';
    return 'Purtat acum $days zile';
  }
}
