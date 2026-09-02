import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/data/import_record.dart';
import 'core/data/package.dart';
import 'core/data/scan.dart';
import 'core/data/slip.dart';
import 'core/layout/app_shell.dart';

import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PackageAdapter());
  Hive.registerAdapter(ScanAdapter());
  Hive.registerAdapter(SlipAdapter());
  Hive.registerAdapter(ImportRecordAdapter());
  /* DEBUG: IN CASE OF DATA MODIFICATION
  await Hive.deleteBoxFromDisk('packageBox');
  await Hive.deleteBoxFromDisk('scanBox');
  await Hive.deleteBoxFromDisk('slipBox');
  await Hive.deleteBoxFromDisk('importBox');
  // */
  await Hive.openBox<Package>('packageBox');
  await Hive.openBox<Scan>('scanBox');
  await Hive.openBox<Slip>('slipBox');
  await Hive.openBox<ImportRecord>('importBox');
  await Hive.openBox('settingsBox');

  runApp(const MailSortApp());
}

class MailSortApp extends StatelessWidget {
  const MailSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      //debugShowCheckedModeBanner: false,
      home: MailSort(),
    );
  }
}

class MailSort extends StatefulWidget {
  const MailSort({super.key});

  @override
  State<MailSort> createState() => _MailSortState();
}

class _MailSortState extends State<MailSort> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'KFAB MailSort',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // Pass the router instance from app_router.dart
      routerConfig: appRouter,
    );
  }
}
