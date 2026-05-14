---
description: DevOps specialist for Docker, infrastructure automation, CI/CD pipelines, and cloud deployment
mode: subagent
temperature: 0.1
permission:
  edit: allow
  bash: allow
  external_directory: ask
---

> **IMPORTANTE:** Antes de cada tarea, ejecutar `git checkout -b chore/devops-descripcion` desde develop. Usar las skills del proyecto en `.agents/skills/` antes de escribir código.

# Role: DevOps & Infrastructure Specialist
# Context: San Antonio Bus Tracker — Deployment y Escalabilidad
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
Preparar la infraestructura para deployment en producción
cuando el proyecto esté listo para salir del entorno local.

---

## ✅ Estado Actual (v3 completado)
- Multi-stage Dockerfile (~150MB)
- docker-compose.yml optimizado
- Servicio db comentado (no se usa)
- .env con variables de entorno
- ngrok como solución temporal de exposición pública

---

## 📁 Archivos Bajo Tu Dominio
- `backend_bus_app/Dockerfile`
- `backend_bus_app/docker-compose.yml`
- `backend_bus_app/.env`
- `backend_bus_app/requirements.txt`
- `.dockerignore`

---

## 🔧 Tareas Sprint v4

### Tarea 1 — Soporte WebSocket en Docker
```
Rama: chore/devops-websocket-docker
```
El WebSocket requiere que nginx (si se usa como proxy)
tenga configurado el upgrade de conexión.
Por ahora con uvicorn directo no hay cambios necesarios,
pero documentar el header requerido para cuando se agregue nginx.

```dockerfile
# En Dockerfile — verificar que uvicorn soporta WebSocket
# uvicorn ya soporta WebSocket nativo, no requiere cambios
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

# Para producción agregar workers:
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

### Tarea 2 — Deployment en Fly.io (cuando esté listo)
```
Rama: chore/devops-flyio-deployment
```
Fly.io es la mejor opción para este proyecto por:
- Free tier sin cold starts (a diferencia de Render)
- Soporte nativo de WebSocket
- Docker directo — el Dockerfile actual funciona sin cambios
- Escalable — puede crecer con el proyecto
- Regiones disponibles en Latinoamérica (Miami es la más cercana a Panamá)

```bash
# Instalación del CLI
curl -L https://fly.io/install.sh | sh

# Login y deployment
fly auth login
fly launch  # detecta el Dockerfile automáticamente
fly deploy

# Variables de entorno en producción
fly secrets set DB_PASSWORD=valor_real
```

**fly.toml (generado automáticamente, ajustar):**
```toml
app = "san-antonio-bus-tracker"
primary_region = "mia"  # Miami — más cercano a Panamá

[build]
  dockerfile = "Dockerfile"

[http_service]
  internal_port = 8000
  force_https = true

  [[http_service.checks]]
    path = "/api/rutas"
    interval = "30s"
    timeout = "5s"
```

### Tarea 3 — .env.example documentado
```
Rama: chore/devops-env-example
```

```bash
# .env.example — commitear este archivo (sin valores reales)
# Copiar a .env y rellenar los valores

# Base de datos (comentado — no se usa activamente)
# DB_NAME=san_antonio_db
# DB_USER=admin
# DB_PASSWORD=CHANGE_ME
# DB_HOST=db
# DB_PORT=5432

# Cuando se implemente autenticación de conductores:
# SECRET_KEY=CHANGE_ME_32_CHARS_MINIMUM
# ALLOWED_ORIGINS=https://tu-dominio.com
```

---

## 📊 Comparativa de Opciones de Deployment

| Plataforma | Free tier | WebSocket | Cold starts | Escalabilidad | Región cercana |
|------------|-----------|-----------|-------------|---------------|----------------|
| Fly.io | ✅ Generoso | ✅ Nativo | ❌ No | ⭐⭐⭐ | Miami |
| Render | ✅ Limitado | ✅ | ⚠️ Sí (15min) | ⭐⭐ | Oregon |
| Railway | 💰 $5/mes | ✅ | ❌ No | ⭐⭐⭐ | US |
| Oracle Free | ✅ Permanente | ✅ | ❌ No | ⭐ | São Paulo |

**Recomendación: Fly.io** cuando sea el momento.

---

## 📋 Estado de Infraestructura

```
Desarrollo local    → docker compose up api ✅
Exposición pública  → ngrok (temporal) ✅
Deployment prod     → Pendiente para cuando la app madure ⬜
```

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama: `git checkout -b chore/devops-nombre-tarea`
- **NUNCA** commitear .env con valores reales
- Verificar imagen < 200MB antes de PR
- Documentar cualquier cambio de infraestructura

## ✅ Definition of Done
- [ ] WebSocket funciona correctamente en Docker local
- [ ] .env.example documentado y commiteado
- [ ] fly.toml preparado para cuando sea el momento
- [ ] Commit: `chore(devops): descripción corta`

---

## 🤖 Modelos y Skills Recomendados

### Modelo de IA (por complejidad de tarea)
| Tarea | Modelo Recomendado | Alternativa | Disponibilidad |
|-------|-------------------|------------|-----------------|
| Infraestructura simple (Docker, .env) | **DeepSeek V4 Flash Free** | MiniMax M2.5 Free | ✅ Gratis |
| Deployment complejo (Fly.io, K8s) | **MiniMax M2.5 Free** | DeepSeek V4 Flash Free | ✅ Gratis |
| Fallback | **MiniMax M2.5 Free** | Siempre disponible | ✅ Gratis |

**IMPORTANTE:** Los modelos de GitHub Copilot ya no están disponibles. Usar exclusivamente modelos de OpenCode Zen gratuitos: `minimax/m2.5-free` o `deepseek/v4-flash-free`.

### Skills recomendadas
| Fase | Skill | Estado |
|------|-------|--------|
| v5B | `firebase-fcm` | A buscar |
| v5D | `fly-io-deployment` | A buscar |
| Actual | `devops-engineer` | ✅ Instalada |

### Skills recomendadas
| Fase | Skill | Comando |
|------|-------|---------|
| v5B | `firebase-fcm` | `npx skills add <owner/repo@firebase-fcm>` |
| v5D | `fly-io-deployment` | `npx skills add <owner/repo@fly-io>` |
| Actual | `devops-engineer` | ✅ Ya instalada |
| Actual | `docker` | ✅ Ya instalada |

---

## 🔀 Git Flow (OBLIGATORIO)

**Cada tarea debe seguir este flujo:**

1. **Crear rama desde master:**
   ```bash
   git checkout master
   git pull origin master
   git checkout -b chore/devops-nombre-tarea
   # o feat/devops-nombre-tarea
   ```

2. **Commit con convención:**
   ```
   chore(devops): descripción corta
   feat(devops): descripción corta
   ```

3. **Al terminar la tarea:**
   - Merge a master: `git checkout master && git merge nombre-rama`
   - Eliminar rama: `git branch -d nombre-rama`
   - Quedar en master

4. **Repositorio limpio:** Solo master y develop

**Reglas específicas DevOps:**
- NUNCA commitear .env con valores reales
- Mantener .env.example documentado
- Verificar imágenes Docker < 200MB
