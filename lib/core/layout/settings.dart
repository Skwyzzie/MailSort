import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  bool _isDarkModeEnabled = false; // New state variable for dark mode

  @override
  void initState() {
    super.initState();
    // Initialize the settings box
    _settingsBox = Hive.box('settingsBox');
    _packageBox = Hive.box('packageBox');
    _importBox = Hive.box('importBox');
    _slipBox = Hive.box('slipBox');

    _isDarkModeEnabled = _settingsBox.get('darkMode', defaultValue: false);

    // Load the saved default branch, defaulting to 'Standard' if not yet set
    _defaultBranch = _settingsBox.get('packageBranch', defaultValue: 'Army');
    _defaultBillId = _settingsBox.get('defaultBillId', defaultValue: 'Unknown');
    _defaultBillNum = _settingsBox.get(
      'defaultBillNum',
      defaultValue: 'Unknown',
    );
    _defaultDeliverer = _settingsBox.get(
      'defaultDeliverer',
      defaultValue: 'Unknown',
    );
    _defaultPrinter = _settingsBox.get(
      'defaultPrinter',
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
                    _settingsBox.put('defaultBillId', newValue);
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
                    _settingsBox.put('defaultDeliverer', newValue);
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
                width:
                    180, // Constrains the text field so it fits nicely on the right
                child: TextFormField(
                  initialValue: _defaultPrinter, // Uses your state variable
                  style: const TextStyle(color: Colors.blueAccent),
                  decoration: const InputDecoration(
                    isDense: true, // Keeps the text field compact
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
                    // 1. Update the correct state variable
                    setState(() {
                      _defaultPrinter = newValue;
                    });

                    // 2. Save to the correct Hive key
                    _settingsBox.put('defaultPrinter', newValue);
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
              title: const Text('Export Database Records to JSON'),
              subtitle: const Text(
                'Exports all packages, scans, and imports as a JSON file.',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                tooltip: 'Debug: Export Database to JSON',
                onPressed: () => _exportHiveBoxes(),
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
                _settingsBox.put('darkMode', newValue);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportHiveBoxes() async {
    final fileName = DateTime.now().toIso8601String().replaceAll(':', '-');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting JSON files ending in $fileName…')),
    );
    final pBoxMap = _packageBox.toMap().map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    );
    final iBoxMap = _importBox.toMap().map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    );
    final sBoxMap = _slipBox.toMap().map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    );
    final pJson = jsonEncode(pBoxMap);
    final iJson = jsonEncode(iBoxMap);
    final sJson = jsonEncode(sBoxMap);
    File('packages_$fileName.json').writeAsString(pJson);
    File('imports_$fileName.json').writeAsString(iJson);
    File('slips_$fileName.json').writeAsString(sJson);
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
      await Hive.box<Package>('packageBox').clear();
      await Hive.box<ImportRecord>('importBox').clear();
      await Hive.box<Slip>('slipBox').clear();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hive boxes cleared!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
