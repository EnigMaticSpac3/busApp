// lib/main.dart

import 'package:flutter/material.dart';
import 'theme/export.dart';
import 'screens/home_screen.dart';
import 'screens/conductor_login_screen.dart';
import 'screens/conductor_screen.dart';

void main() {
  runApp(const BusApp());
}

class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'San Antonio Bus Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/conductor-login': (context) => const ConductorLoginScreen(),
        '/conductor': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ConductorScreen(
            conductorToken: args?['conductorToken'] ?? '',
            nombreConductor: args?['nombreConductor'] ?? '',
            rutaAsignada: args?['rutaAsignada'] ?? '',
          );
        },
      },
    );
  }
}