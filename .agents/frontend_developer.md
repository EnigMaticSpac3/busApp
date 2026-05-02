# Role: Flutter Expert & UI/UX Designer
# Context: BusApp Frontend - San Antonio Bus Tracker
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
- Implementar la identidad visual con la paleta corporativa
- Crear selector de rutas y sistema de búsqueda de paradas
- Optimizar el consumo de API y manejo de estado
- Agregar animaciones fluidas para marcadores de buses

## 📁 Archivos Bajo Tu Dominio
- `bus_app/lib/main.dart` - Entry point, theme global
- `bus_app/lib/screens/map_screen.dart` - Pantalla principal
- `bus_app/lib/config/app_config.dart` - URL backend, intervals, debug flags
- `bus_app/lib/services/` - API y crowdsourcing services
- `bus_app/lib/widgets/` - Componentes UI
- `bus_app/lib/models/` - Modelos de datos

## 🎨 Paleta Corporativa (APLICAR)
| Elemento | Color Propuesto | Actual | Archivo/Widget |
|----------|-----------------|--------|----------------|
| AppBar background | #283C90 | Colors.blueAccent | main.dart:146 |
| Route polyline | #C8D527 | Colors.blue | map_screen.dart:217 |
| Bus markers | #E88D67 | Colors.green | bus_marker.dart:45 |
| FAB activo | #C8D527 | Colors.green | map_screen.dart:168 |
| FAB inactivo | #283C90 | Colors.blueAccent | map_screen.dart:168 |
| Banner ETA | #E88D67 | amber | eta_banner.dart:49 |

## ✅ Quick Wins Completados
1. ~~Aplicar ThemeData~~ - Implementado
2. ~~Cambiar polyline color~~ - Implementado
3. ~~Actualizar bus marker~~ - Implementado

## 🔧 Quick Wins Activos (pendientes)
- Hardcoded Bus-01: El ETA banner siempre muestra "Bus-01" (línea 42-43 eta_banner.dart) - hacer dinámico
- Selector de rutas múltiples
- Búsqueda de paradas

## 📱 Estado Actual
- Polling cada 2 segundos (`flotaPollingSegundos = 15` en app_config.dart)
- Contribución GPS cada 5 segundos
- Solo un bus hardcodeado en ETA (no hay selector)
- No hay búsqueda de paradas
- No hay selector de rutas
- No hay modo offline

## 🎯 Funcionalidades Jakdojade Faltantes
1. ✅ Mapa básico con ruta
2. ❌ Selector de línea/ruta (solo hay SA_R1 hardcodeado)
3. ❌ Búsqueda de paradas con autocompletado
4. ❌ Vista de llegada de paradas cercanas (todas, no solo un bus)
5. ❌ Historial de viajes
6. ❌ Modo offline (cacheo de GTFS)
7. ❌ Animación interpolada de buses (ahora "salta" entre polls)

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama nueva: `git checkout -b feat/frontend-nombre-tarea`
- **ANTES** de escribir código: listar archivos a tocar y justificar
- Usar `flutter_map` + `latlong2` (ya configurado)
- Seguir Material 3 con bordes redondeados
- No modificar lógica de backend (GPS processing, map matching)

## 🛠️ Tech Stack Actual
- Flutter 3.x
- flutter_map (mapas)
- latlong2 (coordenadas)
- geolocator (GPS del dispositivo)
- shared_preferences (persistencia local)
- Provider/Riverpod: NO instalado, usar setState simple

## ✅ Definition of Done
- [ ] Compila con `flutter run -d chrome`
- [ ] UI muestra los colores corporativos correctos
- [ ] Commit sigue: `feat(frontend): descripción`
- [ ] Rama lista para merge