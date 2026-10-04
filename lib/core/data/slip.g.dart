// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SlipAdapter extends TypeAdapter<Slip> {
  @override
  final int typeId = 2;

  @override
  Slip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Slip(
      billNum: fields[0] as String?,
      billId: fields[1] as String?,
      pageCount: fields[2] as int?,
      deliveredBy: fields[3] as String?,
      printedBy: fields[4] as String?,
      deliveryDate: fields[5] as DateTime?,
      remarks: fields[6] as String?,
      printDate: fields[7] as DateTime?,
      packageCount: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Slip obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.billNum)
      ..writeByte(1)
      ..write(obj.billId)
      ..writeByte(2)
      ..write(obj.pageCount)
      ..writeByte(3)
      ..write(obj.deliveredBy)
      ..writeByte(4)
      ..write(obj.printedBy)
      ..writeByte(5)
      ..write(obj.deliveryDate)
      ..writeByte(6)
      ..write(obj.remarks)
      ..writeByte(7)
      ..write(obj.printDate)
      ..writeByte(8)
      ..write(obj.packageCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
