import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/package.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:mail_sort/features/import_export/data/exporter.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late Box<Package> _packageBox;
  late Box _settingsBox;
  PdfExportService export = PdfExportService();

  // 1. Add state variables for the search functionality
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late int _sortColumnIndex;
  late bool _sortAscending;

  Timer? _debounce;
  DateTime? _inputStartTime;

  @override
  void initState() {
    super.initState();
    _packageBox = Hive.box<Package>('packageBox');
    _settingsBox = Hive.box('settingsBox');
    _sortColumnIndex = _settingsBox.get('sortColumnIndex', defaultValue: 0);
    _sortAscending = _settingsBox.get('sortAscending', defaultValue: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 2. Define the cross-field filtering logic
  bool _matchesQuery(Package package, String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    // Check String fields
    final matchesTracking = package.trackingNum.toLowerCase().contains(
      lowerQuery,
    );
    // Check Integer fields by converting to String
    final matchesSlip = package.slipNum.toString().contains(lowerQuery);
    // Check Boolean status fields by mapping them to their UI text equivalents
    final statusText = package.isScanned ? 'scanned' : 'pending';
    final matchesStatus = statusText.contains(lowerQuery);
    final branchText = package.packageType;
    final matchesAF = branchText.contains(lowerQuery);

    // If ANY of these fields match the user's query, return true to keep the item
    return matchesTracking || matchesSlip || matchesStatus || matchesAF;
  }

  @override
  Widget build(BuildContext context) {
    int packageCount = _packageBox.length;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tracking, slips, or status...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  if (value.length == 1) {
                    _inputStartTime = DateTime.now();
                  }

                  if (_debounce?.isActive ?? false) _debounce!.cancel();

                  _debounce = Timer(const Duration(milliseconds: 150), () {
                    if (_inputStartTime != null) {
                      final duration = DateTime.now().difference(
                        _inputStartTime!,
                      );

                      if (value.length > 10 && duration.inMilliseconds < 500) {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                        });
                        _searchController.clear();
                        _inputStartTime = null;

                        return;
                      }
                    }

                    setState(() {
                      _searchQuery = value;
                    });
                  });
                },
              )
            : Text('Complete Scan Table - ${packageCount.toString()} Packages'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  // Closing search: clear the query and controller
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  // Opening search
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.outbox),
            onPressed: () {
              //_exportHiveBoxes();
              export.generatePackageSlip(context);
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _packageBox.listenable(),
        builder: (context, Box<Package> box, _) {
          final allPackages = box.values.toList();

          final filteredPackages = allPackages
              .where((package) => _matchesQuery(package, _searchQuery))
              .toList();

          filteredPackages.sort((a, b) {
            int result = 0;

            switch (_sortColumnIndex) {
              case 1:
                result = compareNullable(a.trackingNum, b.trackingNum);
                break;
              case 2:
                result = compareNullable(a.lastUpdated, b.lastUpdated);
                break;
              case 3:
                result = compareNullable(a.slipNum, b.slipNum);
                break;
              default:
                result = compareNullable(a.timeImported, b.timeImported);
            }

            // Reverse the result if sorting descending
            return _sortAscending ? result : -result;
          });
          if (filteredPackages.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No results found for "$_searchQuery".'
                    : 'No packages in database.',
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildDesktopTable(
                  filteredPackages,
                  constraints.maxWidth,
                );
              }
              return _buildMobileList(filteredPackages);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManualEntrySheet(context),
        icon: const Icon(Icons.add_box),
        label: const Text('Add Manually'),
      ),
    );
  }

  // --- WIDE SCREENS: Data Table View ---
  Widget _buildDesktopTable(List<Package> items, double minWidth) {
    void onSort(int columnIndex, bool ascending) {
      setState(() {
        _sortColumnIndex = columnIndex;
        _sortAscending = ascending;
      });
      _settingsBox.put('sortColumnIndex', columnIndex);
      _settingsBox.put('sortAscending', ascending);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DataTable2(
        minWidth: 800,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        headingRowColor: WidgetStateProperty.resolveWith(
          (states) => Colors.grey.withValues(alpha: 0.1),
        ),
        columns: [
          const DataColumn2(label: Text('Status'), fixedWidth: 80),
          DataColumn2(
            label: Text('Tracking Number'),
            size: ColumnSize.L,
            onSort: onSort,
          ),
          DataColumn2(
            label: Text('Time Imported'),
            size: ColumnSize.M,
            onSort: onSort,
          ),
          DataColumn2(
            label: Text('Bill Number'),
            size: ColumnSize.S,
            onSort: onSort,
          ),
          const DataColumn2(label: Text('Branch'), size: ColumnSize.S),
        ],
        rows: items.map((package) {
          final timeStr =
              "${package.timeImported.month}/${package.timeImported.day} ${package.timeImported.hour}:${package.timeImported.minute.toString().padLeft(2, '0')}";
          return DataRow2(
            cells: [
              DataCell(
                IconButton(
                  icon: Icon(
                    package.isScanned ? Icons.check_circle : Icons.pending,
                    color: package.isScanned ? Colors.green : Colors.orange,
                    size: 32, // Slightly larger for mobile tap targets
                  ),
                  onPressed: () {
                    package.isScanned = !package.isScanned;
                    package.packageType = _settingsBox.get('packageBranch');
                    // 2. Commit the change to the Hive database
                    package.save();
                  },
                ),
              ),
              DataCell(
                Text(
                  package.trackingNum
                      .replaceAllMapped(
                        RegExp(r'.{1,4}'),
                        (match) => '${match.group(0)} ',
                      )
                      .trim(),
                  style: const TextStyle(fontFamily: 'Monospace'),
                ),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: package.trackingNum),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Copied ${package.trackingNum} to clipboard',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              DataCell(Text(timeStr)),
              DataCell(Text(package.slipNum.toString())),
              DataCell(
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: package.packageType,
                    isDense: true,
                    items: <String>['Army', 'Air Force', 'Navy', 'Marines']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != package.packageType) {
                        // Update the database and the lastUpdated timestamp
                        package.packageType = newValue;
                        package.lastUpdated = DateTime.now();
                        package.save();
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- NARROW SCREENS: Detailed List View ---
  Widget _buildMobileList(List<Package> items) {
    //_settingsBox.put('sortColumnIndex', 0);
    //_settingsBox.put('sortAscending', true);

    items.sort((a, b) => compareNullable(a.lastUpdated, b.lastUpdated));

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final package = items[index];
        final timeStr =
            "${package.timeImported.month}/${package.timeImported.day} ${package.timeImported.hour}:${package.timeImported.minute.toString().padLeft(2, '0')}";

        return GestureDetector(
          onTap: () async {
            // 1. Write the exact tracking string to the native clipboard
            await Clipboard.setData(ClipboardData(text: package.trackingNum));

            // 2. Provide visual feedback so the user knows it worked
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied ${package.trackingNum} to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        package.trackingNum
                            .replaceAllMapped(
                              RegExp(r'.{1,4}'),
                              (match) => '${match.group(0)} ',
                            )
                            .trim(),
                        style: const TextStyle(
                          fontFamily: 'Monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          package.isScanned
                              ? Icons.check_circle
                              : Icons.pending,
                          color: package.isScanned
                              ? Colors.green
                              : Colors.orange,
                          size: 32, // Slightly larger for mobile tap targets
                        ),
                        onPressed: () {
                          // 1. Update the UI locally
                          /*setState(() {
                          package.isScanned =
                              !package.isScanned; // Toggles the state
                        });*/
                          package.isScanned = !package.isScanned;
                          // 2. Commit the change to the Hive database
                          package.save();
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      package.isScanned
                          ? Text('Scanned: $timeStr')
                          : Text('Imported: $timeStr'),
                      Text('Slip: ${package.slipNum}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // NEW: Interactive Checkbox Row for Mobile
                  Row(
                    children: [
                      const Text('Package Branch: '),
                      DropdownButton<String>(
                        value: package.packageType,
                        icon: const Icon(Icons.arrow_drop_down),
                        elevation: 16,
                        style: const TextStyle(color: Colors.blueAccent),
                        underline: Container(
                          height: 2,
                          color: Colors.blueAccent,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null &&
                              newValue != package.packageType) {
                            package.packageType = newValue;
                            package.lastUpdated = DateTime.now();
                            package.save();
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showManualEntrySheet(BuildContext context) {
    final TextEditingController trackingController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to move up with the keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          // This padding ensures the keyboard doesn't cover the input field
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manual Package Entry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: trackingController,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                autofocus: true, // Pops the keyboard immediately
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final trackingNum = trackingController.text.trim();
                  trackingNum.replaceAll(' ', ''); // Remove spaces
                  if (trackingNum.isNotEmpty) {
                    // 1. Create the new package
                    final manualPackage = Package(
                      file: null, // No image associated
                      trackingNum: trackingNum,
                      slipNum: _settingsBox.get(
                        'defaultBillNum',
                        defaultValue: '0',
                      ), // Will be picked up by your PDF exporter
                      packageType: _settingsBox.get(
                        'packageBranch',
                        defaultValue: 'Army',
                      ),
                      timeImported: DateTime.now(),
                      isScanned: true,
                    );

                    // 2. Save to Hive
                    Hive.box<Package>('packageBox').add(manualPackage);

                    // 3. Close the bottom sheet
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Package'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  int compareNullable<T extends Comparable<T>>(T? a, T? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }
}
