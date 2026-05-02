# AGENTS.md - San Antonio Bus Tracker

## Project Structure
```
busApp/
├── backend_bus_app/     # FastAPI backend (Python 3.11)
│   ├── app/
│   │   ├── main.py              # API + motor GPS + map matching
│   │   └── gtfs_san_antonio/   # GTFS static data (shapes, stops, routes)
│   ├── docker-compose.yml      # API + PostGIS services
│   └── Dockerfile
├── bus_app/            # Flutter frontend
│   └── lib/
│       ├── main.dart
│       ├── screens/map_screen.dart
│       ├── services/           # API + crowdsourcing services
│       └── config/app_config.dart
└── .agents/            # Agent definitions for multi-agent workflow
    ├── backend_engineer.md
    ├── frontend_developer.md
    ├── devops_agent.md
    ├── git-flow-guide.md
    └── create-branch.sh
```

## Quick Wins - Estado

### ✅ Completados
| # | Rama | Descripción | Fecha |
|---|------|-------------|-------|
| 1 | `chore/devops-*` | Multi-stage Docker + docker-compose optimization | 2025-05-02 |
| 2 | `feat/frontend-*` | Aplicar paleta corporativa (#283C90, #C8D527, #E88D67) | 2025-05-02 |
| 3 | `fix/backend-*` | precision_m filter (>50m reject) | 2025-05-02 |
| 4 | `fix/backend-*` | Velocidad máxima 22→16 m/s (~60 km/h) | 2025-05-02 |

### 🔜 Pendientes
- WebSocket para tiempo real
- PostGIS con persistencia de trayectorias
- Selector de rutas múltiples
- Modo offline con GTFS cacheado

## How to Run

### Backend
```bash
cd backend_bus_app
docker-compose up --build
# API: http://localhost:8000
# PostGIS: localhost:5432 (configured but NOT actively used)
```

### Frontend
```bash
cd bus_app
flutter build apk --debug  # Para Android
# O
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080  # Para web
```

## Critical Configurations

- **Backend URL** in `bus_app/lib/config/app_config.dart:11` - currently points to ngrok tunnel (change to `http://192.168.X.X:8000` for local physical device testing)
- **Debug crowdsourcing** in `app_config.dart:22` - defaults to `false`, set to `true` to bypass map matching validation
- **Polling intervals**: Fleet every 2s (`app_config.dart:15`), GPS contribution every 5s

## Map Matching Thresholds (in `backend_bus_app/app/main.py:44-47`)
- Distance to route: 35m (acceptable for urban Panama)
- Speed: 1.4-16 m/s (~5-60 km/h) - UPDATED: reduced from 22 to 16 m/s
- Bus assignment proximity: 200m
- GPS precision filter: >50m rejected (UPDATED)

## Known Limitations
- PostGIS container runs but GTFS loads from CSV files into memory, not DB
- Only 3 buses hardcoded in `main.py:55-62`
- No WebSocket - uses HTTP polling
- Crowdsourcing requires user to be moving at >1.4 m/s (bus speed)
- No multi-route support - single route hardcoded with `SHAPE_ID = "SA_R1"`

## Important Files for Changes
- Add new route: modify `SHAPE_ID` and `TRIP_ID` in `main.py:37-38`
- Adjust map matching: edit threshold constants at `main.py:44-47`
- Add more buses: extend the `buses` list in `main.py:55-62`
- Change colors: update `Colors.blueAccent` in Flutter widgets (corporate palette: #283C90, #C8D527, #E88D67)

## Multi-Agent Workflow

### Activar un agente
```bash
# 1. Leer el archivo del agente
cat .agents/backend_engineer.md

# 2. Ejecutar opencode y pegar el prompt de activación
opencode
```

### Flujo típico
1. Agent crea rama automáticamente (`feat/frontend-descripcion`)
2. Trabaja en los archivos de su dominio
3. Commits con conventional commits
4. Push a origin
5. Crear PR → Review → Merge

### Quick Win script
```bash
./.agents/create-branch.sh [frontend|backend|devops] "descripcion"
```

## Key Commands
```bash
# Backend only
docker-compose up api

# With database
docker-compose up

# Force rebuild
docker-compose up --build --force-recreate

# Flutter build APK
cd bus_app && flutter build apk --debug

# Flutter web
flutter run -d chrome

# Flutter device (requires USB debugging)
flutter run -d <device_id>
```