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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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