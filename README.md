# San Antonio Bus Tracker

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green.svg)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)

Sistema de monitoreo en tiempo real para la ruta interna de San Antonio, San Miguelito, Panamá.

## Estado del Proyecto

| Versión | Estado | Descripción |
|---------|--------|-------------|
| **v1** | ✅ Deprecated | Mapa básico, ruta E598, simulación GPS |
| **v2** | ✅ Estable | Sesiones dinámicas, crowdsourcing real |
| **v3** | ✅ Completado | Menú de rutas, ubicación usuario, NavigationBar |
| **v4** | ✅ Completado | WebSocket, animaciones de marcadores |
| **v5A** | ✅ Completado | Modo conductor con autenticación PIN |
| **v5B** | ⬜ Pendiente | Notificaciones push (FCM) |
| **v5C** | ⬜ Pendiente | Planificador de rutas (OpenTripPlanner) |
| **v5D** | ⬜ Pendiente | Deployment Fly.io |

## Características

### Modo Pasajero
- **Mapa en tiempo real** con Flutter Map y OpenStreetMap
- **Crowdsourcing GPS** - contribuye tu ubicación cuando estás en el bus
- **Cálculo de ETA** - tiempo estimado de llegada a cada parada
- **Selección de ruta** - elige qué ruta tomar antes de contribuir

### Modo Conductor
- **Autenticación PIN** - 4 dígitos (gestión manual de conductores)
- **Seguimiento GPS** - envío cada 5 segundos
- **Dead Man's Switch** - alerta si no confirma en 25s
- **Dashboard** - velocidad, duración de sesión, contador de envíos

### Técnico
- **WebSocket** para actualizaciones en tiempo real
- **Polling fallback** si WebSocket falla
- **Map matching** con geofencing - filtra kontribusições fuera de ruta
- **Estados de sesión** - activo (<15s), incierto (15s-5min), perdido (>5min)

## Estructura del Proyecto

```
busApp/
├── backend_bus_app/     # FastAPI backend (Python 3.11)
│   ├── app/
│   │   ├── main.py              # API + sesiones dinámicas + geofencing
│   │   └── gtfs_san_antonio/   # GTFS static data
│   └── docker-compose.yml
├── bus_app/            # Flutter frontend
│   └── lib/
│       ├── screens/           # HomeScreen, MapScreen, RutasScreen, ConductorScreen
│       ├── services/           # ApiService, WebSocketService, AuthService
│       ├── widgets/            # BusMarker, EtaBanner, CrowdsourcingSheet
│       └── config/             # AppConfig (colores, URLs)
└── .opencode/           # Agentes y skills
    └── agents/          # Definiciones de agentes
```

## Instalación

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
# o
flutter run -d chrome     # Web
```

## API Endpoints

### Rutas
- `GET /api/rutas` - Lista de rutas disponibles
- `GET /api/rutas/{ruta_id}/paradas` - Paradas de una ruta

### Flota
- `GET /api/flota` - Estado actual de todos los buses
- `GET /api/parada-cercana/{bus_id}` - ETA a siguiente parada
- `GET /api/ruta` - Puntos de la ruta

### Conductor (v5A)
- `POST /api/auth/conductor` - Autenticación con PIN
- `POST /api/sesion-conductor` - Iniciar sesión de conductor
- `POST /api/gps-conductor` - Enviar posición GPS

### WebSocket
- `WS /ws/flota` - Actualizaciones en tiempo real

## Uso

### Modo Pasajero
1. Abrir app → HomeScreen
2. Tab "Mapa": ver buses en tiempo real
3. Tab "Rutas": seleccionar ruta
4. FAB "Contribuir": activar crowdsourcing

### Modo Conductor
1. Tocar icono 🔧 en AppBar
2. Ingresar PIN de 4 dígitos
3. "Iniciar Seguimiento" para comenzar
4. Confirmar cada 25s con Dead Man's Switch

## Configuración

### Colores Oficiales
- **Primary**: #0256a4 (Azul oscuro)
- **Accent**: #bfd244 (Verde lima)
- **Alert**: #e57a44 (Naranja)
- **Text**: #242423 (Gris oscuro)

### Thresholds
- Distancia a ruta: 35m
- Velocidad: 1.4-16 m/s (~5-60 km/h)
- GPS precisión: >50m rechazado

## Contribuidores e IA

Este proyecto usa OpenCode con agentes especializados y modelos de IA gratuitos (MiniMax M2.5 Free, DeepSeek V4 Flash Free).

## Licencia

MIT License - Ver [LICENSE](LICENSE)