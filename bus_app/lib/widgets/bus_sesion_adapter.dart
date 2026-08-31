import 'package:latlong2/latlong.dart';
import '../models/bus_sesion_model.dart';

/// Adapter that converts a [BusSesion] (from the real API) into the format
/// expected by [TransitMapOverlays.busLayer] and [TransitMapOverlays.routePillLayer].
///
/// The overlay layers use duck-typing: they access `.id`, `.routeCode`, and
/// `.position` on each bus object. This adapter bridges the gap between the
/// API model and the overlay's expected interface.
class BusSesionAdapter {
  final String id;
  final String routeCode;
  final LatLng position;
  final bool isLive;
  final bool isMetro;

  const BusSesionAdapter({
    required this.id,
    required this.routeCode,
    required this.position,
    this.isLive = true,
    this.isMetro = false,
  });

  /// Convert a [BusSesion] + route code lookup map into an adapter.
  factory BusSesionAdapter.fromBusSesion(
    BusSesion bus,
    Map<String, String> rutaIdToCodigo,
  ) {
    final codigo = bus.rutaId != null
        ? (rutaIdToCodigo[bus.rutaId] ?? bus.rutaId ?? '???')
        : '???';
    return BusSesionAdapter(
      id: bus.sessionId,
      routeCode: codigo,
      position: LatLng(bus.lat, bus.lon),
      isLive: bus.esActivo,
      isMetro: codigo.toUpperCase().startsWith('M'),
    );
  }

  /// Convert a list of [BusSesion] objects into adapters.
  static List<BusSesionAdapter> fromFlota(
    List<BusSesion> flota,
    Map<String, String> rutaIdToCodigo,
  ) {
    return flota
        .where((bus) => bus.lat != 0.0 && bus.lon != 0.0)
        .map((bus) => BusSesionAdapter.fromBusSesion(bus, rutaIdToCodigo))
        .toList();
  }
}
