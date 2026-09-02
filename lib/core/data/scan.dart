import 'package:hive/hive.dart';

// This file will be generated in the next step
part 'scan.g.dart';

@HiveType(typeId: 1)
class Scan extends HiveObject {
  @HiveField(0)
  String trackingNum;

  @HiveField(1)
  int slipNum = 0;

  @HiveField(2)
  bool isAF;

  @HiveField(3)
  DateTime timeScanned;

  Scan({
    required this.trackingNum,
    required this.slipNum,
    required this.isAF,
    required this.timeScanned,
  });
}
