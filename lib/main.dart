import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mail_sort/core/data/constants.dart';
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

  await Hive.openBox<Package>(HiveBoxes.packages);
  await Hive.openBox<Slip>(HiveBoxes.slips);
  await Hive.openBox<ImportRecord>(HiveBoxes.imports);
  await Hive.openBox(HiveBoxes.settings);

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
      valueListenable: Hive.box(
        HiveBoxes.settings,
      ).listenable(keys: [SettingsKeys.darkMode]),
      builder: (context, Box box, _) {
        bool isDarkMode = box.get(SettingsKeys.darkMode, defaultValue: false);
        return MaterialApp.router(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: AppConstants.appName,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
        );
      },
    );
  }
}
