// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanAdapter extends TypeAdapter<Scan> {
  @override
  final int typeId = 1;

  @override
  Scan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Scan(
      trackingNum: fields[0] as String,
      slipNum: fields[1] as int,
      isAF: fields[2] as bool,
      timeScanned: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Scan obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.trackingNum)
      ..writeByte(1)
      ..write(obj.slipNum)
      ..writeByte(2)
      ..write(obj.isAF)
      ..writeByte(3)
      ..write(obj.timeScanned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
