# Git Flow Guide — San Antonio Bus Tracker

## 🌿 Estructura de Ramas

```
main (producción — v2 estable validado en campo ✅)
  ↑ merge después de QA completo
  ↑
develop (integración — sprint v3 activo)
  ↑ merge después de code review
  ↑
feat/frontend-*     feat/backend-*     chore/devops-*
```

---

## 📋 Nomenclatura de Ramas

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `feat/` | Nueva funcionalidad | `feat/frontend-navigation-bar` |
| `fix/` | Bug fix | `fix/backend-endpoint-rutas` |
| `chore/` | Infraestructura | `chore/devops-comentar-db-docker` |
| `refactor/` | Refactoring | `refactor/frontend-api-service` |

---

## 🎯 Backlog Sprint v3 — Menú de Rutas + UX

### Fase 1 — Backend (bloqueante para frontend tabs 3 y 4)

| # | Rama | Descripción | Estado |
|---|------|-------------|--------|
| 1 | `feat/backend-endpoint-rutas` | GET /api/rutas — lista rutas desde GTFS con buses_activos | ⬜ |
| 2 | `feat/backend-endpoint-paradas-por-ruta` | GET /api/rutas/{ruta_id}/paradas — paradas ordenadas | ⬜ |

### Fase 2 — Frontend (tareas 1-2 independientes, 3-4 dependen de backend)

| # | Rama | Descripción | Depende de |
|---|------|-------------|------------|
| 3 | `feat/frontend-navigation-bar` | HomeScreen + BottomNavigationBar (Mapa/Rutas) | ninguna |
| 4 | `feat/frontend-modelo-ruta` | RutaModel y ParadaModel | ninguna |
| 5 | `feat/frontend-rutas-screen` | Lista de rutas con código y buses activos | Backend #1 + Frontend #3,#4 |
| 6 | `feat/frontend-ruta-detalle-screen` | Lista de paradas, toca → mapa centrado | Backend #2 + Frontend #5 |
| 7 | `feat/frontend-ubicacion-usuario` | Punto azul con posición del usuario en mapa | ninguna |
| 8 | `feat/frontend-boton-centrar-ubicacion` | FAB que centra el mapa en el usuario | Frontend #7 |

### Fase 3 — DevOps

| # | Rama | Descripción |
|---|------|-------------|
| 9 | `chore/devops-comentar-db-docker` | Comentar servicio db en docker-compose |
| 10 | `chore/devops-env-example` | Crear .env.example documentado |

---

## 🚀 Flujo de Trabajo

```bash
# 1. Partir de develop actualizado
git checkout develop
git pull origin develop

# 2. Crear rama
git checkout -b feat/backend-endpoint-rutas

# 3. Commits atómicos
git add backend_bus_app/app/main.py
git commit -m "feat(backend): agregar endpoint GET /api/rutas"

# 4. Push y PR → develop
git push -u origin feat/backend-endpoint-rutas

# 5. Limpieza tras merge
git checkout develop
git pull origin develop
git branch -d feat/backend-endpoint-rutas
```

---

## 📊 Estado del Proyecto

```
v1 ✅  Mapa básico, ruta E598, simulación GPS
v2 ✅  Sesiones dinámicas, crowdsourcing real, validado en campo
v3 🔄  Menú de rutas, ubicación usuario, navegación tabs (EN PROGRESO)
v4 ⬜  WebSocket, PostGIS, múltiples rutas, modo conductor
```

---

## 🔒 Reglas de Oro

1. **Una tarea por rama**
2. **Commits atómicos**
3. **Nunca push directo a main o develop**
4. **Backend antes que frontend** cuando hay dependencias
5. **Nunca commitear .env con valores reales**
6. **Probar en Chrome Y dispositivo físico antes de PR**

---

## 💬 Formato de Commits

```
feat(backend): agregar endpoint GET /api/rutas
feat(frontend): implementar NavigationBar con tabs Mapa/Rutas
fix(frontend): corregir centrado de mapa en ubicación usuario
chore(devops): comentar servicio db en docker-compose
```