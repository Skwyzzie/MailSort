import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mail_sort/core/data/import_record.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/package.dart';
import 'extractor.dart';

class PdfImportService {
  Future<int?> executeImportPipeline({
    required Box<Package> packageBox,
    required void Function(double progress, String status) onProgress,
    required Future<ImportRecord> Function(PlatformFile file) onFilePicked,
  }) async {
    List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isEmpty || files.single.path == null) return 0;
    PlatformFile file = files.single;

    final String pdfPath = file.path!;

    onFilePicked(file);
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

    int totalImported = 0;
    String currentSlipNum = '';
    final int totalPages = document.pagesCount;
    if (Platform.isWindows || Platform.isMacOS) {
      // Route to platform_ocr implementation
      final DesktopTrackingNumberExtractor ocrExtractor =
          DesktopTrackingNumberExtractor();
      try {
        for (int i = 1; i <= document.pagesCount; i++) {
          final double currentProgress = (i - 1) / totalPages;
          onProgress(currentProgress, 'Processing page $i of $totalPages...');
          final page = await document.getPage(i);

          // Render to image at 2x scale for high OCR accuracy
          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.jpeg,
          );

          if (pageImage != null) {
            final tempFile = File('${tempDir.path}/page_$i.jpg');
            await tempFile.writeAsBytes(pageImage.bytes);

            final slip = await ocrExtractor.extractSlipInfo(tempFile);
            currentSlipNum = (slip.billNum != null)
                ? slip.billNum.toString()
                : '';

            final extractedNumbers = await ocrExtractor.extractFromImage(
              tempFile,
            );

            for (String trackingNum in extractedNumbers) {
              // Ensure no duplicates exist in the database before adding
              final exists = packageBox.values.any(
                (p) => p.trackingNum == trackingNum,
              );

              if (!exists) {
                packageBox.add(
                  Package(
                    trackingNum: trackingNum,
                    slipNum: currentSlipNum,
                    isAF: false,
                    timeImported: DateTime.now(),
                    lastUpdated: DateTime.now(),
                    isScanned: false,
                    file: pdf, // Default to pending
                  ),
                );
                totalImported++;
              } else {
                // TODO: check import date. if more than 120 days ago, overwrite all details
                /*
                Package p = packageBox.values.first;
                p.isScanned = false;
                p.slipNum = 0;
                p.isAF = false;
                */
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
            final tempFile = File('${tempDir.path}/page_$i.jpg');
            await tempFile.writeAsBytes(pageImage.bytes);

            final extractedNumbers = await ocrExtractor.extractFromImage(
              tempFile,
            );

            for (String trackingNum in extractedNumbers) {
              final exists = packageBox.values.any(
                (p) => p.trackingNum == trackingNum,
              );

              if (!exists) {
                packageBox.add(
                  Package(
                    trackingNum: trackingNum,
                    slipNum: currentSlipNum,
                    isAF: false,
                    timeImported: DateTime.now(),
                    isScanned: false,
                    file: pdf, // Default to pending
                  ),
                );
                totalImported++;
              } else {
                // TODO: check import date. if more than 120 days ago, overwrite all details
                /*
                Package p = packageBox.values.first;
                p.isScanned = false;
                p.slipNum = 0;
                p.isAF = false;
                */
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
