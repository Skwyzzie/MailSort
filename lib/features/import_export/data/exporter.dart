import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mail_sort/core/data/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/slip.dart';
import 'package:mail_sort/core/data/package.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  Future<Null> generatePackageSlip(BuildContext context) async {
    Box settings = Hive.box(HiveBoxes.settings);
    //Get all package and scan info first, then generate the slip containing all packages and whether they have been scanned or not.
    List<Package> packages = Hive.box<Package>(
      HiveBoxes.packages,
    ).values.toList();
    List<Slip> slips = Hive.box<Slip>(HiveBoxes.slips).values.toList();
    String generatedBillId =
        '${settings.get(SettingsKeys.billId, defaultValue: 'Unknown')}';
    String generatedBillNum =
        '${settings.get(SettingsKeys.billNum, defaultValue: 'Unknown')}';
    String signerName =
        '${settings.get(SettingsKeys.signer, defaultValue: 'Unknown')}';
    List<Package> sliplessPackages = packages
        .where(
          (package) =>
              package.slipNum == '0' || package.slipNum == generatedBillNum,
        )
        .toList();
    if (sliplessPackages.isNotEmpty) {
      // 1. Check if a slip with the default generatedBillNum already exists
      bool defaultSlipExists = slips.any((s) => s.billNum == generatedBillNum);

      if (!defaultSlipExists) {
        // Create a new slip for the slipless packages
        final newSlip = Slip(
          billId: generatedBillId,
          billNum: generatedBillNum,
          deliveryDate: DateTime.now(),
          deliveredBy:
              '${settings.get(SettingsKeys.deliverer, defaultValue: 'Unknown')}',
          printedBy:
              '${settings.get(SettingsKeys.printer, defaultValue: 'Unknown')}',
          remarks: 'Auto-generated for packages imported without a bill ID.',
          printDate: DateTime.now(),
          packageCount: sliplessPackages.length,
        );
        Hive.box<Slip>(HiveBoxes.slips).add(newSlip);
        slips.add(newSlip);

        for (Package pkg in sliplessPackages) {
          pkg.slipNum = generatedBillNum;
          pkg.save();
        }
      }
    }

    List<XFile> exportedFiles = [];

    for (Slip slip in slips) {
      final pdf = pw.Document();
      pw.Font();
      final ByteData imageBytes = await rootBundle.load(
        'assets/slip_template.png',
      );
      final Uint8List templateData = imageBytes.buffer.asUint8List();
      final pw.MemoryImage templateImage = pw.MemoryImage(templateData);

      final ByteData checkmarkBytes = await rootBundle.load('assets/check.png');
      final checkmarkImage = pw.MemoryImage(
        checkmarkBytes.buffer.asUint8List(),
      );

      //Find out how many packages are in the slip. divide by SettingsKeys.packagesPerPage (50) and round up to get the number of pages needed.
      int packageCount = packages
          .where((package) => package.slipNum == slip.billNum)
          .length;

      if (packageCount == 0) {
        // Skip generating a PDF for this slip if there are no packages associated with it
        continue;
      }
      int numPages = (packageCount / SettingsKeys.packagesPerPage).ceil();

      List<Package> packagesForSlip =
          packages.where((package) => package.slipNum == slip.billNum).toList()
            ..sort((a, b) => a.trackingNum.compareTo(b.trackingNum));

      for (int i = 0; i < numPages; i++) {
        List<Package> packagesForPage = packagesForSlip
            .skip(i * SettingsKeys.packagesPerPage)
            .take(SettingsKeys.packagesPerPage)
            .toList();
        bool lastItem = false;
        if (packagesForPage.length < SettingsKeys.packagesPerPage) {
          packagesForPage.add(
            Package(
              file: null,
              trackingNum: 'LASTITEM',
              slipNum: '',
              packageType: '',
              timeImported: DateTime.now(),
              isScanned: false,
            ),
          );
          lastItem = true;
        }
        // 2. Build the PDF page
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Image(templateImage, fit: pw.BoxFit.cover),
                  ),
                  // Fill in header information
                  // Bill Number
                  pw.Positioned(
                    left: 107,
                    top: 53.5,
                    child: pw.Text('${slip.billNum}'),
                  ),
                  // Bill ID
                  pw.Positioned(
                    left: 77,
                    top: 67,
                    child: pw.Text('${slip.billId}'),
                  ),
                  // Page Num
                  pw.Positioned(
                    //{"page":1,"x":247,"y":76
                    left: 247,
                    top: 75,
                    child: pw.Text('${i + 1} of $numPages'),
                  ),

                  ...packagesForPage.asMap().entries.map((p) {
                    if (packagesForPage.isEmpty) {
                      return pw.Container(); // Return an empty container if there are no packages
                    }

                    int index = p.key + 1;
                    double offset = 17.9;
                    double x = 0;

                    int rowMultiplier = index < 26 ? index : index - 25;
                    // "x":66, "y":140  // Package 1
                    // "x":345, "y":139 // Package 26
                    if (index < 26) {
                      x = 68.0;
                    } else {
                      x = 347.0;
                    }
                    return pw.Positioned(
                      left: x,
                      top: 122.0 + (rowMultiplier * offset),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            p.value.trackingNum
                                .replaceAllMapped(
                                  RegExp(r'.{1,4}'),
                                  (match) => '${match.group(0)} ',
                                )
                                .trim(),
                          ),
                          pw.SizedBox(width: 10),
                          if (p.value.isScanned) ...[
                            pw.Image(checkmarkImage, width: 15, height: 15),
                            pw.Text(p.value.packageType),
                          ],
                        ],
                      ),
                    );
                  }),

                  // Add the footer information
                  // articles
                  pw.Positioned(
                    left: 84,
                    top: 585,
                    child: pw.Text(
                      '${lastItem ? packagesForPage.length - 1 : packagesForPage.length}',
                    ),
                  ),
                  // date of delivery
                  pw.Positioned(
                    left: 42,
                    top: 632,
                    child: pw.Text('${slip.deliveryDate}'),
                  ),
                  // delivered by
                  pw.Positioned(
                    left: 247,
                    top: 668,
                    child: pw.Text('${slip.deliveredBy}'),
                  ),
                  // printed by
                  pw.Positioned(
                    left: 294,
                    top: 689,
                    child: pw.Text('${slip.printedBy}'),
                  ),
                  // remarks
                  pw.Positioned(
                    left: 42,
                    top: 722,
                    child: pw.Text('${slip.remarks}'),
                  ),
                  // printed on
                  pw.Positioned(
                    left: 250,
                    top: 748,
                    child: pw.Text('${slip.printDate}'),
                  ),
                  pw.Positioned(
                    left: 247,
                    top: 614,
                    child: pw.Text(signerName),
                  ),
                ],
              );
            },
          ),
        );
      }

      // 6. Save to the device's temporary or documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final Directory appDir = Directory('${docsDir.path}\\MailSort');
      final Directory dateFolder = Directory(
        '${appDir.path}\\${DateTime.now().month.toString()}-${DateTime.now().day.toString()}',
      );
      if (!await dateFolder.exists()) {
        await dateFolder.create(recursive: true);
      }
      final File outputFile = File(
        '${dateFolder.path}\\${slip.billNum} - Markup.pdf',
      );

      await outputFile.writeAsBytes(await pdf.save());
      if (!exportedFiles.any((file) => file.path == outputFile.path)) {
        exportedFiles.add(XFile(outputFile.path));
      }
    }

    if (exportedFiles.isNotEmpty) {
      final docsDir = await getApplicationDocumentsDirectory();
      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: exportedFiles,
            text: 'Exported Manifest Slips',
          ), // Optional message for emails/messages
        );
      } else {
        if (context.mounted) {
          final Directory appDir = Directory('${docsDir.path}\\MailSort');
          final String dateFolder =
              '${DateTime.now().month.toString()} - ${DateTime.now().day.toString()}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDFs generated at: ${appDir.path}\\$dateFolder'),
            ),
          );
        }
      }
    }
  }
}
