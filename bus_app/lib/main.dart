// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF283C90)),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}