import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para leer el JSON
import 'dart:async'; // Nueva importación para el Timer

void main() => runApp(const MaterialApp(home: SanAntonioMap()));

class SanAntonioMap extends StatefulWidget {
  const SanAntonioMap({super.key});
  @override
  State<SanAntonioMap> createState() => _SanAntonioMapState();
}


class _SanAntonioMapState extends State<SanAntonioMap> {
  final LatLng center = const LatLng(9.0561, -79.4582);
  List<LatLng> routePoints = [];
  bool isLoading = true;
  String paradaCercana = "Calculando...";
  
  // Variables del Simulador
  LatLng? posicionBus;
  Timer? simuladorGps;

  // lista para almacenar la flota activa, que se actualizará cada segundo con el nuevo endpoint
  List<dynamic> flotaActiva = [];

  @override
  void initState() {
    super.initState();
    _fetchRouteFromBackend();
    
    // Iniciar el Polling: Preguntar al backend cada segundo
    simuladorGps = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchFlota(); // antes _fetchPosicionBus, ahora _fetchFlota para obtener toda la flota y mostrar solo el Bus-01 en el banner
    });
  }

  @override
  void dispose() {
    // Apagar el timer si cierras la app para no gastar memoria
    simuladorGps?.cancel();
    super.dispose();
  }

  Future<void> _fetchRouteFromBackend() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/ruta'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<LatLng> points = [];
        for (var p in data['puntos']) {
          points.add(LatLng(p['lat'], p['lon']));
        }
        setState(() {
          routePoints = points;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error de conexión a la API: $e');
      setState(() => isLoading = false);
    }
  }

  // Llama al NUEVO ENDPOINT del bus en movimiento
  /* Future<void> _fetchPosicionBus() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/bus-ubicacion'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['lat'] != 0.0) {
          setState(() {
            posicionBus = LatLng(data['lat'], data['lon']);
          });
          
          // AHORA LE ENVIAMOS LA VELOCIDAD AL BACKEND
          _checkNearestStop(data['lat'], data['lon'], data['velocidad_ms']);
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación del bus: $e');
    }
  }
  */
  
  // reemplazando el metodo fetchPosicionBus por este nuevo metodo que obtiene toda la flota, pero solo le pedimos al backend la ubicación del Bus-01 para el banner
  Future<void> _fetchFlota() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/flota'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          flotaActiva = data;
        });
        
        // Solo para el banner, le pedimos a la API la parada del Bus-01
        if (flotaActiva.isNotEmpty) {
          _checkNearestStop("Bus-01");
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo flota: $e');
    }
  }

  // AHORA RECIBE LA VELOCIDAD
  /* Future<void> _checkNearestStop(double lat, double lon, double velMs) async {
    try {
      final response = await http.get(
        // PASAMOS LA VELOCIDAD COMO PARÁMETRO EN LA URL
        Uri.parse('http://localhost:8000/api/parada-cercana?lat=$lat&lon=$lon&vel_ms=$velMs')
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // ACTUALIZAMOS EL TEXTO PARA MOSTRAR EL ETA
          paradaCercana = "Llegando a ${data['parada_mas_cercana']} en ${data['eta_texto']} (${data['distancia_metros']}m)";
        });
      }
    } catch (e) {
      debugPrint('Error calculando parada: $e');
    }
  }
 */
  Future<void> _checkNearestStop(String idBus) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/parada-cercana/$idBus'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          paradaCercana = "Bus 1 -> Próxima: ${data['parada']} en ${data['eta']}";
        });
      }
    } catch (e) {
      debugPrint('Error calculando parada: $e');
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiBus San Antonio (En Vivo)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.amberAccent,
            child: Text(
              paradaCercana,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: Colors.blue.withOpacity(0.6),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                    // marcador del bus en movimiento
                   /*  MarkerLayer(
                      markers: [
                        if (posicionBus != null)
                          Marker(
                            point: posicionBus!,
                            width: 50,
                            height: 50,
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.circle, color: Colors.white, size: 40),
                                Icon(Icons.directions_bus, color: Colors.green, size: 30),
                              ],
                            ),
                          ),
                      ],
                    ),
                   */
                  // Capa dinámica de la Flota
                    MarkerLayer(
                      markers: flotaActiva.map((bus) {
                        return Marker(
                          point: LatLng(bus['lat'], bus['lon']),
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: Text(
                                  bus['id'], 
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                )
                              ),
                              const Icon(Icons.directions_bus, color: Colors.green, size: 30),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}