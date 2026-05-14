// lib/screens/home_screen.dart
//
// Pantalla principal con NavigationBar para cambiar entre Mapa y Rutas.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
  LatLng? _coordenadasParaCentrar;
  double _zoomInicial = 16.0;

  // Callback para centrar el mapa en una ubicación desde cualquier parte
  void _centrarEn(double lat, double lon, {double zoom = 16.0}) {
    setState(() {
      _tabIndex = 0;
      _coordenadasParaCentrar = LatLng(lat, lon);
      _zoomInicial = zoom;
    });
  }

  void _navegarAConductorLogin() {
    Navigator.pushNamed(context, '/conductor-login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        foregroundColor: Colors.white,
        title: const Text('San Antonio Bus Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Acceso conductor',
            onPressed: _navegarAConductorLogin,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          MapScreen(
            coordenadasIniciales: _coordenadasParaCentrar,
            zoomInicial: _zoomInicial,
            onMapaCentrado: () {
              setState(() => _coordenadasParaCentrar = null);
            },
          ),
          RutasScreen(onCentrarEn: _centrarEn),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppConfig.colorPrimary,
        indicatorColor: Colors.white.withValues(alpha: 0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.map, color: Colors.white),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.directions_bus, color: Colors.white),
            label: 'Rutas',
          ),
        ],
      ),
    );
  }
}