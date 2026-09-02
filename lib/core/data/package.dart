import 'package:hive/hive.dart';
import 'package:mail_sort/core/data/import_record.dart';

// This file will be generated in the next step
part 'package.g.dart';

@HiveType(typeId: 0)
class Package extends HiveObject {
  @HiveField(0)
  String trackingNum;

  @HiveField(1)
  String? slipNum;

  @HiveField(2)
  bool isAF = false;

  @HiveField(3)
  DateTime timeImported;

  @HiveField(4)
  bool isScanned = false;

  @HiveField(5)
  ImportRecord? file;

  @HiveField(6)
  DateTime? lastUpdated;

  Package({
    required this.trackingNum,
    required this.slipNum,
    required this.isAF,
    required this.timeImported,
    this.lastUpdated,
    required this.isScanned,
    required this.file,
  });
}
