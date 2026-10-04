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
  int? pageCount;

  @HiveField(3)
  String? deliveredBy;

  @HiveField(4)
  String? printedBy;

  @HiveField(5)
  DateTime? deliveryDate;

  @HiveField(6)
  String? remarks;

  @HiveField(7)
  DateTime? printDate;

  @HiveField(8)
  int? packageCount;

  Slip({
    this.billNum,
    this.billId,
    this.pageCount,
    this.deliveredBy,
    this.printedBy,
    this.deliveryDate,
    this.remarks,
    this.printDate,
    this.packageCount,
  });

  Map<String, dynamic> toJson() => {
    'billNum': billNum,
    'billId': billId,
    'pageCount': pageCount,
    'deliveredBy': deliveredBy,
    'printedBy': printedBy,
    'deliveryDate': deliveryDate.toString(),
    'remarks': remarks,
    'printDate': printDate.toString(),
    'packageCount': packageCount,
  };
}
