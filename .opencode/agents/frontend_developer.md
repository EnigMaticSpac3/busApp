# Role: Flutter Expert & UI/UX Designer
# Context: BusApp Frontend — San Antonio Bus Tracker (E598)
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
Implementar el nuevo flujo de contribución con confirmación del usuario,
marcadores dinámicos con indicador de incertidumbre, y geofencing local.

---

## 📐 Nuevo Flujo de Contribución (v2)

### Antes
```
Usuario toca "Contribuir" → GPS activo → backend adivina el bus
```

### Ahora
```
Usuario toca "Estoy en el bus"
    ↓
Bottom sheet: "¿Subiste al bus E598?"
    [Sí, ya subí]   [Todavía no]
    ↓
App llama POST /api/iniciar-sesion-bus
Backend devuelve session_id
    ↓
App guarda session_id localmente
GPS activo → envía cada 5s con session_id
    ↓
Geofencing local detecta si usuario salió de la ruta
    → Si salió → detener contribución automáticamente
    → Mostrar: "Dejaste de contribuir (saliste de la ruta)"
```

---

## 📁 Archivos Bajo Tu Dominio
- `bus_app/lib/main.dart`
- `bus_app/lib/screens/map_screen.dart`
- `bus_app/lib/config/app_config.dart`
- `bus_app/lib/services/api_service.dart`
- `bus_app/lib/services/crowdsourcing_service.dart`
- `bus_app/lib/widgets/` — todos los widgets
- `bus_app/lib/models/` — todos los modelos

---

## 🎨 Paleta Corporativa (ya aplicada ✅)
| Elemento | Color |
|----------|-------|
| AppBar | #283C90 |
| Polyline ruta | #C8D527 |
| Bus marcador activo | #E88D67 sólido |
| Bus marcador incierto | #E88D67 al 50% opacidad |
| Bus marcador perdido | #E88D67 al 20% opacidad |
| FAB activo | #C8D527 |
| FAB inactivo | #283C90 |

---

## 🔧 Quick Wins Activos

### 1. Nuevo modelo BusSesion
```
Rama: feat/frontend-modelo-bus-sesion
```
Reemplazar `Bus` con `BusSesion` que incluye `segundos_sin_senal` y `modo`.

```dart
// lib/models/bus_sesion_model.dart
class BusSesion {
  final String sessionId;
  final double lat;
  final double lon;
  final double velMs;
  final String modo;           // "activo" | "incierto" | "perdido"
  final double segundosSinSenal;

  bool get esActivo   => modo == "activo";
  bool get esIncierto => modo == "incierto";
  bool get esPerdido  => modo == "perdido";

  // Opacidad del marcador según estado
  double get opacidad => esActivo ? 1.0 : esIncierto ? 0.5 : 0.2;

  // Texto del tooltip
  String get etiquetaTiempo {
    if (esActivo) return "En tiempo real";
    final min = (segundosSinSenal / 60).floor();
    return "Última señal hace ${min}m";
  }
}
```

### 2. Marcador dinámico con opacidad
```
Rama: feat/frontend-marcador-incertidumbre
```

```dart
// lib/widgets/bus_marker.dart
Marker(
  point: LatLng(bus.lat, bus.lon),
  child: Opacity(
    opacity: bus.opacidad,
    child: Column(children: [
      // Badge con tiempo si es incierto
      if (bus.esIncierto || bus.esPerdido)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            bus.etiquetaTiempo,
            style: TextStyle(color: Colors.white, fontSize: 9),
          ),
        ),
      Icon(Icons.directions_bus, color: Color(0xFFE88D67), size: 30),
    ]),
  ),
)
```

### 3. Bottom sheet de confirmación de subida
```
Rama: feat/frontend-confirmacion-subida
```
Reemplazar el sheet genérico de "¿Quieres contribuir?" por uno específico:

```dart
// lib/widgets/subida_bus_sheet.dart
// Muestra: "¿Subiste al bus E598?"
// Botones: [Sí, ya subí] [Todavía no]
// Al confirmar: llama POST /api/iniciar-sesion-bus
//               guarda session_id en SharedPreferences
//               activa el GPS
```

### 4. Geofencing local en CrowdsourcingService
```
Rama: feat/frontend-geofencing-salida-ruta
```
Cada vez que se recibe una posición GPS, verificar si está dentro de 100m
de algún punto de la ruta (usando los puntos cacheados de `/api/ruta`).

```dart
bool _estaEnRuta(LatLng posicion) {
  const umbralM = 100.0;
  for (final punto in _rutaPoints) {
    final dist = const Distance().as(
      LengthUnit.Meter, posicion, punto,
    );
    if (dist <= umbralM) return true;
  }
  return false;
}

// En _enviarUbicacion():
if (!_estaEnRuta(LatLng(posicion.latitude, posicion.longitude))) {
  detener();
  _notificarSalidaRuta(); // snackbar o banner
  return;
}
```

### 5. Mensaje cuando no hay buses activos
```dart
// En map_screen.dart, sobre el mapa:
if (_flota.isEmpty)
  Positioned(
    bottom: 80, left: 16, right: 16,
    child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "No hay buses activos en este momento.\n"
        "Sé el primero en contribuir.",
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    ),
  ),
```

---

## 🚀 Big Bets (v3)
1. Selector de ruta origen → destino (estilo Jakdojade)
2. Detección automática de bajada por ruta elegida
3. Animación suave de marcadores entre polls (interpolación)
4. Vista de paradas con tiempos de llegada de todos los buses activos
5. Modo offline con GTFS cacheado en local

---

## 🛠️ Tech Stack Actual
- Flutter 3.x + Material 3
- flutter_map + latlong2
- geolocator (GPS)
- shared_preferences (session_id, preferencias)
- http (polling REST)
- latlong2 Distance() para geofencing local

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama: `git checkout -b feat/frontend-nombre-tarea`
- **NUNCA** modificar archivos de `backend_bus_app/`
- Una tarea por rama — no mezclar UI con lógica de servicio
- Probar en Chrome Y en dispositivo físico antes de PR

## ✅ Definition of Done
- [ ] Compila sin warnings en `flutter run -d chrome`
- [ ] Marcador sólido cuando bus activo, semitransparente cuando incierto
- [ ] Bottom sheet pregunta "¿Subiste al E598?" antes de activar GPS
- [ ] Geofencing detiene contribución al salir de la ruta
- [ ] Mapa muestra mensaje cuando no hay buses activos
- [ ] Commit: `feat(frontend): descripción corta`