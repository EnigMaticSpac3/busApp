// lib/screens/home_screen.dart
//
// Pantalla principal con NavigationBar para cambiar entre Mapa y Rutas.

import 'package:flutter/material.dart';
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
        backgroundColor: const Color(0xFF283C90),
        indicatorColor: const Color(0xFFC8D527),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.map, color: Color(0xFF283C90)),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.directions_bus, color: Color(0xFF283C90)),
            label: 'Rutas',
          ),
        ],
      ),
    );
  }
}