import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mail_sort/core/data/import_record.dart';
//import 'package:mail_sort/core/data/scan.dart';
import 'package:mail_sort/features/import_export/data/importer.dart';
import 'package:hive/hive.dart';
import 'package:mail_sort/core/data/package.dart';

/// Page for selecting PDFs to import into MailSort and exporting managed files.
///
/// Connect [_importPdf] and [_exportPdf] to the application's file service when
/// a file picker/storage implementation is available.
class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  final List<ImportRecord> _files = <ImportRecord>[];

  late Box<Package> _packageBox;
  late Box<ImportRecord> _importBox;

  @override
  void initState() {
    super.initState();
    _packageBox = Hive.box<Package>('packageBox');
    _importBox = Hive.box<ImportRecord>('importBox');
  }

  Future<void> _handleImport(BuildContext context) async {
    final importService = PdfImportService();

    final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);
    final ValueNotifier<String> statusNotifier = ValueNotifier<String>(
      'Preparing...',
    );

    // 1. Show the non-dismissible modal dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false, // Prevent back button dismissal during processing
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Importing PDF Bills',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar updates reactively
                  ValueListenableBuilder<double>(
                    valueListenable: progressNotifier,
                    builder: (context, progress, _) {
                      return LinearProgressIndicator(
                        value: progress > 0
                            ? progress
                            : null, // Indeterminate until reading starts
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Status Text updates reactively
                  ValueListenableBuilder<String>(
                    valueListenable: statusNotifier,
                    builder: (context, status, _) {
                      return Text(
                        status,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 2. Run the pipeline
    final int? importedCount = await importService.executeImportPipeline(
      packageBox: _packageBox,
      onProgress: (progress, status) {
        progressNotifier.value = progress;
        statusNotifier.value = status;
      },
      onFilePicked: (PlatformFile file) async {
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

        final matchedImport = _importBox.values
            .cast<ImportRecord?>()
            .firstWhere((p) => p?.filePath == file.path, orElse: () => null);

        setState(() {
          if (matchedImport == null) {
            _importBox.add(pdf);
            _files.insert(0, pdf);
          }
        });
        return pdf;
      },
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();

      if (importedCount != null) {
        if (importedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully imported $importedCount new packages.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import cancelled or no tracking numbers found.',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.yellow,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _exportPdf() async {
    //final fileName = DateTime.now().toIso8601String().replaceAll(':', '-');

    if (_packageBox.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No packages found. Aborting PDF generation.',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // call the exporter
    //TODO: call pdf export here as well, since this is the page where we manage PDFs
    // not sure how I want to do that yet, but the button in the header of the scan page will work for now
  }

  void _removePdf(ImportRecord file) {
    setState(() {
      _files.remove(file);
      file.delete();
    });
    String billNum = file.fileName.substring(0, file.fileName.length - 4);
    final keysToDelete = _packageBox
        .toMap()
        .entries
        .where((entry) => entry.value.slipNum == billNum)
        .map((entry) => entry.key)
        .toList();
    _packageBox.deleteAll(keysToDelete);
  }

  @override
  Widget build(BuildContext context) {
    for (ImportRecord file in _importBox.values) {
      if (!_files.contains(file)) _files.add(file);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Managed PDFs'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (_files.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.builder(
                  itemCount: _files.length,
                  itemBuilder: (BuildContext context, int index) {
                    final file = _files[index];
                    return _PdfTile(
                      file: file,
                      onExport: () => _exportPdf(),
                      onDelete: () => _removePdf(file),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _handleImport(context);
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Import PDF'),
      ),
    );
  }
}

class _PdfTile extends StatelessWidget {
  const _PdfTile({
    required this.file,
    required this.onExport,
    required this.onDelete,
  });
  final ImportRecord file;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.picture_as_pdf)),
      title: Text(file.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(file.fileSize),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => value == 'export' ? onExport() : onDelete(),
        itemBuilder: (_) => const <PopupMenuEntry<String>>[
          PopupMenuItem(value: 'export', child: Text('Export')),
          PopupMenuItem(value: 'delete', child: Text('Remove')),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.folder_copy_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 14),
          const Text(
            'No PDFs yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text('Imported files will appear here.'),
        ],
      ),
    ),
  );
}
