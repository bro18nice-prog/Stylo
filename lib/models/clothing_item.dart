import 'package:hive/hive.dart';

part 'clothing_item.g.dart';

@HiveType(typeId: 0)
class ClothingItem {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  bool isFavorite;

  @HiveField(4)
  final String? placementSlot;

  String get slot =>
      placementSlot ??
      (category == 'Pantofi'
          ? 'Papucul 1'
          : category == 'Accesorii'
          ? 'Geantă'
          : category);

  ClothingItem({
    required this.name,
    required this.category,
    required this.imagePath,
    this.isFavorite = false,
    this.placementSlot,
  });
}
