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
            child: AnimatedBusMarker(
              key: ValueKey(bus.sessionId),
              bus: bus,
              posicionAnterior: posicionesAnteriores[bus.sessionId],
            ),
          ))
      .toList();
}

class AnimatedBusMarker extends StatefulWidget {
  final BusSesion bus;
  final LatLng? posicionAnterior;

  const AnimatedBusMarker({
    super.key,
    required this.bus,
    this.posicionAnterior,
  });

  @override
  State<AnimatedBusMarker> createState() => _AnimatedBusMarkerState();
}

class _AnimatedBusMarkerState extends State<AnimatedBusMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(AnimatedBusMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final distancia = _distanciaEntre(
      LatLng(widget.bus.lat, widget.bus.lon),
      LatLng(oldWidget.bus.lat, oldWidget.bus.lon),
    );
    if (distancia > 10) {
      _controller.forward(from: 0);
    }
  }

  double _distanciaEntre(LatLng a, LatLng b) {
    const metroPorGrado = 111320.0;
    final dLat = (a.latitude - b.latitude).abs() * metroPorGrado;
    final dLon = (a.longitude - b.longitude).abs() * metroPorGrado;
    return (dLat * dLat + dLon * dLon);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: widget.bus.opacidad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.bus.esIncierto || widget.bus.esPerdido)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gray900,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.bus.etiquetaTiempo,
                    style: const TextStyle(color: AppColors.white, fontSize: 9),
                  ),
                ),
              if (widget.bus.esActivo)
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
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
