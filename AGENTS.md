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
│       ├── screens/map_screen.dart
│       ├── services/
│       │   ├── api_service.dart
│       │   └── crowdsourcing_service.dart
│       ├── widgets/
│       │   ├── bus_marker.dart
│       │   ├── crowdsourcing_sheet.dart
│       │   ├── subida_bus_sheet.dart
│       │   └── eta_banner.dart
│       └── config/app_config.dart
└── .agents/            # Agent definitions
    ├── backend_engineer.md
    ├── frontend_developer.md
    ├── devops_agent.md
    ├── git-flow-guide.md
    └── create-branch.sh
```

## Quick Wins - Estado (v2 COMPLETO ✅)

### ✅ Completados v2
| # | Rama | Descripción | Fecha |
|---|------|-------------|-------|
| 1 | `chore/devops-*` | Multi-stage Docker | 2025-05-02 |
| 2 | `feat/frontend-*` | Paleta corporativa (#283C90, #C8D527, #E88D67) | 2025-05-02 |
| 3 | `fix/backend-*` | precision_m filter (>50m) | 2025-05-02 |
| 4 | `fix/backend-*` | Velocidad máxima 22→16 m/s | 2025-05-02 |
| 5 | `refactor/backend-*` | Eliminar simulación, crear sesiones dinámicas | 2025-05-03 |
| 6 | `feat/backend-*` | Sesión bus dinámica (POST /api/iniciar-sesion-bus) | 2025-05-03 |
| 7 | `feat/backend-*` | Contribución por sesión con session_id | 2025-05-03 |
| 8 | `feat/backend-*` | Flota desde sesiones activas | 2025-05-03 |
| 9 | `feat/backend-*` | Monitor de sesiones (geofencing backend) | 2025-05-03 |
| 10 | `feat/backend-*` | Ruta con 1730 puntos para geofencing | 2025-05-03 |
| 11 | `feat/frontend-*` | Modelo BusSesion con modo y opacidad | 2025-05-03 |
| 12 | `feat/frontend-*` | Marcador dinámico con incertidumbre | 2025-05-03 |
| 13 | `feat/frontend-*` | Confirmación de subida al bus | 2025-05-03 |
| 14 | `feat/frontend-*` | Geofencing local para salida de ruta | 2025-05-03 |
| 15 | `feat/frontend-*` | Mensaje cuando no hay buses activos | 2025-05-03 |
| 16 | `fix/frontend-*` | Integración con backend v2 - payloads con sessionId/rutaId | 2025-05-03 |
| 17 | `fix/frontend-*` | Debug logs y corregir eta_banner para usar session_id real | 2025-05-03 |

### 🔜 Pendientes (v3)
- WebSocket para tiempo real (eliminar polling)
- PostGIS con persistencia de trayectorias reales
- Selector de rutas (origen → destino estilo Jakdojade)
- Modo offline con GTFS cacheado
- Algoritmo de fusión múltiples contribuidores

## How to Run

### Backend
```bash
cd backend_bus_app
docker-compose up --build
# API: http://localhost:8000
```

### Frontend
```bash
cd bus_app
flutter build apk --debug  # Para Android
# O
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## Nuevo Flujo v2 (Confirmación de Usuario)

```
1. Usuario toca "Estoy en el bus"
2. App muestra: "¿Subiste al bus E598?" [Sí] [Todavía no]
3. Si confirma → POST /api/iniciar-sesion-bus → recibe session_id
4. GPS activo → envía cada 5s con session_id
5. Backend fusiona múltiples contribuidores (promedio GPS)
6. Geofencing detecta si usuario sale de la ruta → detiene contribución
7. Si no hay señal >5 min → bus pasa a modo "incierto"
8. Si no hay señal >10 min → bus desaparece del mapa
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
curl -X POST http://localhost:8000/api/iniciar-sesion-bus \
  -H "Content-Type: application/json" \
  -d '{"usuario_id":"test","ruta_id":"SA_R1"}'
```

## Skills Instaladas
- flutter-add-widget-test
- fastapi-python
- devops-engineer
- security-review

## Multi-Agent Workflow
```bash
# Crear rama
./.opencode/agents/create-branch.sh [frontend|backend|devops] "descripcion"

# Activar agente
opencode
# Pegar prompt de activación
```