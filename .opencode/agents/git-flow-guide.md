# Git Flow Guide — San Antonio Bus Tracker

## 🌿 Estructura de Ramas

```
main (producción — solo versiones estables)
  ↑ merge después de QA completo en campo
  ↑
develop (integración — rama base de trabajo)
  ↑ merge después de code review
  ↑
feat/frontend-*     feat/backend-*     chore/devops-*     refactor/backend-*
```

**Regla de oro: nunca trabajar directamente en `main` o `develop`.**

---

## 📋 Nomenclatura de Ramas

**Formato:** `tipo/agente-descripcion-corta`

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `feat/` | Nueva funcionalidad | `feat/frontend-marcador-incertidumbre` |
| `fix/` | Bug fix | `fix/backend-geofencing-salida-ruta` |
| `chore/` | Infraestructura, config | `chore/devops-comentar-db-docker` |
| `refactor/` | Refactoring sin cambiar comportamiento | `refactor/backend-eliminar-simulacion` |

---

## 🚀 Flujo de Trabajo

```bash
# 1. Partir siempre desde develop actualizado
git checkout develop
git pull origin develop

# 2. Crear rama para la tarea
git checkout -b feat/backend-sesion-bus-dinamico

# 3. Trabajar — commits atómicos por cambio lógico
git add backend_bus_app/app/main.py
git commit -m "feat(backend): agregar endpoint POST /api/iniciar-sesion-bus"

# 4. Push y Pull Request → develop
git push -u origin feat/backend-sesion-bus-dinamico
# En GitHub: PR de feat/* → develop → merge

# 5. Limpieza local
git checkout develop
git pull origin develop
git branch -d feat/backend-sesion-bus-dinamico
```

---

## 🎯 Backlog Sprint v2 — Buses Dinámicos

**Orden de ejecución obligatorio** — las tareas de backend deben completarse
antes de las de frontend que dependen de los nuevos endpoints.

### Fase 1 — Backend (bloqueante para frontend)

| # | Rama | Descripción | Dependencias |
|---|------|-------------|--------------|
| 1 | `refactor/backend-eliminar-simulacion` | Eliminar lista buses hardcodeada y motor_gps(). Crear sesiones_activas dict. | ninguna |
| 2 | `feat/backend-sesion-bus-dinamico` | Endpoint POST /api/iniciar-sesion-bus. Sesión única por ruta, múltiples contribuidores. | #1 |
| 3 | `feat/backend-contribucion-por-sesion` | Modificar /api/contribuir-ubicacion para recibir session_id. Promedio ponderado. | #2 |
| 4 | `feat/backend-flota-desde-sesiones` | Modificar /api/flota para devolver sesiones con modo e incertidumbre. | #1 |
| 5 | `feat/backend-monitor-sesiones` | Tarea async de limpieza, geofencing y timeout de sesiones. | #1 |

### Fase 2 — Frontend (puede iniciar cuando Fase 1 esté en develop)

| # | Rama | Descripción | Dependencias |
|---|------|-------------|--------------|
| 6 | `feat/frontend-modelo-bus-sesion` | Nuevo modelo BusSesion con opacidad dinámica y etiqueta de tiempo. | Backend #4 |
| 7 | `feat/frontend-marcador-incertidumbre` | Marcador con opacidad según modo activo/incierto/perdido. | #6 |
| 8 | `feat/frontend-confirmacion-subida` | Bottom sheet "¿Subiste al E598?" → llama /api/iniciar-sesion-bus → guarda session_id. | Backend #2 |
| 9 | `feat/frontend-geofencing-local` | CrowdsourcingService detecta salida de ruta usando puntos de /api/ruta. Detiene contribución automáticamente. | #8 |
| 10 | `feat/frontend-mensaje-sin-buses` | Banner "No hay buses activos" cuando /api/flota devuelve []. | #6 |

### Fase 3 — DevOps (puede hacerse en paralelo)

| # | Rama | Descripción |
|---|------|-------------|
| 11 | `chore/devops-comentar-db-docker` | Comentar servicio db en docker-compose (no eliminar, puede ser necesario para PostGIS en v3). |
| 12 | `chore/devops-env-example` | Crear .env.example documentado sin valores reales. |

---

## 📊 Estado de Ramas

```
main     ← v1 estable — crowdsourcing básico con simulación
develop  ← rama activa — apunta a v2
```

---

## 🔒 Reglas de Oro

1. **Una tarea por rama** — no mezclar feat con fix
2. **Commits atómicos** — un cambio lógico por commit
3. **Nunca push directo a main o develop**
4. **Siempre partir de develop actualizado**
5. **Borrar ramas después del merge**
6. **Nunca commitear .env con valores reales**
7. **Backend antes que frontend** — respetar el orden de dependencias

---

## 💬 Formato de Commits (Conventional Commits)

```
feat(backend): agregar endpoint iniciar-sesion-bus
feat(backend): calcular posición con promedio ponderado
fix(frontend): corregir opacidad marcador incierto
chore(devops): comentar servicio db en docker-compose
refactor(backend): reemplazar buses hardcodeados por sesiones_activas
docs: actualizar AGENTS.md con modelo v2
```

---

## 🔗 Referencias
- Conventional Commits: https://www.conventionalcommits.org/
- Git Flow: https://nvie.com/posts/a-successful-git-branching-model/