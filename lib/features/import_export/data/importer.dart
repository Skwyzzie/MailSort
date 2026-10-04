import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mail_sort/core/data/import_record.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/package.dart';
import 'extractor.dart';
import 'package:image/image.dart' as img;
import 'package:mail_sort/core/data/slip.dart';

class PdfImportService {
  late final Box settingsBox;
  late final Box<ImportRecord> importBox;
  Future<int?> executeImportPipeline({
    required Box<Package> packageBox,
    required void Function(double progress, String status) onProgress,
    required Future<ImportRecord> Function(PlatformFile file) onFilePicked,
  }) async {
    settingsBox = Hive.box('settingsBox');
    importBox = Hive.box<ImportRecord>('importBox');
    String packageType = settingsBox.get('packageBranch', defaultValue: 'Army');

    List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isEmpty || files.single.path == null) return 0;
    PlatformFile file = files.single;

    final String pdfPath = file.path!;

    onFilePicked(file);

    final matchedImport = importBox.values.cast<ImportRecord?>().firstWhere(
      (p) => p?.filePath == file.path,
      orElse: () => null,
    );
    if (matchedImport != null) return 0;
    onProgress(0.0, 'Opening document...');

    final int size = await file.length();
    final kb = size / 1024;
    String sizeString = (kb > 1024)
        ? '${(kb / 1024).toStringAsFixed(2)} MB'
        : '${kb.toStringAsFixed(0)} KB';
    final pdf = ImportRecord(
      fileName: file.name,
      filePath: file.path!,
      fileSize: sizeString,
      timeImported: DateTime.now(),
    );

    // Initialize PDF Document
    final document = await PdfDocument.openFile(pdfPath);
    final tempDir = await getTemporaryDirectory();
    final tempDir2 = '${tempDir.path}/MailSort/temp_images';
    await Directory(tempDir2).create(recursive: true);

    int totalImported = 0;
    String currentSlipNum = '';
    final int totalPages = document.pagesCount;

