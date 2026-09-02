import 'package:hive/hive.dart';

// This file will be generated in the next step
part 'slip.g.dart';

@HiveType(typeId: 2)
class Slip extends HiveObject {
  @HiveField(0)
  String? billNum;

  @HiveField(1)
  String? billId;

  @HiveField(2)
  int? pageNum;

  @HiveField(3)
  int? pageCount;

  @HiveField(4)
  String? deliveredBy;

  @HiveField(5)
  String? printedBy;

  @HiveField(6)
  DateTime? deliveryDate;

  @HiveField(7)
  String? remarks;

  @HiveField(8)
  DateTime? printDate;

  @HiveField(9)
  int? packageCount;

  Slip({
    this.billNum,
    this.billId,
    this.pageNum,
    this.pageCount,
    this.deliveredBy,
    this.printedBy,
    this.deliveryDate,
    this.remarks,
    this.printDate,
    this.packageCount,
  });
}
