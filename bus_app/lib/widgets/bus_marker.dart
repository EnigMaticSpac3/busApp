// lib/widgets/bus_marker.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';

/// Convierte una lista de buses en marcadores para FlutterMap.
List<Marker> buildBusMarkers(List<Bus> flota) {
  return flota
      .where((bus) => bus.lat != 0.0 && bus.lon != 0.0) // ignorar buses sin posición aún
      .map((bus) => Marker(
            point: LatLng(bus.lat, bus.lon),
            width: 56,
            height: 56,
            child: _BusMarkerWidget(bus: bus),
          ))
      .toList();
}

class _BusMarkerWidget extends StatelessWidget {
  final Bus bus;
  const _BusMarkerWidget({required this.bus});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            bus.id,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Icon(Icons.directions_bus, color: Colors.green, size: 30),
      ],
    );
  }
}