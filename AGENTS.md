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
└── bus_app/            # Flutter frontend
    └── lib/
        ├── main.dart
        ├── screens/map_screen.dart
        ├── services/           # API + crowdsourcing services
        └── config/app_config.dart
```

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
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## Critical Configurations

- **Backend URL** in `bus_app/lib/config/app_config.dart:11` - currently points to ngrok tunnel (change to `http://192.168.X.X:8000` for local physical device testing)
- **Debug crowdsourcing** in `app_config.dart:22` - defaults to `false`, set to `true` to bypass map matching validation
- **Polling intervals**: Fleet every 2s (`app_config.dart:15`), GPS contribution every 5s

## Map Matching Thresholds (in `backend_bus_app/app/main.py:44-47`)
- Distance to route: 35m (acceptable for urban Panama)
- Speed: 1.4-22 m/s (~5-79 km/h) - upper limit too high, buses rarely exceed 60 km/h
- Bus assignment proximity: 200m

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

## Key Commands
```bash
# Backend only
docker-compose up api

# With database
docker-compose up

# Force rebuild
docker-compose up --build --force-recreate

# Flutter web
flutter run -d chrome

# Flutter device (requires USB debugging)
flutter run -d <device_id>
```