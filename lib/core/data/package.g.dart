// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PackageAdapter extends TypeAdapter<Package> {
  @override
  final int typeId = 0;

  @override
  Package read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Package(
      trackingNum: fields[0] as String,
      slipNum: fields[1] as String?,
      packageType: fields[2] as String,
      timeImported: fields[3] as DateTime,
      lastUpdated: fields[6] as DateTime?,
      isScanned: fields[4] as bool,
      file: fields[5] as ImportRecord?,
    );
  }

  @override
  void write(BinaryWriter writer, Package obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.trackingNum)
      ..writeByte(1)
      ..write(obj.slipNum)
      ..writeByte(2)
      ..write(obj.packageType)
      ..writeByte(3)
      ..write(obj.timeImported)
      ..writeByte(4)
      ..write(obj.isScanned)
      ..writeByte(5)
      ..write(obj.file)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
