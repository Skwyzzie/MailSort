import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mail_sort/core/data/slip.dart';
import 'package:platform_ocr/platform_ocr.dart';
import 'package:intl/intl.dart';

class MobileTrackingNumberExtractor extends TrackingNumberExtractor {
  // Initialize the recognizer (Latin script covers standard numbers and English letters)
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<Slip> extractSlipInfo(File imageFile) async {
    return Slip();
  }

  /// Processes an image file and returns a list of validated tracking numbers.
  Future<List<String>> extractFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    final List<String> validTrackingNumbers = [];

    // Regex looking for boundaries containing exactly 22 or 30 digits
    final RegExp trackingRegex = RegExp(r'\b\d{22}\b|\b\d{30}\b');

    // Iterate through the recognized text blocks and lines
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        // Remove spaces from the line in case the OCR split the barcode digits
        final cleanLine = line.text.replaceAll(' ', '');

        final matches = trackingRegex.allMatches(cleanLine);

        final numericLine = normalizeOcrDigits(cleanLine);
        String mergedDigits = numericLine.replaceAll(RegExp(r"\D"), "");
        bool foundNumeric = false;

        // ==========================================
        // PASS 1: USPS NUMERIC TRACKING (Right-To-Left)
        // ==========================================
        int i = mergedDigits.length - 22;
        final RegExp prefix = RegExp(r'^(420|427)\d{5}$');
        while (i >= 0) {
          String coreTracking = mergedDigits.substring(i, 22);

          if (_isValidModulo10(coreTracking)) {
            foundNumeric = true;

            // ALWAYS store just the 22-digit core tracking number
            validTrackingNumbers.add(coreTracking);
            // Check if an 8-digit routing prefix exists before our core tracking number
            if (i >= 8 && prefix.hasMatch(mergedDigits.substring(i - 8, 8))) {
              // Prefix found: Jump past the full 30-digit block so we don't scan the zip code
              i -= 30;
            } else {
              // No prefix
              i -= 22;
            }
          } else {
            i--; // No match
          }

          // ==========================================
          // PASS 2: ALPHANUMERIC TRACKING (UPS / eVS)
          // ==========================================
          if (!foundNumeric) {
            final tokenizedString = numericLine.replaceAll(
              RegExp(r'[^a-zA-Z0-9]'),
              ' ',
            );
            final words = tokenizedString.split(' ');

            for (final word in words) {
              if (word.length >= 10 &&
                  RegExp(r'^[A-Z0-9]+$').hasMatch(word) &&
                  RegExp(r'[A-Z]').hasMatch(word) &&
                  RegExp(r'[0-9]').hasMatch(word) &&
                  word != 'NC') {
                validTrackingNumbers.add(word);
              }
            }
          }
        }
        for (final match in matches) {
          final String? possibleNumber = match.group(0);

          if (possibleNumber != null && _isValidModulo10(possibleNumber)) {
            // Avoid adding duplicates if the same number is read twice on a label
            if (!validTrackingNumbers.contains(possibleNumber)) {
              validTrackingNumbers.add(possibleNumber);
            }
          }
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
  Future<Slip> extractSlipInfo(File imageFile) async {
    final ocr = PlatformOcr();
    if (!await imageFile.exists()) {
      return Slip();
    }

    DateFormat inputFormat = DateFormat("MM/dd/yyyy HH:mm Z");

    final result = await ocr.recognizeText(OcrSource.file(imageFile));
    bool deliveryNext = false;
    bool remarkNext = false;
    bool deliveredNext = false;

    String billNum = '';
    String billId = '';
    String deliveredBy = '';
    String printedBy = '';
    DateTime? deliveryDate = DateTime.now();
    String remarks = '';
    DateTime? printDate = DateTime.now();

    for (final line in result.lines) {
      if (deliveryNext) {
        //We are looking for date of delivery/remarks/and delivered by info
        //save line.text, but in the right spot.
        inputFormat = DateFormat("MM/dd/yy HH:mm");
        deliveryDate = inputFormat.tryParse(line.text);
        deliveryNext = false;
      }
      if (remarkNext) {
        remarks = line.text;
        remarkNext = false;
      }
      if (deliveredNext) {
        deliveredBy = line.text;
        deliveredNext = false;
      }
      if (line.text.toLowerCase().contains("date of")) {
        deliveryNext = true;
        continue;
      }
      if (line.text.toLowerCase().contains("remark")) {
        remarkNext = true;
        continue;
      }
      if (line.text.toLowerCase().contains("delivered")) {
        deliveredNext = true;
      }
      if (line.text.toLowerCase().contains('bill id')) {
        billId = line.text.split(':')[1];
      }
      if (line.text.toLowerCase().contains('bill num')) {
        billNum = line.text.split(':')[1];
      }
      if (line.text.toLowerCase().contains('printed b')) {
        printedBy = line.text.split(':')[1];
      }
      if (line.text.toLowerCase().contains('printed on')) {
        printDate = inputFormat.tryParse(
          line.text.split(':')[1].replaceAll(' ', ''),
        );
      }
    }

    return Slip(
      billNum: billNum,
      billId: billId,
      deliveredBy: deliveredBy,
      printedBy: printedBy,
      printDate: printDate,
      deliveryDate: deliveryDate,
      remarks: remarks,
    );
  }

  /// Processes an image file and returns a list of validated tracking numbers.
  Future<List<String>> extractFromImage(File imageFile) async {
    final ocr = PlatformOcr();
    if (!await imageFile.exists()) {
      return [];
    }

    final result = await ocr.recognizeText(OcrSource.file(imageFile));
    final List<String> validTrackingNumbers = [];

    // Regex looking for boundaries containing exactly 22 or 30 digits
    final RegExp trackingRegex = RegExp(r'\b\d{22}\b|\b\d{30}\b');
    for (final line in result.lines) {
      if (line.text.contains("ACCOUNTABLE MAIL") ||
          line.text.contains("OUTGOING MANIFEST") ||
          line.text.contains("Page Number") ||
          line.text.contains("Origin") ||
          line.text.contains("Automated") ||
          line.text.contains("ACCOUNTABLE") ||
          line.text.contains("Mail for: KFAB") ||
          line.text.contains("Item Number") ||
          line.text.contains("A total of") ||
          line.text.contains("were received") ||
          line.text.contains("Bill Type") ||
          line.text.contains("Received By") ||
          line.text.contains("nature of Addressee") ||
          line.text.contains("Delivery Office")) {
        continue;
      }
      // Remove spaces from the line in case the OCR split the barcode digits
      final cleanLine = line.text.replaceAll(' ', '');
      final matches = trackingRegex.allMatches(cleanLine);

      //final numericLine = normalizeOcrDigits(cleanLine);
      String mergedDigits = cleanLine.replaceAll(RegExp(r"\D"), "");
      bool foundNumeric = false;

      // ==========================================
      // PASS 1: USPS NUMERIC TRACKING
      // ==========================================
      final RegExp prefix = RegExp(r'^(420|427)\d{5}');
      String coreTracking;
      //print(mergedDigits);
      if (prefix.hasMatch(mergedDigits)) {
        coreTracking = mergedDigits.substring(8);
      } else {
        coreTracking = mergedDigits;
      }

      if (coreTracking.length == 22 && _isValidModulo10(coreTracking)) {
        foundNumeric = true;
        validTrackingNumbers.add(coreTracking);
        continue;
      }

      // ==========================================
      // PASS 2: ALPHANUMERIC TRACKING (UPS / eVS)
      // ==========================================
      if (!foundNumeric) {
        final tokenizedString = cleanLine.replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          ' ',
        );
        final words = tokenizedString.split(' ');
        final RegExp ups1ZRegex = RegExp(
          r'^1Z[0-9A-Z]{15}\d$',
          caseSensitive: false,
        );
        for (final word in words) {
          if (word.length == 18 && ups1ZRegex.hasMatch(word)) {
            //yep, definitely a UPS tracking number
          } else if (word.length >= 10 &&
              RegExp(r'^[A-Z0-9]+$').hasMatch(word) &&
              RegExp(r'[A-Z]').hasMatch(word) &&
              RegExp(r'[0-9]').hasMatch(word) &&
              word != 'NC') {
            foundNumeric = true;
            validTrackingNumbers.add(word);
          }
        }
      }

      for (final match in matches) {
        final String? possibleNumber = match.group(0);

        if (possibleNumber != null && _isValidModulo10(possibleNumber)) {
          // Avoid adding duplicates if the same number is read twice on a label
          if (!validTrackingNumbers.contains(possibleNumber)) {
            validTrackingNumbers.add(possibleNumber);
          }
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
    // You can add or remove these based on the specific quirks of your printed documents.
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
