/// Centralized names for persistent storage and app-wide values.
///
/// Keep Hive box names and keys stable to preserve access to existing data.
library;

import 'package:package_info_plus/package_info_plus.dart';

abstract final class HiveBoxes {
  static const String settings = 'settingsBox';
  static const String packages = 'packageBox';
  static const String imports = 'importBox';
  static const String slips = 'slipBox';
}

abstract final class SettingsKeys {
  static const String billNum = 'defaultBillNum';
  static const String billId = 'defaultBillId';
  static const String deliverer = 'defaultDeliverer';
  static const String printer = 'defaultPrinter';
  static const String signer = 'signerName';
  static const String branch = 'packageBranch';
  static const String darkMode = 'darkMode';
  static const String column = 'sortColumnIndex';
  static const String sort = 'sortAscending';
  static const int packagesPerPage = 50;
}

abstract final class LayoutKeys {
  static const double desktopMinimum = 800;
}

abstract class AppConstants {
  static String appName = '';
  static String appVersion = '';
  static String buildNumber = '';

  static const String appLegalese =
      'Designed and Developed by Third Echo Labs (TSgt Kerry Hackert, 386 ECES/128 CES). \n© 18 September 2026. All Rights Reserved.';
  static const String appAbout =
      'MailSort is a cross-platform mail sorting program built for forward operating locations and designed to work seamlessly with AMPS.';

  static Future<void> init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    appVersion = packageInfo.version;
    buildNumber = packageInfo.buildNumber; 
  }
}
