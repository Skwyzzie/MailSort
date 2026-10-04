import 'package:hive/hive.dart';

// This file will be generated in the next step
part 'import_record.g.dart';

@HiveType(typeId: 3)
class ImportRecord extends HiveObject {
  @HiveField(0)
  String fileName;

  @HiveField(1)
  String filePath;

  @HiveField(2)
  String fileSize;

  @HiveField(3)
  DateTime timeImported;

  ImportRecord({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.timeImported,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'filePath': filePath,
    'fileSize': fileSize,
    'timeImported': timeImported.toString(),
  };
}
