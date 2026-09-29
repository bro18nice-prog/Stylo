import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/clothing_item.dart';

class WardrobeProvider extends ChangeNotifier {
  late Box<ClothingItem> _box;

  final List<ClothingItem> _items = [];

  List<ClothingItem> get items => List.unmodifiable(_items);

  Future<void> init() async {
    Hive.registerAdapter(ClothingItemAdapter());

    _box = await Hive.openBox<ClothingItem>('wardrobe');

    _items.clear();
    _items.addAll(_box.values);

    notifyListeners();
  }

  Future<void> addItem(ClothingItem item) async {
    await _box.add(item);
    _items.add(item);
    notifyListeners();
  }

  Future<void> removeItem(ClothingItem item) async {
    final index = _items.indexOf(item);

    if (index != -1) {
      await _box.deleteAt(index);
      _items.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> updateItem(int index, ClothingItem item) async {
    await _box.putAt(index, item);
    _items[index] = item;
    notifyListeners();
  }

  Future<void> toggleFavorite(ClothingItem item) async {
    final index = _items.indexOf(item);

    if (index == -1) return;

    final updated = ClothingItem(
      name: item.name,
      category: item.category,
      imagePath: item.imagePath,
      isFavorite: !item.isFavorite,
      placementSlot: item.placementSlot,
    );
    await _box.putAt(index, updated);
    item.isFavorite = updated.isFavorite;

    notifyListeners();
  }

  ClothingItem getItem(int index) => _items[index];

  int get length => _items.length;

  void refresh() => notifyListeners();

  Future<void> clear() async {
    await _box.clear();
    _items.clear();
    notifyListeners();
  }
}
