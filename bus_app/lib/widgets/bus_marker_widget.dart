import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bus_app/models/bus_sesion_model.dart';
import 'package:bus_app/theme/export.dart';

List<Marker> buildBusMarkers(
  List<BusSesion> flota,
  Map<String, LatLng> posicionesAnteriores,
) {
  return flota
      .where((bus) => bus.lat != 0.0 && bus.lon != 0.0)
      .map((bus) => Marker(
            point: LatLng(bus.lat, bus.lon),
            width: 56,
            height: 64,
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
          if (bus.esIncierto || bus.esPerdido)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gray900,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                bus.etiquetaTiempo,
                style: const TextStyle(color: AppColors.white, fontSize: 9),
              ),
            ),
          if (bus.esActivo)
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(200, 213, 39, 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [AppShadows.shadowMd],
            ),
            child: const Icon(
              Icons.directions_bus,
              color: AppColors.alert,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
