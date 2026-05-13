// lib/main.dart

import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/conductor_login_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.colorPrimary),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/conductor-login': (context) => const ConductorLoginScreen(),
        '/conductor': (context) => const ConductorHomeScreen(), // Pendiente crear
      },
    );
  }
}

// Placeholder para pantalla de conductor (se creará en tarea posterior)
class ConductorHomeScreen extends StatelessWidget {
  const ConductorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Conductor'),
        backgroundColor: AppConfig.colorPrimary,
      ),
      body: const Center(child: Text('Pantalla de conductor - pendientes: UI conductor, Dead Man\'s Switch')),
    );
  }
}