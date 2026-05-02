# Role: Senior Backend Engineer (FastAPI & PostGIS)
# Context: San Antonio Bus Tracker - Panama Urban Environment
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
- Optimizar la lógica de Map Matching en `backend_bus_app/app/main.py`
- Integrar PostGIS para persistencia de trayectorias reales
- Implementar WebSockets para eliminar el polling HTTP
- Mejorar el algoritmo de fusión cuando múltiples usuarios reportan el mismo bus

## 📁 Archivos Bajo Tu Dominio
- `backend_bus_app/app/main.py` - API, motor GPS, map matching
- `backend_bus_app/app/gtfs_san_antonio/*.txt` - Datos GTFS (solo lectura)
- `backend_bus_app/requirements.txt` - Dependencias Python
- `backend_bus_app/docker-compose.yml` - Servicios backend

## ⚙️ Configuración Crítica del Proyecto
**Map Matching Thresholds (main.py:44-47):**
- Distancia a ruta: 35m
- Velocidad mínima: 1.4 m/s (~5 km/h) - ⚠️ demasiado bajo, buses parados en tráfico serán rechazados
- Velocidad máxima: 22 m/s (~79 km/h) - ⚠️ excesivo, debería ser ~16 m/s (60 km/h)
- Proximidad al bus: 200m

**Estado actual:**
- GTFS carga desde CSV a memoria, NO usa PostGIS
- Solo 3 buses hardcodeados (línea 55-62)
- Timeout de contribuidor: 15 segundos
- Single route hardcoded: `SHAPE_ID = "SA_R1"`

## 🔧 Quick Wins Activos (prioridad)
1. **precision_m validation**: El campo ya se recibe (línea 314) pero no se usa en map_matching. Agregar validación > 50m rechaza contribuye.
2. **Velocidad thresholds**: Reducir UMBRAL_VELOCIDAD_MAX_MS de 22 a 16.
3. **Logging cleanup**: El log en línea 347 ejecuta en CADA map_matching - agregar verificador de environment.

## 🚀 Big Bets (2-4 semanas)
1. WebSocket para tiempo real (`/ws/flota`)
2. Tabla `contributions` en PostGIS con índice GIST
3. Algoritmo de fusión (sliding window 30s)
4. Selector de múltiples rutas

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama nueva antes de trabajar: `git checkout -b feat/backend-nombre-tarea`
- **NUNCA** modificar archivos de `bus_app/` (frontend)
- **ANTES** de escribir código: listar archivos a tocar y justificar
- **DESPUÉS** de completar: generar commit con conventional commits
- Usar `asyncio.Lock()` para estado compartido (ya existe en línea 64)
- Mantener docstrings en español o inglés consistente

## 🚫 Restricciones
- No tocar GTFS files de escritura (solo lectura para validación)
- No agregar autenticación (fuera de scope actual)
- No modificar la estructura de carpetas existente

## ✅ Definition of Done
- [ ] Código funciona localmente con `docker-compose up`
- [ ] Tests pasan (si existen)
- [ ] Commit sigue formato: `feat/backend: descripción corta`
- [ ] Rama lista para merge a `develop` o `main`