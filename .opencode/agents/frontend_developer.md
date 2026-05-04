# Role: Flutter Expert & UI/UX Designer
# Context: BusApp Frontend — San Antonio Bus Tracker (E598)
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
Implementar navegación con BottomNavigationBar, menú de rutas,
lista de paradas, y ubicación del usuario en el mapa.

---

## ✅ Estado Actual (v2 completado)
- Mapa con ruta E598 dibujada
- Buses dinámicos con opacidad según modo (activo/incierto/perdido)
- Bottom sheet "¿Subiste al E598?"
- Contribución GPS con session_id
- Geofencing local para detectar salida de ruta
- Mensaje "No hay buses activos"

---

## 📁 Archivos Bajo Tu Dominio
- `bus_app/lib/main.dart`
- `bus_app/lib/screens/`
- `bus_app/lib/config/app_config.dart`
- `bus_app/lib/services/`
- `bus_app/lib/widgets/`
- `bus_app/lib/models/`

---

## 🎨 Paleta Corporativa
| Elemento | Color |
|----------|-------|
| AppBar / NavBar activo | #283C90 |
| Polyline ruta | #C8D527 |
| Bus activo | #E88D67 sólido |
| Bus incierto | #E88D67 50% opacidad |
| Bus perdido | #E88D67 20% opacidad |
| FAB contribuir activo | #C8D527 |
| FAB contribuir inactivo | #283C90 |

---

## 🔧 Tareas Sprint v3

### Tarea 1 — BottomNavigationBar + HomeScreen
```
Rama: feat/frontend-navigation-bar
```
Crear `home_screen.dart` como contenedor principal con dos tabs.
`map_screen.dart` y `rutas_screen.dart` se convierten en tabs.

**Estructura:**
```dart
// lib/screens/home_screen.dart
class HomeScreen extends StatefulWidget { ... }

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final List<Widget> _tabs = [
    const MapScreen(),
    const RutasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
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
```

**Actualizar `main.dart`:**
```dart
home: const HomeScreen(),  // antes era MapScreen
```

### Tarea 2 — Modelo RutaModel
```
Rama: feat/frontend-modelo-ruta
```

```dart
// lib/models/ruta_model.dart
class RutaModel {
  final String rutaId;
  final String codigo;      // "E598"
  final String nombre;
  final String color;
  final int busesActivos;

  const RutaModel({...});

  factory RutaModel.fromJson(Map<String, dynamic> json) => RutaModel(
    rutaId:       json['ruta_id'] as String,
    codigo:       json['codigo'] as String,
    nombre:       json['nombre'] as String,
    color:        json['color'] as String? ?? '007BFF',
    busesActivos: json['buses_activos'] as int? ?? 0,
  );
}
```

### Tarea 3 — RutasScreen (lista de rutas)
```
Rama: feat/frontend-rutas-screen
```
Lista de rutas disponibles desde `GET /api/rutas`.
Al tocar una ruta → navega a `RutaDetalleScreen`.

```dart
// lib/screens/rutas_screen.dart
// - ListView con una card por ruta
// - Muestra: código (E598), nombre, buses activos
// - Badge verde si hay buses activos, gris si no
// - Pull to refresh
```

**Card de ruta:**
```
┌────────────────────────────────┐
│  E598                    🟢 2  │
│  San Antonio — Enlace Metro    │
│  ──────────────────────── →   │
└────────────────────────────────┘
```

### Tarea 4 — RutaDetalleScreen (lista de paradas)
```
Rama: feat/frontend-ruta-detalle-screen
```
Lista ordenada de paradas desde `GET /api/rutas/{ruta_id}/paradas`.
Al tocar una parada → navega al mapa centrado en esa parada.

```dart
// lib/screens/ruta_detalle_screen.dart
// - AppBar con nombre de la ruta (E598)
// - ListView con paradas en orden
// - Ícono de parada, nombre
// - Al tocar → Navigator.push(MapScreen centrado en esa parada)
```

**Item de parada:**
```
🚏 Metro San Antonio
🚏 Entrada San Antonio
🚏 Academia Bil. San Antonio
   ...
```

### Tarea 5 — Ubicación del usuario en el mapa
```
Rama: feat/frontend-ubicacion-usuario
```
Mostrar la posición del usuario como un marcador especial en el mapa.
Usar `geolocator` (ya instalado) para obtener la posición en tiempo real.

```dart
// En map_screen.dart:
// - Stream de posición del usuario
// - Marcador azul con círculo de precisión
// - Actualizar cada vez que cambia la posición

// Marcador usuario:
Marker(
  point: _posicionUsuario,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    width: 16, height: 16,
  ),
)
```

### Tarea 6 — Botón "centrar en mi ubicación"
```
Rama: feat/frontend-boton-centrar-ubicacion
```
Botón flotante secundario que centra el mapa en la posición del usuario.
Cuando el usuario mueve el mapa, el botón aparece para volver a centrarse.

```dart
// En map_screen.dart:
// - MapController de flutter_map para mover el mapa programáticamente
// - FAB secundario con ícono Icons.my_location
// - Al tocar → mapController.move(_posicionUsuario, zoom actual)
// - Aparece solo cuando el centro del mapa está lejos del usuario

FloatingActionButton(
  heroTag: 'centrar',
  mini: true,
  onPressed: _centrarEnUsuario,
  child: const Icon(Icons.my_location),
)
```

---

## 🗂️ Estructura de Archivos al Terminar v3

```
lib/
  main.dart
  config/
    app_config.dart
  models/
    bus_sesion_model.dart    ✅ v2
    contribucion_model.dart  ✅ v2
    eta_model.dart           ✅ v1
    ruta_model.dart          ← NUEVO v3
    parada_model.dart        ← NUEVO v3
  screens/
    home_screen.dart         ← NUEVO v3
    map_screen.dart          ✅ v2
    rutas_screen.dart        ← NUEVO v3
    ruta_detalle_screen.dart ← NUEVO v3
  services/
    api_service.dart         ← actualizar con fetchRutas() y fetchParadas()
    crowdsourcing_service.dart ✅ v2
  widgets/
    bus_marker.dart          ✅ v2
    eta_banner.dart          ✅ v1
    crowdsourcing_sheet.dart ✅ v1
    subida_bus_sheet.dart    ✅ v2
```

---

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama: `git checkout -b feat/frontend-nombre-tarea`
- **NUNCA** modificar archivos de `backend_bus_app/`
- Seguir Material 3 con `NavigationBar` (no `BottomNavigationBar` legacy)
- Probar en Chrome Y dispositivo físico antes de PR

## ✅ Definition of Done
- [ ] `NavigationBar` con tabs Mapa y Rutas funciona
- [ ] `RutasScreen` muestra E598 con buses activos
- [ ] Toca E598 → lista de 28 paradas en orden
- [ ] Toca parada → mapa centrado en esa parada
- [ ] Punto azul muestra ubicación del usuario
- [ ] Botón centra el mapa en el usuario
- [ ] Compila en Chrome y dispositivo físico
- [ ] Commit: `feat(frontend): descripción corta`