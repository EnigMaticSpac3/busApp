# Role: Senior Backend Engineer (FastAPI)
# Context: San Antonio Bus Tracker — E598, San Miguelito, Panamá
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
Mantener y extender la API FastAPI con nuevos endpoints para el sprint v3.

---

## ✅ Estado Actual (v2 completado)
- Modelo de sesiones dinámicas (`sesiones_activas` dict)
- Endpoint `POST /api/iniciar-sesion-bus`
- Endpoint `POST /api/contribuir-ubicacion` con promedio ponderado
- Endpoint `GET /api/flota` con modo e incertidumbre
- Monitor de sesiones con geofencing y limpieza automática
- Sin motor de simulación — solo datos reales

---

## 📁 Archivos Bajo Tu Dominio
- `backend_bus_app/app/main.py`
- `backend_bus_app/app/gtfs_san_antonio/*.txt` — Solo lectura
- `backend_bus_app/requirements.txt`
- `backend_bus_app/docker-compose.yml`

---

## 🔧 Tareas Sprint v3

### Tarea 1 — Endpoint GET /api/rutas
```
Rama: feat/backend-endpoint-rutas
```
Lista todas las rutas disponibles leyendo del GTFS.
Incluye cuántos buses activos tiene cada ruta en ese momento.

```python
@app.get("/api/rutas")
async def get_rutas():
    """
    Lee routes.txt del GTFS y devuelve lista de rutas disponibles.
    Incluye buses_activos calculado desde sesiones_activas.
    """
    rutas = leer_csv_gtfs("routes.txt")
    async with _sesiones_lock:
        resultado = []
        for ruta in rutas:
            ruta_id = ruta["route_id"]
            buses_activos = 0
            if ruta_id in sesiones_activas:
                sesion = sesiones_activas[ruta_id]
                ahora = time.time()
                seg = ahora - sesion["ultimo_gps"]
                if seg < 600:  # sesión no expirada
                    buses_activos = sesion.get("contribuidores_activos", 0)

            resultado.append({
                "ruta_id":       ruta_id,
                "codigo":        ruta["route_short_name"],  # "E598"
                "nombre":        ruta["route_long_name"],
                "color":         ruta.get("route_color", "007BFF"),
                "buses_activos": buses_activos,
            })
    return resultado
```

### Tarea 2 — Endpoint GET /api/rutas/{ruta_id}/paradas
```
Rama: feat/backend-endpoint-paradas-por-ruta
```
Devuelve las paradas de una ruta en orden, con su posición
en la secuencia del recorrido.

```python
@app.get("/api/rutas/{ruta_id}/paradas")
async def get_paradas_ruta(ruta_id: str):
    """
    Devuelve paradas ordenadas por secuencia para una ruta específica.
    Lee stop_times.txt y stops.txt del GTFS.
    """
    # Filtrar paradas del trip correspondiente a ruta_id
    # Usar paradas_info ya cargado en memoria
    paradas_ordenadas = sorted(
        [p for p in paradas_info if True],  # filtrar por ruta_id cuando haya múltiples rutas
        key=lambda p: p["indice_ruta"]
    )
    return {
        "ruta_id": ruta_id,
        "paradas": [
            {
                "stop_id":   p["stop_id"],
                "nombre":    p["nombre"],
                "lat":       p["lat"],
                "lon":       p["lon"],
                "secuencia": i,
            }
            for i, p in enumerate(paradas_ordenadas)
        ]
    }
```

---

## 🚀 Big Bets (v4)
1. WebSocket `/ws/flota` — eliminar polling HTTP
2. PostGIS — persistencia de trayectorias reales
3. Soporte múltiples rutas con GTFS independientes
4. Modo conductor oficial

---

## ⚙️ Umbrales actuales (main.py)
```python
UMBRAL_DISTANCIA_RUTA_M = 35.0
UMBRAL_VELOCIDAD_MIN_MS = 1.4
UMBRAL_VELOCIDAD_MAX_MS = 16.0
GEOFENCING_SALIDA_M     = 100.0
TIMEOUT_INCIERTO_S      = 15
TIMEOUT_PERDIDO_S       = 300
TIMEOUT_ELIMINAR_S      = 600
VENTANA_PROMEDIO_S      = 30
```

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama: `git checkout -b tipo/backend-nombre-tarea`
- **NUNCA** modificar archivos de `bus_app/`
- Usar `_sesiones_lock` para todo acceso a `sesiones_activas`
- Un endpoint por PR

## ✅ Definition of Done
- [ ] `GET /api/rutas` devuelve E598 con buses_activos correcto
- [ ] `GET /api/rutas/SA_R1/paradas` devuelve 28 paradas ordenadas
- [ ] Ambos endpoints documentados en `/docs` de FastAPI
- [ ] Commit: `feat(backend): descripción corta`