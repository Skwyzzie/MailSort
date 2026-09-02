import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mail_sort/core/layout/app_shell.dart';

import 'package:mail_sort/features/dashboard/dashboard.dart';
import 'package:mail_sort/features/scanner/scanner.dart';
import 'package:mail_sort/features/import_export/import_export.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // Calculate the selected index based on the current URL
        int getSelectedIndex(String location) {
          if (location.startsWith('/scanner')) return 1;
          if (location.startsWith('/pdf')) return 2;
          return 0; // Default to dashboard
        }

        // Handle navigation clicks from the Shell (BottomNav or Rail)
        void onDestinationSelected(int index, BuildContext context) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/scanner');
              break;
            case 2:
              context.go('/pdf');
              break;
          }
        }

        return MailSortShell(
          selectedIndex: getSelectedIndex(state.uri.toString()),
          onDestinationSelected: (index) =>
              onDestinationSelected(index, context),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => DashboardPage(),
        ),
        GoRoute(path: '/scanner', builder: (context, state) => ScannerPage()),
        GoRoute(path: '/pdf', builder: (context, state) => ImportExportPage()),
      ],
    ),
  ],
);
