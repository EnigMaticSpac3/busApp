// lib/screens/home_screen.dart
//
// Pantalla principal con NavigationBar para cambiar entre Mapa y Rutas.

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'map_screen.dart';
import 'rutas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final List<Widget> _tabs = const [
    MapScreen(),
    RutasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppConfig.colorPrimary,
        indicatorColor: AppConfig.colorAccent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.map, color: AppConfig.colorPrimary),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.directions_bus, color: AppConfig.colorPrimary),
            label: 'Rutas',
          ),
        ],
      ),
    );
  }
}