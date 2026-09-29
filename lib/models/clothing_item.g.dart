// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clothing_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClothingItemAdapter extends TypeAdapter<ClothingItem> {
  @override
  final int typeId = 0;

  @override
  ClothingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClothingItem(
      name: fields[0] as String,
      category: fields[1] as String,
      imagePath: fields[2] as String,
      isFavorite: fields[3] as bool,
      placementSlot: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClothingItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.isFavorite)
      ..writeByte(4)
      ..write(obj.placementSlot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
