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
| **v5** | ⬜ Planificación | Modo conductor, notificaciones push, OTP, deployment |

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

**Problemas a resolver:**
| Problema actual | Solución v5 |
|-----------------|-------------|
| Crowdsourcing pasajero | Modo conductor (1 dispositivo por bus) |
| App siempre abierta | Notificaciones push (FCM gratuito) |
| Mapa activo = robo | Alerta de proximidad en pantalla bloqueada |
| Sin planificador | OpenTripPlanner (OTP) + GTFS local |
| ngrok temporal | Fly.io (cuando haya MVP funcional) |

**Roadmap v5:**

| Fase | Descripción |
|------|-------------|
| v5A | Modo conductor: autenticación simple, detección de rol, UI minimalista, sesión GPS 8-12h, "Dead Man's Switch" |
| v5B | Notificaciones push: Firebase FCM, geofencing servidor (bus a 500m → push) |
| v5C | Planificador de rutas: OpenTripPlanner, GTFS local + OSM Panamá |
| v5D | Deployment Fly.io |

**Decisiones tomadas:**
1. Una sola app con dos modos (conductor/pasajero según credenciales)
2. Firebase gratuito (FCM sin costo)
3. Modo conductor primero
4. Conductores manejados manualmente (MVP)

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

## 🎨 Paleta de Colores Oficial

```css
/* Colores base */
--color-primary: #0256a4;        /* Azul oscuro - AppBar, botones principales */
--color-primary-secondary: #2f74ad;  /* Azul medio */
--color-accent: #bfd244;         /* Verde/lima - destacados, acciones */
--color-alert: #e57a44;          /* Naranja - buses, alertas, estado incierto */
--color-text: #242423;           /* Gris oscuro - texto */

/* Ramps */
--color-blue-50: #e8f2fa;
--color-blue-300: #7ab3e0;
--color-blue-600: #2f74ad;
--color-blue-900: #013a70;

--color-lime-50: #f4f8d0;
--color-lime-300: #d4e46a;
--color-lime-600: #8fa020;
--color-lime-900: #576010;

--color-orange-50: #fdf0e8;
--color-orange-300: #f0ac80;
--color-orange-600: #b85520;
--color-orange-900: #7a2f0e;

--color-gray-50: #f0f0ef;
--color-gray-300: #868684;
--color-gray-600: #484846;
--color-gray-900: #101010;

/* Superficies */
--surface-primary: #ffffff;
--surface-secondary: #f2f2f0;
--surface-info: #e8f2fa;
--surface-success: #f4f8d0;
--surface-warning: #fdf0e8;
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

---

## 🤖 Modelos de IA Recomendados (por agente)

| Agente | Modelo Principal | Alternativa | Fallback |
|--------|------------------|------------|----------|
| **Backend** (FastAPI, Python) | GPT-4.1 | Deepseek V4 Flash | MiniMax M2.5 |
| **Frontend** (Flutter, Dart, UI) | GPT-4o | GPT-4.1 | MiniMax M2.5 |
| **DevOps** (Docker, infraestructura) | Deepseek V4 Flash | MiniMax M2.5 | Siempre disponible |
| **Documentación** (.md, planning) | GPT-5-mini | Deepseek V4 Flash | MiniMax M2.5 |

**Nota:** GitHub Copilot proporciona acceso gratuito a GPT-4.1 y GPT-4o. Cuando se agoten los créditos, usa Deepseek V4 Flash como alternativa.

---

## 📦 Skills Recomendadas (por fase)

### Instaladas Actualmente ✅
- `devops-engineer` — Docker, CI/CD, infraestructura
- `fastapi-python` — Backend FastAPI con async
- `flutter-add-widget-test` — Tests de widgets en Flutter
- `security-review` — Autenticación, APIs seguras
- `find-skills` — Descubrir skills del ecosistema

### Para v5A (Modo Conductor) - Próximas a instalar
```bash
npx skills find jwt-authentication
npx skills find flutter-background-location
```

### Para v5B (Notificaciones) - A buscar
```bash
npx skills find firebase-fcm
```

### Para v5C (Planificador) - A buscar
```bash
npx skills find opentrip-planner
npx skills find gtfs
npx skills find postgis
```

### Útiles en General - Opcional
```bash
npx skills find websocket-optimization
npx skills find fly-io-deployment
npx skills find flutter-development
```

---

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