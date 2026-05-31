// lib/widgets/bus_marker.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bus_app/theme/export.dart';
import '../models/bus_sesion_model.dart';

/// Convierte una lista de buses en marcadores para FlutterMap.
List<Marker> buildBusMarkers(List<BusSesion> flota) {
  return flota
      .where((bus) => bus.lat != 0.0 && bus.lon != 0.0)
      .map((bus) => Marker(
            point: LatLng(bus.lat, bus.lon),
            width: 56,
            height: 56,
            child: _BusMarkerWidget(bus: bus),
          ))
      .toList();
}

class _BusMarkerWidget extends StatelessWidget {
  final BusSesion bus;
  const _BusMarkerWidget({required this.bus});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: bus.opacidad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge con tiempo si es incierto o perdido
          if (bus.esIncierto || bus.esPerdido)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                bus.etiquetaTiempo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
              ),
            ),
          // Bus: círculo blanco con icono naranja
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus,
              color: AppColors.accent,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}