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
      pageNum: fields[2] as int?,
      pageCount: fields[3] as int?,
      deliveredBy: fields[4] as String?,
      printedBy: fields[5] as String?,
      deliveryDate: fields[6] as DateTime?,
      remarks: fields[7] as String?,
      printDate: fields[8] as DateTime?,
      packageCount: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Slip obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.billNum)
      ..writeByte(1)
      ..write(obj.billId)
      ..writeByte(2)
      ..write(obj.pageNum)
      ..writeByte(3)
      ..write(obj.pageCount)
      ..writeByte(4)
      ..write(obj.deliveredBy)
      ..writeByte(5)
      ..write(obj.printedBy)
      ..writeByte(6)
      ..write(obj.deliveryDate)
      ..writeByte(7)
      ..write(obj.remarks)
      ..writeByte(8)
      ..write(obj.printDate)
      ..writeByte(9)
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
