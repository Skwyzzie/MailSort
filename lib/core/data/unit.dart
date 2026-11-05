import 'package:hive/hive.dart';

// This file will be generated in the next step
part 'unit.g.dart';

@HiveType(typeId: 4)
class Unit extends HiveObject {
  @HiveField(0)
  String unitName;

  @HiveField(1)
  String? unitAbbreviation;

  @HiveField(2)
  String unitBranch = '';

  @HiveField(3)
  String unitMailClerk;

  Unit({
    required this.unitName,
    required this.unitAbbreviation,
    required this.unitBranch,
    required this.unitMailClerk,
  });
  Map<String, dynamic> toJson() => {
    'unitName': unitName,
    'unitAbbreviation': unitAbbreviation,
    'unitBranch': unitBranch,
    'unitMailClerk': unitMailClerk,
  };

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      unitName: json['unitName'] as String? ?? '',
      unitAbbreviation: json['unitAbbreviation'] as String? ?? '',
      unitBranch: json['unitBranch'] as String? ?? 'Army',
      unitMailClerk: json['unitMailClerk'] as String? ?? '',
    );
  }
}
