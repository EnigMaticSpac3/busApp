import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus),
            label: 'Rutas',
          ),
        ],
      ),
    );
  }
}
