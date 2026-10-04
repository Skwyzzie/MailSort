import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml;
import 'package:intl/intl.dart';
import 'package:mail_sort/core/data/slip.dart';
import 'package:platform_ocr/platform_ocr.dart';

class MobileTrackingNumberExtractor extends TrackingNumberExtractor {
  // Initialize the recognizer (Latin script covers standard numbers and English letters)
  final ml.TextRecognizer _textRecognizer = ml.TextRecognizer(
    script: ml.TextRecognitionScript.latin,
  );
  /*
Slip slip = Slip(
                billNum: billNum,
                billId: billId,
                deliveredBy: deliveredBy,
                printedBy: printedBy,
                deliveryDate: deliveryDate,
                printDate: printDate,
                remarks: remarks,
                pageCount: pageTotal,
              );
*/
  String billNum = '';
  String billId = '';
  String deliveredBy = '';
  String printedBy = '';
  DateTime deliveryDate = DateTime.now();
  DateTime printDate = DateTime.now();
  String remarks = '';
  final RegExp trackingRegex = RegExp(r'\b\d{22}\b|\b\d{30}\b');

  Future<Slip> extractSlipInfo(File imageFile) async {
    return Slip(
      billNum: billNum,
      billId: billId,
      deliveredBy: deliveredBy,
      printedBy: printedBy,
      deliveryDate: deliveryDate,
      printDate: printDate,
      remarks: remarks,
    );
  }

  /// Processes an image file and returns a list of validated tracking numbers.
  Future<List<String>> extractFromImage(File imageFile) async {
    final File file = File(imageFile.path);
    final Uint8List bytes = await file.readAsBytes();

    // decodeImageFromList is highly efficient and doesn't block the UI thread
    final ui.Image decodedImage = await decodeImageFromList(bytes);

    final double imageWidth = decodedImage.width.toDouble();
    final double imageHeight = decodedImage.height.toDouble();
    final inputImage = ml.InputImage.fromFile(imageFile);

    final ml.RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );
    // 1. Define your logical boundaries (Matching your desktop percentages)
    final double centerAxis = imageWidth / 2;
    final double headerBottom = imageHeight * 0.15;
    final double footerTop = imageHeight * 0.67;

    List<String> headerLines = [];
    List<String> footerLines = [];
    List<String> leftColumnLines = [];
    List<String> rightColumnLines = [];

    // 2. Loop through all text found on the page
    for (ml.TextBlock block in recognizedText.blocks) {
      for (ml.TextLine line in block.lines) {
        final ui.Rect box = line.boundingBox;

        // Use the center of the text block to determine its true location
        final double itemCenterX = box.center.dx;
        final double itemCenterY = box.center.dy;

        // 3. Sort into buckets based on Y and X coordinates
        if (itemCenterY < headerBottom) {
          headerLines.add(line.text);
        } else if (itemCenterY > footerTop) {
          footerLines.add(line.text);
        } else {
          // It's in the body, so split by left/right column
          if (itemCenterX < centerAxis) {
            leftColumnLines.add(line.text);
          } else {
            rightColumnLines.add(line.text);
          }
        }
      }
    }

    _textRecognizer.close();

    // Now you can run your Regex on headerText/footerText
    // and run your (NC) anchor loop on leftColumnLines and rightColumnLines
    List<String> validTrackingNumbers = [];
    List<String> allLines = [...leftColumnLines, ...rightColumnLines];

