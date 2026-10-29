import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/import_record.dart';
import '../data/package.dart';
import '../data/slip.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box _settingsBox;
  late Box<Package> _packageBox;
  late Box<ImportRecord> _importBox;
  late Box<Slip> _slipBox;
  String _defaultBranch = 'Army';
  String _defaultBillId = 'Unknown';
  String _defaultBillNum = 'Unknown';
  String _defaultDeliverer = 'Unknown';
  String _defaultPrinter = 'Unknown';
  String _signerName = 'Unknown';
  bool _isDarkModeEnabled = false; // New state variable for dark mode

  @override
  void initState() {
    super.initState();
    // Initialize the settings box
    _settingsBox = Hive.box(HiveBoxes.settings);
    _packageBox = Hive.box(HiveBoxes.packages);
    _importBox = Hive.box(HiveBoxes.imports);
    _slipBox = Hive.box(HiveBoxes.slips);

    _isDarkModeEnabled = _settingsBox.get(
      SettingsKeys.darkMode,
      defaultValue: false,
    );

    // Load the saved default branch, defaulting to 'Standard' if not yet set
    _defaultBranch = _settingsBox.get(
      SettingsKeys.branch,
      defaultValue: 'Army',
    );
    _defaultBillId = _settingsBox.get(
      SettingsKeys.billId,
      defaultValue: 'Unknown',
    );
    _defaultBillNum = _settingsBox.get(
      SettingsKeys.billNum,
      defaultValue: 'Unknown',
    );
    _defaultDeliverer = _settingsBox.get(
      SettingsKeys.deliverer,
      defaultValue: 'Unknown',
    );
    _defaultPrinter = _settingsBox.get(
      SettingsKeys.printer,
      defaultValue: 'Unknown',
    );
    _signerName = _settingsBox.get(
      SettingsKeys.signer,
      defaultValue: 'Unknown',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Assignment Defaults Section ---
            const Text(
              'Application Defaults',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Default Package Branch'),
              subtitle: const Text(
                'Assigned automatically to newly imported packages.',
              ),
              trailing: DropdownButton<String>(
                value: _defaultBranch,
                icon: const Icon(Icons.arrow_drop_down),
                elevation: 16,
                style: const TextStyle(color: Colors.blueAccent),
                underline: Container(height: 2, color: Colors.blueAccent),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _defaultBranch) {
                    setState(() {
                      _defaultBranch = newValue;
                      _settingsBox.put('packageBranch', newValue);
                    });
                  }
                },
                items: <String>['Army', 'Air Force', 'Navy', 'Marines']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
              ),
            ),
            ListTile(
              title: const Text('Default Bill Number'),
              subtitle: const Text(
                'Used for packages scanned but not imported.',
              ),
              trailing: SizedBox(
                width:
                    180, // Constrains the text field so it fits nicely on the right
                child: TextFormField(
                  initialValue: _defaultBillNum, // Uses your state variable
                  style: const TextStyle(color: Colors.blueAccent),
                  decoration: const InputDecoration(
                    isDense: true, // Keeps the text field compact
                    hintText: 'Bill Number',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (String newValue) {
                    // 1. Update the correct state variable
                    setState(() {
                      _defaultBillNum = newValue;
                    });

                    // 2. Save to the correct Hive key
                    _settingsBox.put('defaultBillNum', newValue);
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Default Bill ID'),
              subtitle: const Text(
                'USed for packages scanned but not imported.',
              ),
              trailing: SizedBox(
                width:
                    180, // Constrains the text field so it fits nicely on the right
                child: TextFormField(
                  initialValue: _defaultBillId, // Uses your state variable
                  style: const TextStyle(color: Colors.blueAccent),
                  decoration: const InputDecoration(
                    isDense: true, // Keeps the text field compact
                    hintText: 'Bill ID',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (String newValue) {
                    // 1. Update the correct state variable
                    setState(() {
                      _defaultBillId = newValue;
                    });

                    // 2. Save to the correct Hive key
                    _settingsBox.put(SettingsKeys.billId, newValue);
                  },
                ),
              ),
            ),

            ListTile(
              title: const Text('Default Deliverer'),
              subtitle: const Text(
                'Name of the person shown near "delivered by" on a bill for packages scanned but not imported.',
              ),
              trailing: SizedBox(
                width:
                    180, // Constrains the text field so it fits nicely on the right
                child: TextFormField(
                  initialValue: _defaultDeliverer, // Uses your state variable
                  style: const TextStyle(color: Colors.blueAccent),
                  decoration: const InputDecoration(
                    isDense: true, // Keeps the text field compact
                    hintText: 'Enter Deliverer Name',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (String newValue) {
                    // 1. Update the correct state variable
                    setState(() {
                      _defaultDeliverer = newValue;
                    });

                    // 2. Save to the correct Hive key
                    _settingsBox.put(SettingsKeys.deliverer, newValue);
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Default Printer'),
              subtitle: const Text(
                'Name of the person shown near "printed by" on a bill for packages scanned but not imported.',
              ),
              trailing: SizedBox(
                width: 180,
                child: TextFormField(
                  initialValue: _defaultPrinter,
                  style: const TextStyle(color: Colors.blueAccent),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Enter Printer Name',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (String newValue) {
                    setState(() {
                      _defaultPrinter = newValue;
                    });

                    _settingsBox.put(SettingsKeys.printer, newValue);
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Delivery Signature'),
              subtitle: const Text(
                'Name of the person signing for the scanned packages.',
              ),
              trailing: SizedBox(
                width: 180,
                child: TextFormField(
                  initialValue: _signerName,
                  style: const TextStyle(color: Colors.blueAccent),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Signer Name',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (String newValue) {
                    setState(() {
                      _signerName = newValue;
                    });

                    _settingsBox.put(SettingsKeys.signer, newValue);
                  },
                ),
              ),
            ),

            const Divider(height: 32),

            // --- Debug / Maintenance Section ---
            const Text(
              'Maintenance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Clear All Database Records'),
              subtitle: const Text(
                'Permanently deletes all packages, scans, and imports.',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                tooltip: 'Clear All Packages',
                onPressed: () => _showClearConfirmation(context),
              ),
            ),
            ListTile(
              title: const Text('Backup app state'),
              subtitle: const Text(
                'Exports all packages, scans, and imports, Hive boxes, and settings to a custom file for backup.',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                tooltip: 'Export app state to .mailsort file',
                onPressed: () => _backupAppState(),
              ),
            ),
            ListTile(
              title: const Text('Restore app state from backup'),
              subtitle: const Text(
                'Select a .mailsort backup file and the app will load its entire state from the backup.',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.upload, color: Colors.blue),
                tooltip: 'Import .mailsort backup',
                onPressed: () => _restoreAppState(),
              ),
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark mode'),
              value: _isDarkModeEnabled,
              onChanged: (bool newValue) {
                setState(() {
                  _isDarkModeEnabled = newValue;
                });
                _settingsBox.put(SettingsKeys.darkMode, newValue);
              },
            ),

            const Divider(height: 32),

            // --- About / Credits Section ---
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Info & Credits'),
              subtitle: Text('Version ${AppConstants.appVersion}'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.appVersion,
                  applicationLegalese: AppConstants.appLegalese,
                  applicationIcon: const Icon(
                    Icons.mark_email_read,
                    size: 48,
                    color: Colors.blueAccent,
                  ),
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      AppConstants.appAbout,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<File> _backupAppState() async {
    final Map<String, dynamic> fullBackup = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'appName': 'MailSort',
      'boxes': {
        // Serializing lists of HiveObjects using their .toJson() methods
        'packageBox': _packageBox.values.map((p) => p.toJson()).toList(),
        'slipBox': _slipBox.values.map((s) => s.toJson()).toList(),
        'importBox': _importBox.values.map((i) => i.toJson()).toList(),
        'settingsBox': Map<String, dynamic>.from(_settingsBox.toMap()),
      },
    };
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(fullBackup);

    Directory docsDir = await getApplicationDocumentsDirectory();
    // Create a dedicated subfolder for your data
    final Directory appDir = Directory('${docsDir.path}\\MailSort');
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File backupFile = File('${appDir.path}\\backup_$timestamp.mailsort');

    await backupFile.writeAsString(jsonString);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported app backup to file: ${backupFile.path}'),
        ),
      );
    }
    return backupFile;
  }

  Future<void> handleBackupExport(BuildContext context) async {
    final File backupFile = await _backupAppState();

    if (await backupFile.exists()) {
      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(backupFile.path, mimeType: 'application/json')],
            text: 'MailSort Database Backup',
          ), // Optional message for emails/messages
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App backup created at: ${backupFile.path}')),
        );
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate backup.')),
      );
    }
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all Hive boxes. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Hive.box<Package>(HiveBoxes.packages).clear();
      await Hive.box<ImportRecord>(HiveBoxes.imports).clear();
      await Hive.box<Slip>(HiveBoxes.slips).clear();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hive boxes cleared!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<bool> _restoreAppState() async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mailsort', 'json'],
        dialogTitle: 'Select MailSort Backup',
      );

      if (result.isEmpty || result.single.path == null) return false;
      File backupFile = File(result.single.path!);
      final String contents = await backupFile.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(contents);

      final Map<String, dynamic> boxes = backupData['boxes'];

      // 1. Restore Packages
      await _packageBox.clear();
      final List packageList = boxes[HiveBoxes.packages] ?? [];
      for (var item in packageList) {
        await _packageBox.add(
          Package.fromJson(Map<String, dynamic>.from(item)),
        );
      }

      // 2. Restore Slips
      await _slipBox.clear();
      final List slipList = boxes[HiveBoxes.slips] ?? [];
      for (var item in slipList) {
        await _slipBox.add(Slip.fromJson(Map<String, dynamic>.from(item)));
      }

      // 3. Restore Imports
      await _importBox.clear();
      final List importList = boxes[HiveBoxes.imports] ?? [];
      for (var item in importList) {
        await _importBox.add(
          ImportRecord.fromJson(Map<String, dynamic>.from(item)),
        );
      }

      // 4. Restore Settings
      await _settingsBox.clear();
      final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(
        boxes[HiveBoxes.settings] ?? {},
      );
      await _settingsBox.putAll(settingsMap);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import successful! Imported ${packageList.length} packages.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Failed to restore backup: $e');
      return false;
    }
  }
}
