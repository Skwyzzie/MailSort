import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/package.dart';
import 'package:data_table_2/data_table_2.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late Box<Package> _packageBox;
  late Box _settingsBox;

  // 1. Add state variables for the search functionality
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late int _sortColumnIndex;
  late bool _sortAscending;

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
    final afText = package.isAF ? 'yes' : 'no';
    final matchesAF = afText.contains(lowerQuery);

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
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
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
          const DataColumn2(
            label: Text('Air Force Package?'),
            size: ColumnSize.S,
          ),
        ],
        rows: items.map((package) {
          final timeStr =
              "${package.timeImported.month}/${package.timeImported.day} ${package.timeImported.hour}:${package.timeImported.minute.toString().padLeft(2, '0')}";
          return DataRow2(
            cells: [
              DataCell(
                Icon(
                  package.isScanned ? Icons.check_circle : Icons.pending,
                  color: package.isScanned ? Colors.green : Colors.orange,
                ),
              ),
              DataCell(
                Text(
                  package.trackingNum,
                  style: const TextStyle(fontFamily: 'Monospace'),
                ),
              ),
              DataCell(Text(timeStr)),
              DataCell(Text(package.slipNum.toString())),
              DataCell(
                Checkbox(
                  value: package.isAF,
                  onChanged: (bool? newValue) {
                    if (newValue != null) {
                      package.isAF = newValue;
                      package
                          .save(); // Instantly saves to Hive and triggers UI rebuild
                    }
                  },
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

        return Card(
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
                      package.trackingNum,
                      style: const TextStyle(
                        fontFamily: 'Monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Icon(
                      package.isScanned ? Icons.check_circle : Icons.pending,
                      color: package.isScanned ? Colors.green : Colors.orange,
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
                    const Text('Air Force Package? '),
                    Checkbox(
                      value: package.isAF,
                      // Minimizes the padding around the checkbox for tighter layouts
                      visualDensity: VisualDensity.compact,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          package.isAF = newValue;
                          package.save();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
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
