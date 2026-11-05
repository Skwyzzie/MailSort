// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnitAdapter extends TypeAdapter<Unit> {
  @override
  final int typeId = 4;

  @override
  Unit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Unit(
      unitName: fields[0] as String,
      unitAbbreviation: fields[1] as String?,
      unitBranch: fields[2] as String,
      unitMailClerk: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Unit obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.unitName)
      ..writeByte(1)
      ..write(obj.unitAbbreviation)
      ..writeByte(2)
      ..write(obj.unitBranch)
      ..writeByte(3)
      ..write(obj.unitMailClerk);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
