# Role: DevOps & Infrastructure Specialist
# Context: Dockerization & Deployment — San Antonio Bus Tracker
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
Mantener la infraestructura Docker eficiente y preparar el proyecto
para deployment en producción cuando sea necesario.

---

## ✅ Quick Wins Completados
- Multi-stage Dockerfile implementado (~150MB)
- .dockerignore creado
- docker-compose.yml optimizado con healthchecks y red aislada
- Variables de entorno en .env

---

## 🔧 Quick Wins Activos

### 1. Eliminar servicio db del docker-compose
```
Rama: chore/devops-eliminar-db-inutilizada
```
PostGIS corre pero no se usa. Eliminar para ahorrar ~300MB RAM.

```yaml
# docker-compose.yml — eliminar bloque db completo
# Solo dejar:
services:
  api:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./app:/app
    env_file:
      - .env
    restart: unless-stopped
```

### 2. Script de startup para desarrollo
```
Rama: chore/devops-dev-startup-script
```
Automatizar el proceso de iniciar sesión de desarrollo:

```bash
#!/bin/bash
# dev-start.sh — ejecutar desde backend_bus_app/

echo "🚌 Iniciando San Antonio Bus Tracker..."

# 1. Levantar backend
docker compose up api -d
echo "✅ Backend en http://localhost:8000"

# 2. Recordar ngrok
echo "⚡ Para exponer al exterior: ngrok http 8000"
echo "   Luego actualiza app_config.dart con la URL de ngrok"

# 3. Mostrar logs
docker compose logs api -f
```

### 3. Variables de entorno para producción
```
Rama: chore/devops-env-produccion
```
Preparar `.env.example` con todas las variables documentadas
(sin valores reales) para que otros desarrolladores puedan configurar.

```bash
# .env.example
DB_NAME=san_antonio_db
DB_USER=admin
DB_PASSWORD=CHANGE_ME
DB_HOST=db
DB_PORT=5432

# Cuando se implemente autenticación:
# SECRET_KEY=CHANGE_ME
# ALLOWED_ORIGINS=https://tu-dominio.com
```

---

## 🚀 Big Bets (v3)

### Deployment en producción
Cuando la app esté lista para salir del entorno local:

**Opción recomendada: Railway.app**
- Costo: ~$5/mes
- Docker nativo — el Dockerfile actual funciona sin cambios
- URL fija (elimina la necesidad de ngrok)
- PostgreSQL/PostGIS disponible como addon

```bash
# Cuando sea el momento:
npm install -g @railway/cli
railway login
railway init
railway up
```

**Alternativa: Render.com**
- Free tier disponible (con cold starts)
- También soporta Docker directamente

### nginx como reverse proxy
Cuando haya múltiples servicios (API + WebSocket + frontend web):
```nginx
location /api/ { proxy_pass http://api:8000; }
location /ws/  { proxy_pass http://api:8000; upgrade websocket; }
```

---

## 📋 Estado Actual de Infraestructura
```
docker-compose up api     → API en localhost:8000 ✅
ngrok http 8000           → URL pública temporal ✅
PostGIS                   → Corre pero sin uso activo ⚠️
Deployment producción     → Pendiente ⬜
```

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama: `git checkout -b chore/devops-nombre-tarea`
- **NUNCA** commitear archivos .env con valores reales
- Verificar con `docker build --no-cache` antes de PR
- Tamaño objetivo de imagen: < 200MB

## ✅ Definition of Done
- [ ] `docker compose up api` arranca en < 10 segundos
- [ ] Imagen final < 200MB (`docker images`)
- [ ] .env.example documentado y commiteado
- [ ] Sin secretos en el código fuente
- [ ] Commit: `chore(devops): descripción corta`