    for (String line in headerLines) {
      if (line.contains('Bill Number:')) {
        billNum = line.split('Bill Number:').last.trim();
      } else if (line.contains('Bill ID:')) {
        billId = line.split('Bill ID:').last.trim();
      }
    }
    for (String line in footerLines) {
      if (line.contains('Delivered By:')) {
        deliveredBy = line.split('Delivered By:').last.trim();
      } else if (line.contains('Printed By:')) {
        printedBy = line.split('Printed By:').last.trim();
      } else if (line.contains('Delivery Date:')) {
        final dateString = line.split('Delivery Date:').last.trim();
        final DateFormat expectedFormat = DateFormat('MM/dd/yyyy HH:mm ZZZZZ');
        try {
          // Attempt to parse the string using the specific format
          deliveryDate = expectedFormat.parse(dateString);
        } catch (e) {
          // Fallback to now() if the OCR string is mangled or doesn't match
          deliveryDate = DateTime.now();
        }
      } else if (line.contains('Print Date:')) {
        final dateString = line.split('Print Date:').last.trim();
        final DateFormat expectedFormat = DateFormat('MM/dd/yyyy HH:mm ZZZZZ');
        try {
          // Attempt to parse the string using the specific format
          printDate = expectedFormat.parse(dateString);
        } catch (e) {
          // Fallback to now() if the OCR string is mangled or doesn't match
          printDate = DateTime.now();
        }
      } else if (line.contains('Remarks:')) {
        remarks = line.split('Remarks:').last.trim();
      }
    }
    for (String line in allLines) {
      if (line.contains('(NC)')) {
        String sanitized = line.replaceAll(' ', '').replaceAll('(NC)', '');
        if (sanitized.contains('USORD')) {
          final startIndex = sanitized.indexOf('USORD');
          validTrackingNumbers.add(sanitized.substring(startIndex));
          continue;
        }
        sanitized = normalizeOcrDigits(sanitized);
        String digitsOnly = sanitized.replaceAll(RegExp(r'\D'), '');

        // 3. Handle the 420/427 postal routing prefix if present
        final RegExp prefix = RegExp(r'^(420|427)\d{5}');
        String coreTracking = digitsOnly;
        if (prefix.hasMatch(digitsOnly)) {
          coreTracking = digitsOnly.substring(8);
        }

        while (coreTracking.length >= 15) {
          if (trackingRegex.hasMatch(coreTracking)) {
            if (_isValidModulo10(coreTracking)) {
              validTrackingNumbers.add(coreTracking);
              break;
            }
          }
          // Drop the first character and check again on the next loop
          coreTracking = coreTracking.substring(1);
        }
      }
    }
    return validTrackingNumbers;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class DesktopTrackingNumberExtractor extends TrackingNumberExtractor {
  Future<String> extractText(File imageFile) async {
    final ocr = PlatformOcr();
    if (!await imageFile.exists()) {
      return "";
    }
    final result = await ocr.recognizeText(OcrSource.file(imageFile));
    return result.text;
  }

  /// Processes an image file and returns a list of validated tracking numbers.
  Future<List<String>> extractTrackingNumbersFromImage(File imageFile) async {
    final ocr = PlatformOcr();
    if (!await imageFile.exists()) {
      return [];
    }

    final result = await ocr.recognizeText(OcrSource.file(imageFile));
    final List<String> validTrackingNumbers = [];

    // Regex looking for boundaries containing exactly 22 or 30 digits
    final RegExp trackingRegex = RegExp(r'\b\d{22}\b|\b\d{30}\b');
    for (final line in result.lines) {
      if (line.text.contains('(NC)')) {
        String sanitized = line.text.replaceAll(' ', '').replaceAll('(NC)', '');

        // 1. Handle alphanumeric edge cases FIRST (e.g., USORD)
        if (sanitized.contains('USORD')) {
          final startIndex = sanitized.indexOf('USORD');
          validTrackingNumbers.add(sanitized.substring(startIndex));
          continue;
        }

        sanitized = normalizeOcrDigits(sanitized);
        String digitsOnly = sanitized.replaceAll(RegExp(r'\D'), '');

        // 3. Handle the 420/427 postal routing prefix if present
        final RegExp prefix = RegExp(r'^(420|427)\d{5}');
        String coreTracking = digitsOnly;
        if (prefix.hasMatch(digitsOnly)) {
          coreTracking = digitsOnly.substring(8);
        }

        while (coreTracking.length >= 15) {
          if (trackingRegex.hasMatch(coreTracking)) {
            if (_isValidModulo10(coreTracking)) {
              validTrackingNumbers.add(coreTracking);
              break;
            }
          }
          // Drop the first character and check again on the next loop
          coreTracking = coreTracking.substring(1);
        }
      }
    }
    return validTrackingNumbers;
  }
}

class TrackingNumberExtractor {
  bool _isValidModulo10(String trackingNumber) {
    if (trackingNumber.isEmpty) return false;

    try {
      // The last digit is the check digit
      final int checkDigit = int.parse(
        trackingNumber.substring(trackingNumber.length - 1),
      );
      final String payload = trackingNumber.substring(
        0,
        trackingNumber.length - 1,
      );

      int sum = 0;
      bool isOddPosition = true;

      for (int j = payload.length - 1; j >= 0; j--) {
        int digit = int.parse(payload[j]);
        sum += isOddPosition ? digit * 3 : digit * 1;
        isOddPosition = !isOddPosition;
      }
      int remainder = sum % 10;
      int calculatedCheck = remainder == 0 ? 0 : 10 - remainder;
      return calculatedCheck == checkDigit;
    } catch (e) {
      return false;
    }
  }

  String normalizeOcrDigits(String input) {
    // Replace common OCR character misreads with their numeric equivalents.
    return input
        .replaceAll("O", "0")
        .replaceAll("o", "0")
        .replaceAll("D", "0")
        .replaceAll("I", "1")
        .replaceAll("l", "1")
        .replaceAll("i", "1")
        .replaceAll("Z", "2")
        .replaceAll("z", "2")
        .replaceAll("S", "5")
        .replaceAll("s", "5")
        .replaceAll("G", "6")
        .replaceAll("B", "8")
        .replaceAll("Q", "9")
        .replaceAll("q", "9")
        .replaceAll("g", "9");
  }
}
