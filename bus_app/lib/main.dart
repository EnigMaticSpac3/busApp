// lib/main.dart

import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';

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
      home: const HomeScreen(),
    );
  }
}