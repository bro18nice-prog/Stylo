import 'package:hive/hive.dart';

class OutfitRecord {
  const OutfitRecord({required this.wornAt, required this.itemImagePaths});

  final DateTime wornAt;
  final List<String> itemImagePaths;
}

class OutfitRecordAdapter extends TypeAdapter<OutfitRecord> {
  @override
  final int typeId = 1;

  @override
  OutfitRecord read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return OutfitRecord(
      wornAt: fields[0] as DateTime,
      itemImagePaths: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, OutfitRecord object) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(object.wornAt)
      ..writeByte(1)
      ..write(object.itemImagePaths);
  }
}
