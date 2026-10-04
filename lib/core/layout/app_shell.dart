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
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _packageBox = Hive.box<Package>('packageBox');
    _settingsBox = Hive.box('settingsBox');
  }

  void _onGlobalBarcodeScanned(String barcode) {
    if (!isValidTrackingNumber(barcode)) {
      _showSnackbar('Invalid tracking number scanned: $barcode');
      return;
    }

    String trackingNum = '';
    if (barcode.startsWith('420')) {
      trackingNum = barcode.substring(8);
    } else {
      trackingNum = barcode;
    }

    var packageType = _settingsBox.get('packageBranch', defaultValue: 'Army');

    final matchedPackage = _packageBox.values.cast<Package?>().firstWhere(
      (p) => p?.trackingNum == trackingNum,
      orElse: () => null,
    );

    if (matchedPackage != null) {
      matchedPackage.isScanned = true;
      matchedPackage.lastUpdated = DateTime.now();
      if (matchedPackage.packageType != packageType) {
        matchedPackage.packageType = packageType;
      }
      matchedPackage.save();
      _showSnackbar('Matched & updated pending package: $trackingNum');
    } else {
      _packageBox.add(
        Package(
          trackingNum: trackingNum,
          slipNum: '0',
          packageType: packageType,
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
      SnackBar(content: Text(message), duration: Duration(seconds: 1)),
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
                  NavigationDestination(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
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
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
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

  bool isValidTrackingNumber(String scannedCode) {
    // Reject Unrepresentable/Control Characters (Corrupted 2D Scans & Fragments)
    // Rejects any string containing characters outside standard printable ASCII (e.g., ½, \uFFFD)
    if (scannedCode.contains(RegExp(r'[^\x20-\x7E]'))) {
      return false;
    }

    // Reject Short Routing Tags
    // Standard USPS/UPS/FedEx tracking numbers are > 10 characters.
    if (scannedCode.length <= 9) {
      return false;
    }

    // Reject Amazon FNSKU Inventory Labels
    // Amazon FNSKUs always start with 'X00' followed by exactly 7 alphanumeric characters.
    if (RegExp(
      r'^X00[A-Z0-9]{7}$',
      caseSensitive: false,
    ).hasMatch(scannedCode)) {
      return false;
    }

    // Reject Amazon Logistics (AMZL) Internal Codes
    // Matches anything starting with 'SP' followed by alphanumeric characters or underscores.
    if (RegExp(r'^SP[A-Z0-9_]+$', caseSensitive: false).hasMatch(scannedCode)) {
      return false;
    }

    // If it passes all blacklist checks, it is a clean string.
    // Return true, or pass it directly into your existing Modulo 10 validator here.
    return true;
  }
}
