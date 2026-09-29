import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

/// Navigarea principală: paginile importante rămân mereu la un singur tap.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const DashboardScreen());
  }
}
