import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/import_record.dart';
import 'package:mail_sort/core/data/package.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Box<Package> _packageBox;
  late Box<ImportRecord> _importBox;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _packageBox = Hive.box<Package>('packageBox');
    _importBox = Hive.box<ImportRecord>('importBox');
    _settingsBox = Hive.box('settingsBox');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [
          
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _packageBox.listenable(),
        builder: (context, Box<Package> box, _) {
          final allPackages = box.values.toList();

          // Sort by most recent activity (newest first)
          allPackages.sort((a, b) {
            final DateTime aTime = a.lastUpdated ?? a.timeImported;
            final DateTime bTime = b.lastUpdated ?? b.timeImported;

            return bTime.compareTo(aTime);
          });
          final recentActivity = allPackages.take(15).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              /*if (constraints.maxWidth > 800) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildListColumn(
                            'Waiting to be Scanned',
                            pending,
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: _buildListColumn(
                            'Successfully Scanned',
                            scanned,
                          ),
                        ),
                      ],
                    );
                  }*/
              return Column(
                children: [
                  _buildDashboardTiles(allPackages),
                  Expanded(child: _buildUnifiedList(recentActivity)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDashboardTiles(List<Package> items) {
    final importedPackages = items
        .where(
          (p) =>
              p.slipNum != '0' &&
              p.slipNum != _settingsBox.get('defaultBillNum') &&
              p.slipNum != 'Unknown',
        )
        .toList();
    final totalImported = importedPackages.length;
    final uniqueSlips = _importBox.length;
    final totalScanned = items.where((p) => p.isScanned).length;
    final sliplessCount = items
        .where(
          (p) =>
              p.slipNum == '0' ||
              p.slipNum == _settingsBox.get('defaultBillNum') ||
              p.slipNum == 'Unknown',
        )
        .length;
    final totalPackages = items.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Column(
                children: [
                  Text("Bills\nImported"),
                  Text(textScaler: TextScaler.linear(2), "$uniqueSlips"),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Column(
                children: [
                  Center(child: Text("Tracking Numbers\n      Imported")),
                  Text(textScaler: TextScaler.linear(2), "$totalImported"),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Column(
                children: [
                  Text("Packages\nScanned"),
                  Text(
                    textScaler: TextScaler.linear(2),
                    "$totalScanned/$totalPackages",
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Column(
                children: [
                  Text("Bill-less\nPackages"),
                  Text(textScaler: TextScaler.linear(2), "$sliplessCount"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedList(List<Package> items) {
    if (items.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),

            // The List
            // Wrapped in Expanded so it scrolls properly within the Card
            Expanded(
              child: Center(child: Text('No packages imported or scanned.')),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),

          // The List
          // Wrapped in Expanded so it scrolls properly within the Card
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildPackage(items[index]);
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackage(Package package) {
    final timeFormatted =
        "${package.timeImported.hour}:${package.timeImported.minute.toString().padLeft(2, '0')} on ${package.timeImported.month}/${package.timeImported.day}";

    return ListTile(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: package.trackingNum));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied ${package.trackingNum} to clipboard'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      leading: Icon(
        package.isScanned ? Icons.check_circle : Icons.pending_actions,
        color: package.isScanned ? Colors.green : Colors.orange,
      ),
      title: Text(
        package.trackingNum
            .replaceAllMapped(
              RegExp(r'.{1,4}'),
              (match) => '${match.group(0)} ',
            )
            .trim(),
        style: const TextStyle(fontFamily: 'Monospace'),
      ),
      subtitle: Text(
        package.isScanned
            ? 'Scanned: $timeFormatted'
            : 'Imported: $timeFormatted (Bill: ${package.slipNum})',
      ),
      trailing: Chip(
        label: Text(package.packageType),
        backgroundColor: switch (package.packageType) {
          'Army' => Colors.green.withValues(alpha: 0.1),
          'Air Force' => Colors.lightBlue.withValues(alpha: 0.1),
          'Navy' => Colors.blue.withValues(alpha: 0.1),
          _ => Colors.red.withValues(alpha: 0.1),
        },
      ),
    );
  }
}
