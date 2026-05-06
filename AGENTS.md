# AGENTS.md - San Antonio Bus Tracker

## Project Structure
```
busApp/
├── backend_bus_app/     # FastAPI backend (Python 3.11)
│   ├── app/
│   │   ├── main.py              # API + sesiones dinámicas + geofencing
│   │   └── gtfs_san_antonio/   # GTFS static data (shapes, stops, routes)
│   └── docker-compose.yml      # API service
├── bus_app/            # Flutter frontend
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── map_screen.dart
│       │   ├── rutas_screen.dart
│       │   └── ruta_detalle_screen.dart
│       ├── services/
│       │   ├── api_service.dart
│       │   └── crowdsourcing_service.dart
│       ├── widgets/
│       │   ├── bus_marker.dart
│       │   ├── crowdsourcing_sheet.dart
│       │   ├── subida_bus_sheet.dart
│       │   └── eta_banner.dart
│       └── models/
│           ├── bus_sesion_model.dart
│           ├── ruta_model.dart
│           └── parada_model.dart
└── .opencode/agents/    # Agent definitions
    ├── backend_engineer.md
    ├── frontend_developer.md
    ├── devops_agent.md
    └── git-flow-guide.md
```

## Estado del Proyecto

| Versión | Estado | Descripción |
|---------|--------|-------------|
| **v1** | ✅ Deprecated | Mapa básico, ruta E598, simulación GPS |
| **v2** | ✅ Estable | Sesiones dinámicas, crowdsourcing real, validado en campo |
| **v3** | ✅ Completado | Menú de rutas, ubicación usuario, NavigationBar |
| **v4** | 🔄 En desarrollo | WebSocket, animaciones, múltiples rutas |

---

### ✅ Completados v3
| # | Rama | Descripción | Fecha |
|---|------|-------------|-------|
| 1 | `feat/backend-*` | GET /api/rutas - lista de rutas desde GTFS | 2025-05-03 |
| 2 | `feat/backend-*` | GET /api/rutas/{ruta_id}/paradas - paradas ordenadas | 2025-05-03 |
| 3 | `feat/frontend-*` | NavigationBar con tabs Mapa y Rutas | 2025-05-03 |
| 4 | `feat/frontend-*` | RutasScreen con pull-to-refresh | 2025-05-03 |
| 5 | `feat/frontend-*` | RutaDetalleScreen con lista de paradas | 2025-05-03 |
| 6 | `feat/frontend-*` | Ubicación del usuario en el mapa (punto azul) | 2025-05-03 |
| 7 | `feat/frontend-*` | Botón centrar en mi ubicación (FAB) | 2025-05-03 |
| 8 | `fix/frontend-*` | Corregir parsing API - wrapper rutas/paradas | 2025-05-03 |
| 9 | `feat/frontend-*` | Flow de selección de ruta antes de contribuir | 2025-05-03 |
| 10 | `feat/frontend-*` | Conectar tap en parada con mapa centrado | 2025-05-03 |

### 🔜 En Progreso (v4)
- WebSocket /ws/flota para tiempo real
- Animación suave de marcadores
- Soporte múltiples rutas GTFS

### ⬜ Pendientes (v5)
- PostGIS con persistencia de trayectorias
- Modo conductor oficial
- Deployment producción

---

## How to Run

### Backend
```bash
cd backend_bus_app
docker-compose up --build
# API: http://localhost:8000
# Docs: http://localhost:8000/docs
```

### Frontend
```bash
cd bus_app
flutter build apk --debug  # Android
# O
flutter run -d chrome     # Web
```

## Flujo de Usuario v3

```
1. Abrir app → HomeScreen con NavigationBar
2. Tab Mapa: Ver ruta y buses en tiempo real
3. Tab Rutas: Ver lista de rutas disponibles
4. Tocar ruta → Ver paradas en orden
5. Tocar parada → Mapa centrado en esa parada
6. Tocar "Estoy en el bus" → Selección de ruta → Contribuir GPS
```

## Critical Configurations

- **Backend URL** in `bus_app/lib/config/app_config.dart:11`
- **Debug crowdsourcing** in `app_config.dart:22` - defaults to `false`
- **Polling intervals**: Fleet 2s, GPS contribution 5s

## Map Matching Thresholds (main.py)
- Distance to route: 35m
- Speed: 1.4-16 m/s (~5-60 km/h)
- GPS precision: >50m rejected

## Estados de Sesión (Backend)
| Estado | Condición | Visualización |
|--------|-----------|---------------|
| `activo` | señal < 15s | Marcador sólido #E88D67 |
| `incierto` | señal 15s-5min | Marcador 50% opacidad |
| `perdido` | señal > 5min | Marcador 20% opacidad, luego se elimina |

## Key Commands
```bash
# Backend
cd backend_bus_app && docker-compose up --build

# Frontend
cd bus_app && flutter build apk --debug

# Test API
curl http://localhost:8000/api/flota
curl http://localhost:8000/api/rutas
curl http://localhost:8000/api/rutas/SA_INTERNAL/paradas

# Test WebSocket (cuando esté implementado)
wscat -c ws://localhost:8000/ws/flota
```

## Skills Instaladas
- flutter-add-widget-test
- fastapi-python
- devops-engineer
- security-review

## Multi-Agent Workflow
```bash
# Crear rama desde develop
git checkout develop && git pull
git checkout -b feat/backend-nombre-tarea

# Activar agente
opencode

# Commit y push
git commit -m "feat(backend): descripción"
git push -u origin feat/backend-nombre-tarea
```

## Git Flow

```
main (producción) ← v1, v2, v3 ✅
  ↑
develop (integración) ← v4 activo
  ↑
feat/frontend-*   feat/backend-*   chore/devops-*
```