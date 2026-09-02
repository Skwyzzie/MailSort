import 'package:flutter/material.dart';
import 'package:mail_sort/core/data/package.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:hive_flutter/hive_flutter.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MailSortShell extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const MailSortShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<MailSortShell> createState() => _MailSortShellState();
}

class _MailSortShellState extends State<MailSortShell> {
  late Box<Package> _packageBox;

  @override
  void initState() {
    super.initState();
    _packageBox = Hive.box<Package>('packageBox');
  }

  void _onGlobalBarcodeScanned(String barcode) {
    if (barcode.length < 10) {
      return;
    }
    String trackingNum = barcode.substring(8);

    final matchedPackage = _packageBox.values.cast<Package?>().firstWhere(
      (p) => p?.trackingNum == trackingNum,
      orElse: () => null,
    );

    if (matchedPackage != null) {
      matchedPackage.isScanned = true;
      matchedPackage.lastUpdated = DateTime.now();
      matchedPackage.save();
      _showSnackbar('Matched & updated pending package: $trackingNum');
    } else {
      _packageBox.add(
        Package(
          trackingNum: trackingNum,
          slipNum: '0',
          isAF: false,
          timeImported: DateTime.now(),
          lastUpdated: DateTime.now(),
          isScanned: true,
          file: null,
        ),
      );
      _showSnackbar('Added new scanned package: $trackingNum');
    }
  }

  // Helper method using the global key
  void _showSnackbar(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. Wrap the persistent shell in the BarcodeKeyboardListener
    return BarcodeKeyboardListener(
      onBarcodeScanned: _onGlobalBarcodeScanned,
      bufferDuration: const Duration(milliseconds: 200),
      useKeyDownEvent: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Mobile Layout: Bottom Navigation
          if (constraints.maxWidth < 600) {
            return Scaffold(
              body: widget.child, // Feature content goes here
              bottomNavigationBar: NavigationBar(
                selectedIndex: widget.selectedIndex,
                onDestinationSelected: widget.onDestinationSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.qr_code_scanner),
                    label: 'Scan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.picture_as_pdf),
                    label: 'PDFs',
                  ),
                ],
              ),
            );
          }

          final bool isExtended = constraints.maxWidth >= 900;

          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: widget.onDestinationSelected,
                  extended: isExtended,
                  // FIX: If extended is true, labelType MUST be none (or null).
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.qr_code_scanner),
                      label: Text('Scanner'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.picture_as_pdf),
                      label: Text('Manage PDFs'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: widget.child),
              ],
            ),
          );
        },
      ),
    );
  }
}
