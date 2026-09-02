// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImportRecordAdapter extends TypeAdapter<ImportRecord> {
  @override
  final int typeId = 3;

  @override
  ImportRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImportRecord(
      fileName: fields[0] as String,
      filePath: fields[1] as String,
      fileSize: fields[2] as String,
      timeImported: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ImportRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.fileName)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileSize)
      ..writeByte(3)
      ..write(obj.timeImported);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
