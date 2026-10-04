import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/data/import_record.dart';
import 'core/data/package.dart';
import 'core/data/slip.dart';
import 'core/layout/app_shell.dart';

import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PackageAdapter());
  Hive.registerAdapter(SlipAdapter());
  Hive.registerAdapter(ImportRecordAdapter());

  await Hive.openBox<Package>('packageBox');
  await Hive.openBox<Slip>('slipBox');
  await Hive.openBox<ImportRecord>('importBox');
  await Hive.openBox('settingsBox');

  runApp(const MailSortApp());
}

class MailSortApp extends StatelessWidget {
  const MailSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MailSort());
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
    return ValueListenableBuilder(
      valueListenable: Hive.box('settingsBox').listenable(keys: ['darkMode']),
      builder: (context, Box box, _) {
        bool isDarkMode = box.get('darkMode', defaultValue: false);
        return MaterialApp.router(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'MailSort',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          /*
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark Material background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
      ),
      */
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
        );
      },
    );
  }
}
