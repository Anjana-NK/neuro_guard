import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/intake_flow.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const NeuroGuardApp());
}

class NeuroGuardApp extends StatelessWidget {
  const NeuroGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neuro Guard',
      debugShowCheckedModeBanner: false,
      theme: CosmicTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/intake': (context) => const IntakeFlowScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
