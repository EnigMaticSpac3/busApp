// lib/widgets/bus_marker_animated.dart
//
// Marcador de bus con animación suave de posición.
// SimpleTweenAnimation para interpolación lineal.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';
import '../models/bus_sesion_model.dart';

/// Genera marcadores de buses con animación de posición.
List<Marker> buildAnimatedBusMarkers(
  List<BusSesion> flota,
  Map<String, LatLng> posicionesAnteriores,
) {
  return flota
      .where((bus) => bus.lat != 0.0 && bus.lon != 0.0)
      .map((bus) {
        return Marker(
          point: LatLng(bus.lat, bus.lon),
          width: 56,
          height: 56,
          child: AnimatedBusMarker(
            key: ValueKey(bus.sessionId),
            bus: bus,
            posicionAnterior: posicionesAnteriores[bus.sessionId],
          ),
        );
      })
      .toList();
}

/// Marcador individual con animación suave.
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
  // ignore: unused_field
  late Animation<double> _latAnim;
  // ignore: unused_field
  late Animation<double> _lonAnim;

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

    // Solo animar si hay posición anterior y cambió significativamente
    if (widget.posicionAnterior != null) {
      final distancia = _distanciaEntre(
        LatLng(widget.bus.lat, widget.bus.lon),
        LatLng(oldWidget.bus.lat, oldWidget.bus.lon),
      );

      if (distancia > 10) {
        _latAnim = Tween<double>(
          begin: widget.posicionAnterior!.latitude,
          end: widget.bus.lat,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));

        _lonAnim = Tween<double>(
          begin: widget.posicionAnterior!.longitude,
          end: widget.bus.lon,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));

        _controller.forward(from: 0);
      }
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
              // Badge con tiempo si es incierto o perdido
              if (widget.bus.esIncierto || widget.bus.esPerdido)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.bus.etiquetaTiempo,
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
                  color: AppConfig.colorAlert,
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