# Git Flow Guide — San Antonio Bus Tracker

## 🌿 Estructura de Ramas

```
main (producción — v3 estable ✅)
  ↑ merge después de QA completo
  ↑
develop (integración — sprint v4 activo)
  ↑
feat/frontend-*   feat/backend-*   chore/devops-*
```

---

## 📋 Nomenclatura

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `feat/` | Nueva funcionalidad | `feat/backend-websocket-flota` |
| `fix/` | Bug fix | `fix/frontend-websocket-reconexion` |
| `chore/` | Infraestructura | `chore/devops-flyio-deployment` |
| `refactor/` | Refactoring | `refactor/frontend-eliminar-polling` |

---

## 🎯 Backlog Sprint v4 — WebSocket + Animaciones + Escalabilidad

### Fase 1 — Backend (bloqueante para WebSocket frontend)

| # | Rama | Descripción | Estado |
|---|------|-------------|--------|
| 1 | `feat/backend-websocket-flota` | WebSocket /ws/flota con broadcast automático | ⬜ |
| 2 | `feat/backend-multiples-rutas` | Soporte múltiples shapes GTFS simultáneos | ⬜ |
| 3 | `feat/backend-modo-conductor` | Registro de conductores con peso x3 en promedio | ⬜ |

### Fase 2 — Frontend

| # | Rama | Descripción | Depende de |
|---|------|-------------|------------|
| 4 | `feat/frontend-websocket-flota` | WebSocketService + fallback HTTP | Backend #1 |
| 5 | `feat/frontend-animacion-marcadores` | Interpolación suave entre posiciones GPS | #4 |
| 6 | `feat/frontend-selector-ruta-contribucion` | Elegir ruta al contribuir (multi-ruta) | Backend #2 |

### Fase 3 — DevOps

| # | Rama | Descripción | Depende de |
|---|------|-------------|------------|
| 7 | `chore/devops-websocket-docker` | Verificar soporte WebSocket en Docker | Backend #1 |
| 8 | `chore/devops-env-example` | .env.example documentado | ninguna |
| 9 | `chore/devops-flyio-deployment` | fly.toml preparado para producción | ninguna |

---

## 📊 Estado del Proyecto

```
v1 ✅  Mapa básico, ruta E598, simulación GPS
v2 ✅  Sesiones dinámicas, crowdsourcing real, validado en campo
v3 ✅  Menú de rutas, ubicación usuario, navegación tabs
v4 ✅  WebSocket, animaciones, múltiples rutas
v5A 🔄 Modo conductor (autenticación PIN, UI conductor, Dead Man's Switch)
v5B ⬜ Notificaciones push (Firebase FCM)
v5C ⬜ Planificador de rutas (OTP)
v5D ⬜ Deployment Fly.io
```

---

## 🎯 Backlog Sprint v5A — Modo Conductor

### Fase 1 — Backend

| # | Rama | Descripción | Estado |
|---|------|-------------|--------|
| 1 | `feat/backend-auth-conductor` | Endpoint POST /api/auth/conductor (verificar PIN) | ⬜ |
| 2 | `feat/backend-sesion-conductor` | Endpoint POST /api/sesion-conductor (8-12h GPS) | ⬜ |
| 3 | `feat/backend-dead-man-switch` | Timeout de 30s para sesiones conductor | ⬜ |

### Fase 2 — Frontend

| # | Rama | Descripción | Depende de |
|---|------|-------------|------------|
| 4 | `feat/frontend-login-conductor` | Pantalla login con opciones Pasajero/Conductor | ninguna |
| 5 | `feat/frontend-pantalla-conductor` | UI minimalista conductor (GPS activo, Dead Man's Switch) | Backend #1-3 |
| 6 | `feat/frontend-detectar-rol` | main.dart detecta rol y muestra pantalla correcta | #4, #5 |

### Fase 3 — DevOps

| # | Rama | Descripción |
|---|------|-------------|
| 7 | `chore/devops-firebase-fcm` | Configurar Firebase para notificaciones push (v5B) |
| 8 | `chore/devops-db-conductores` | Tabla de conductores en DB (gestión manual) |

---

## 🔄 Flujo de Trabajo

```bash
git checkout develop && git pull origin develop
git checkout -b feat/backend-websocket-flota
# ... trabajar ...
git commit -m "feat(backend): implementar WebSocket /ws/flota"
git push -u origin feat/backend-websocket-flota
# PR → develop → merge
git checkout develop && git pull
git branch -d feat/backend-websocket-flota
```

---

## 🔒 Reglas de Oro

1. Una tarea por rama
2. Backend WebSocket antes que frontend WebSocket
3. Nunca push directo a main o develop
4. Mantener /api/flota HTTP como fallback siempre
5. Nunca commitear .env con valores reales
6. Probar WebSocket con `wscat` antes del PR:
   ```bash
   # Instalar wscat para probar WebSocket desde terminal
   npm install -g wscat
   wscat -c ws://localhost:8000/ws/flota
   ```

---

## 💬 Formato de Commits

```
feat(backend): implementar WebSocket /ws/flota con broadcast
feat(frontend): reemplazar polling con WebSocketService
feat(frontend): animación suave de marcadores con interpolación
feat(backend): soporte múltiples rutas GTFS simultáneas
feat(backend): modo conductor con peso x3 en promedio ponderado
chore(devops): preparar fly.toml para deployment en Fly.io
```