    final Box<Slip> slipBox = Hive.box<Slip>('slipBox');
    if (Platform.isWindows || Platform.isMacOS) {
      // Route to platform_ocr implementation
      final DesktopTrackingNumberExtractor ocrExtractor =
          DesktopTrackingNumberExtractor();
      try {
        int pageTotal = document.pagesCount;
        String billNum = '';
        for (int i = 1; i <= document.pagesCount; i++) {
          final double currentProgress = (i - 1) / totalPages;
          onProgress(currentProgress, 'Processing page $i of $totalPages...');
          final page = await document.getPage(i);

          final double scaleFactor = 2.0;

          // Render to image at 2x scale for high OCR accuracy
          final pageImage = await page.render(
            width: page.width * scaleFactor,
            height: page.height * scaleFactor,
            format: PdfPageImageFormat.jpeg,
          );

          if (pageImage != null) {
            final originalImage = img.decodeImage(pageImage.bytes);

            if (originalImage != null) {
              final int totalWidth = (page.width).toInt();
              final int totalHeight = (page.height).toInt();

              final int centerAxis = totalWidth ~/ 2;
              final int headerHeight = (totalHeight * 0.15).toInt();
              final int footerY = (totalHeight * 0.67).toInt();
              final int bodyHeight = footerY - headerHeight;

              final List<CropZone> targets = [
                CropZone('header', 0, 0, totalWidth, headerHeight),
                CropZone(
                  'tracking_left',
                  0,
                  headerHeight,
                  centerAxis,
                  bodyHeight,
                ),

                CropZone(
                  'tracking_right',
                  centerAxis,
                  headerHeight,
                  centerAxis,
                  bodyHeight,
                ),
                CropZone(
                  'footer',
                  0,
                  footerY,
                  totalWidth,
                  totalHeight - footerY,
                ),
              ];

              List<String> extractedTrackingNumbers = [];
              //DateFormat inputFormat = DateFormat("MM/dd/yyyy HH:mm Z");
              String billId = '';
              String deliveredBy = '';
              String printedBy = '';
              DateTime deliveryDate = DateTime.now();
              String remarks = '';
              DateTime printDate = DateTime.now();

              for (final target in targets) {
                final int scaledX = (target.x * scaleFactor).toInt();
                final int scaledY = (target.y * scaleFactor).toInt();
                final int scaledW = (target.width * scaleFactor).toInt();
                final int scaledH = (target.height * scaleFactor).toInt();

                // Crop
                final croppedImage = img.copyCrop(
                  originalImage,
                  x: scaledX,
                  y: scaledY,
                  width: scaledW,
                  height: scaledH,
                );
                const int padding = 20;

                final paddedImage = img.Image(
                  width: croppedImage.width + (padding * 2),
                  height: croppedImage.height + (padding * 2),
                );

                img.fill(paddedImage, color: img.ColorRgb8(255, 255, 255));

                img.compositeImage(
                  paddedImage,
                  croppedImage,
                  dstX: padding,
                  dstY: padding,
                );

                // Save temp file
                final tempFile = File('$tempDir2/page_${i}_${target.id}.jpg');
                await tempFile.writeAsBytes(img.encodeJpg(paddedImage));

                // 4. Run OCR and route the text based on the target ID
                if (target.id == 'tracking_left' ||
                    target.id == 'tracking_right') {
                  extractedTrackingNumbers.addAll(
                    await ocrExtractor.extractTrackingNumbersFromImage(
                      tempFile,
                    ),
                  );
                } else {
                  if (i == 1) {
                    final result = await ocrExtractor.extractText(tempFile);
                    switch (target.id) {
                      case 'header':
                        String headerText = result.trim();
                        // Bill Number: Extracts the digits after the label
                        billNum =
                            RegExp(
                              r'Bill Number[;:]\s*(\d+)',
                            ).firstMatch(headerText)?.group(1) ??
                            'Unknown';

                        // Bill ID: Extracts the digits after the label

                        billId =
                            RegExp(
                              r'Bill I[DO0][;:]\s*(\d+)',
                            ).firstMatch(headerText)?.group(1) ??
                            'Unknown';
                        break;
                      case 'footer':
                        String footerText = result.trim();
                        // Date of Delivery: Captures the full date, time, and timezone offset
                        // Example: "09/28/2026 06:24 -05:00"
                        deliveryDate =
                            DateTime.tryParse(
                              RegExp(
                                    r'Date of Delivery\s*([\d/]+\s+\d{2}:\d{2}\s*[+\-]\d{2}:\d{2})',
                                  ).firstMatch(footerText)?.group(1) ??
                                  'Unknown',
                            ) ??
                            DateTime.now();
                        deliveredBy =
                            RegExp(
                              r'Delivered By.*?\s+([A-Z]+,\s*[A-Z]+)',
                            ).firstMatch(footerText)?.group(1) ??
                            'Unknown';

                        // Printed By: Captures LASTNAME, FIRSTNAME format
                        printedBy =
                            RegExp(
                              r'Printed By:\s*([A-Z]+,\s*[A-Z]+)',
                            ).firstMatch(footerText)?.group(1) ??
                            'Unknown';

                        // Date Printed: Captures the date and time printed at the very bottom
                        printDate =
                            DateTime.tryParse(
                              RegExp(
                                    r'Printed on:\s*([\d/]+\s+\d{2}:\d{2})',
                                  ).firstMatch(footerText)?.group(1) ??
                                  'Unknown',
                            ) ??
                            DateTime.now();

                        final match = RegExp(
                          r'Remarks:\s*(.*?)\s*Bill',
                        ).firstMatch(footerText);
                        remarks = match?.group(1) ?? 'None';
                        break;
                    }
                  }
                }

                // Clean up the tiny cropped file immediately

                if (await tempFile.exists()) {
                  await tempFile.delete();
                }
              }

              final Slip slip = Slip(
                billNum: billNum,
                billId: billId,
                deliveredBy: deliveredBy,
                printedBy: printedBy,
                deliveryDate: deliveryDate,
                printDate: printDate,
                remarks: remarks,
                pageCount: pageTotal,
              );

              final slipExists = slipBox.values.any(
                (s) => s.billNum == billNum,
              );
              if (!slipExists) {
                slipBox.add(slip);
              }

              for (String trackingNum in extractedTrackingNumbers) {
                // Ensure no duplicates exist in the database before adding
                final exists = packageBox.values.any(
                  (p) => p.trackingNum == trackingNum,
                );

                if (!exists) {
                  packageBox.add(
                    Package(
                      trackingNum: trackingNum,
                      slipNum: billNum,
                      packageType: packageType,
                      timeImported: DateTime.now(),
                      lastUpdated: DateTime.now(),
                      isScanned: false,
                      file: pdf, // Default to pending
                    ),
                  );
                  totalImported++;
                }
              }
            }
          }

          await page.close();
        }
        onProgress(1.0, 'Finalizing import...');
        final slip = slipBox.values.firstWhere(
          (s) => s.billNum == billNum,
          orElse: () => Slip(billId: ''),
        );

        if (slip.billId!.isNotEmpty) {
          slip.packageCount = totalImported;
          slip.save();
        }
        return totalImported;
      } finally {
        await document.close();
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final MobileTrackingNumberExtractor ocrExtractor =
          MobileTrackingNumberExtractor();
      try {
        for (int i = 1; i <= document.pagesCount; i++) {
          final double currentProgress = (i - 1) / totalPages;
          onProgress(currentProgress, 'Processing page $i of $totalPages...');
          final page = await document.getPage(i);

          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.jpeg,
          );

          if (pageImage != null) {
            final tempFile = File('$tempDir2/page_$i.jpg');
            await tempFile.writeAsBytes(pageImage.bytes);

            final extractedNumbers = await ocrExtractor.extractFromImage(
              tempFile,
            );

            final slip = await ocrExtractor.extractSlipInfo(tempFile);
            currentSlipNum = slip.billNum ?? '';
            slipBox.add(slip);

            for (String trackingNum in extractedNumbers) {
              final exists = packageBox.values.any(
                (p) => p.trackingNum == trackingNum,
              );

              if (!exists) {
                packageBox.add(
                  Package(
                    trackingNum: trackingNum,
                    slipNum: currentSlipNum,
                    packageType: packageType,
                    timeImported: DateTime.now(),
                    isScanned: false,
                    file: pdf, // Default to pending
                  ),
                );
                totalImported++;
              }
            }

            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          }

          await page.close();
        }
        onProgress(1.0, 'Finalizing import...');
        return totalImported;
      } finally {
        await document.close();
        ocrExtractor.dispose();
      }
    } else {
      return 0;
    }
  }
}

class CropZone {
  final String id;
  final int x;
  final int y;
  final int width;
  final int height;

  CropZone(this.id, this.x, this.y, this.width, this.height);
}
