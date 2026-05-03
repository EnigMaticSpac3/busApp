# Role: Senior Backend Engineer (FastAPI)
# Context: San Antonio Bus Tracker — E598, San Miguelito, Panamá
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
Implementar el nuevo modelo de **buses dinámicos** basado en contribuidores reales.
Eliminar la simulación como fuente primaria de verdad.

---

## 📐 Nuevo Modelo de Datos (v2)

### Concepto clave: Sesión única por ruta
En cualquier momento dado, existe **máximo una sesión activa por ruta**.
Cuando el primer usuario confirma "estoy en el E598", se crea la sesión.
Los siguientes usuarios que confirmen se unen como contribuidores adicionales.
La posición del bus se calcula como **promedio ponderado** de todas las señales
recibidas en los últimos 15 segundos (más reciente = más peso).

```
sesiones_activas = {
    "SA_R1": {
        "session_id":     "a1b2c3d4",
        "ruta_id":        "SA_R1",
        "lat":            9.07296,      # promedio ponderado
        "lon":            -79.44488,
        "vel_ms":         8.3,          # promedio ponderado
        "indice_ruta":    1042,
        "modo":           "activo",     # "activo"|"incierto"|"perdido"
        "ultimo_gps":     1714123456.0, # timestamp más reciente
        "contribuidores": {
            "6f9da6f4": {"lat": 9.07296, "lon": -79.44488, "vel_ms": 8.3, "ts": 1714123456.0},
            "a2b3c4d5": {"lat": 9.07301, "lon": -79.44490, "vel_ms": 7.9, "ts": 1714123451.0},
        }
    }
}
```

### Estados del bus
```
"activo"   → al menos un contribuidor envió señal hace < 15s
             → marcador sólido en el mapa
"incierto" → última señal hace 15s - 5 minutos
             → marcador semitransparente, muestra "última señal hace Xm"
"perdido"  → última señal hace > 5 minutos
             → marcador muy transparente, se elimina tras 10 minutos totales
```

### Antes (eliminar)
```python
# ELIMINAR — buses hardcodeados, motor de simulación
buses = [
    {"id": "Bus-01", "indice": 0, ...},
    {"id": "Bus-02", "indice": 500, ...},
    {"id": "Bus-03", "indice": 1000, ...},
]
async def motor_gps(): ...  # ELIMINAR
```

### Ahora
```python
import uuid

# Una entrada por ruta activa
sesiones_activas: dict[str, dict] = {}
# Clave: ruta_id ("SA_R1")
# El session_id vive dentro del dict de la sesión

_sesiones_lock = asyncio.Lock()
```

---

## 📁 Archivos Bajo Tu Dominio
- `backend_bus_app/app/main.py` — API, map matching, sesiones
- `backend_bus_app/app/gtfs_san_antonio/*.txt` — Solo lectura
- `backend_bus_app/requirements.txt`
- `backend_bus_app/docker-compose.yml`

---

## 🔧 Tareas del Sprint v2

### Tarea 1 — Refactor: eliminar simulación y crear estructura de sesiones
```
Rama: refactor/backend-eliminar-simulacion
```
- Eliminar lista `buses` hardcodeada
- Eliminar función `motor_gps()`
- Eliminar `asyncio.create_task(motor_gps())` del lifespan
- Crear `sesiones_activas: dict` y `_sesiones_lock`
- Mantener todo lo demás intacto (GTFS, paradas, haversine)

### Tarea 2 — Endpoint POST /api/iniciar-sesion-bus
```
Rama: feat/backend-sesion-bus-dinamico
```
Cuando el usuario confirma "estoy en el bus", el app llama este endpoint.
Si ya existe sesión activa para esa ruta → devuelve el session_id existente.
Si no existe → crea una nueva sesión.

```python
class InicioSesion(BaseModel):
    usuario_id: str
    ruta_id: str = "SA_R1"

@app.post("/api/iniciar-sesion-bus")
async def iniciar_sesion_bus(payload: InicioSesion):
    async with _sesiones_lock:
        # Si ya existe sesión activa para esta ruta, unirse a ella
        if payload.ruta_id in sesiones_activas:
            sesion = sesiones_activas[payload.ruta_id]
            # Agregar contribuidor si no estaba
            sesion["contribuidores"][payload.usuario_id] = {
                "lat": 0.0, "lon": 0.0, "vel_ms": 0.0, "ts": time.time()
            }
            log.info(f"Usuario {payload.usuario_id} se unió a sesión {sesion['session_id']}")
            return {"session_id": sesion["session_id"], "nueva": False}

        # Crear nueva sesión
        session_id = str(uuid.uuid4())[:8]
        sesiones_activas[payload.ruta_id] = {
            "session_id":    session_id,
            "ruta_id":       payload.ruta_id,
            "lat":           0.0,
            "lon":           0.0,
            "vel_ms":        0.0,
            "indice_ruta":   0,
            "modo":          "incierto",
            "ultimo_gps":    time.time(),
            "contribuidores": {
                payload.usuario_id: {"lat": 0.0, "lon": 0.0, "vel_ms": 0.0, "ts": time.time()}
            }
        }
        log.info(f"Nueva sesión {session_id} creada para ruta {payload.ruta_id}")
        return {"session_id": session_id, "nueva": True}
```

### Tarea 3 — Modificar POST /api/contribuir-ubicacion
```
Rama: feat/backend-contribucion-por-sesion
```
Recibe `session_id` y `ruta_id`. Actualiza el contribuidor específico
y recalcula la posición del bus como promedio ponderado.

```python
class UbicacionUsuario(BaseModel):
    session_id:   str
    usuario_id:   str
    ruta_id:      str = "SA_R1"
    lat:          float
    lon:          float
    velocidad_ms: float
    precision_m:  Optional[float] = None

def _calcular_promedio_ponderado(contribuidores: dict) -> tuple[float, float, float]:
    """
    Promedio ponderado por recencia — señales más recientes tienen más peso.
    Ignora contribuidores sin señal en los últimos 30 segundos.
    """
    ahora = time.time()
    lats, lons, vels, pesos = [], [], [], []

    for datos in contribuidores.values():
        antiguedad = ahora - datos["ts"]
        if antiguedad > 30 or datos["lat"] == 0.0:
            continue
        peso = 1.0 / (1.0 + antiguedad)  # más reciente = más peso
        lats.append(datos["lat"] * peso)
        lons.append(datos["lon"] * peso)
        vels.append(datos["vel_ms"] * peso)
        pesos.append(peso)

    if not pesos:
        return 0.0, 0.0, 0.0

    total = sum(pesos)
    return sum(lats)/total, sum(lons)/total, sum(vels)/total
```

### Tarea 4 — Modificar GET /api/flota
```
Rama: feat/backend-flota-desde-sesiones
```
Devuelve sesiones activas con `segundos_sin_senal` y `modo` calculado.
Incluye también cuántos contribuidores activos tiene la sesión.

```python
@app.get("/api/flota")
async def get_flota():
    ahora = time.time()
    async with _sesiones_lock:
        resultado = []
        for sesion in sesiones_activas.values():
            seg = ahora - sesion["ultimo_gps"]
            if seg > 600:  # 10 minutos → no mostrar
                continue
            modo = (
                "activo"   if seg < 15  else
                "incierto" if seg < 300 else
                "perdido"
            )
            contribuidores_activos = sum(
                1 for c in sesion["contribuidores"].values()
                if ahora - c["ts"] < 30
            )
            resultado.append({
                **sesion,
                "modo":                  modo,
                "segundos_sin_senal":    round(seg, 0),
                "contribuidores_activos": contribuidores_activos,
                # No exponer datos internos de cada contribuidor
                "contribuidores":        {},
            })
    return resultado
```

### Tarea 5 — GET /api/ruta devuelve también puntos para geofencing
```
Rama: feat/backend-ruta-con-puntos-geofencing
```
El frontend necesita los puntos de la ruta para hacer geofencing local
(detectar si el usuario salió de la ruta sin necesitar llamar al backend).
El endpoint ya devuelve los puntos — verificar que incluye suficiente
densidad (cada ~10m es ideal para geofencing preciso).

```python
@app.get("/api/ruta")
async def get_ruta():
    return {
        "ruta_id": SHAPE_ID,
        "puntos": [{"lat": p["lat"], "lon": p["lon"]} for p in ruta_puntos]
    }
# Sin cambios al código — solo verificar que los 1730 puntos son suficientes
```

### Tarea 6 — Monitor de limpieza de sesiones perdidas
```
Rama: feat/backend-monitor-sesiones
```
Tarea asíncrona que corre cada 60s.
Limpia contribuidores inactivos y sesiones perdidas.
También detecta geofencing: si la posición promedio está a > 100m de la ruta.

```python
async def monitor_sesiones():
    while True:
        await asyncio.sleep(60)
        ahora = time.time()
        async with _sesiones_lock:
            rutas_a_eliminar = []
            for ruta_id, sesion in sesiones_activas.items():
                # Limpiar contribuidores sin señal en 60s
                sesion["contribuidores"] = {
                    uid: datos for uid, datos in sesion["contribuidores"].items()
                    if ahora - datos["ts"] < 60
                }
                # Si no quedan contribuidores y han pasado 10 minutos → eliminar
                if not sesion["contribuidores"] and ahora - sesion["ultimo_gps"] > 600:
                    rutas_a_eliminar.append(ruta_id)
                    continue
                # Geofencing: verificar que la posición está en la ruta
                if sesion["lat"] != 0.0:
                    dist_min = min(
                        haversine(sesion["lat"], sesion["lon"], p["lat"], p["lon"])
                        for p in ruta_puntos
                    )
                    if dist_min > 100:
                        log.info(f"Sesión {sesion['session_id']} fuera de ruta "
                                 f"({dist_min:.0f}m) → marcada como perdida")
                        sesion["modo"] = "perdido"

            for ruta_id in rutas_a_eliminar:
                log.info(f"Sesión {sesiones_activas[ruta_id]['session_id']} eliminada por timeout")
                del sesiones_activas[ruta_id]
```

---

## 🚀 Big Bets (v3)
1. WebSocket `/ws/flota` — eliminar polling HTTP
2. PostGIS — tabla `sesiones_bus` con trayectorias reales persistidas
3. Integración Google Maps Traffic API para ETAs más precisos
4. Modo conductor oficial (registro con credenciales de MiBus/alcaldía)

---

## ⚙️ Umbrales (main.py)
```python
UMBRAL_DISTANCIA_RUTA_M = 35.0    # map matching: metros a la ruta
UMBRAL_VELOCIDAD_MIN_MS = 1.4     # ~5 km/h mínimo
UMBRAL_VELOCIDAD_MAX_MS = 16.0    # ~60 km/h máximo
GEOFENCING_SALIDA_M     = 100.0   # metros para detectar salida de ruta
TIMEOUT_INCIERTO_S      = 15      # segundos sin señal → modo incierto
TIMEOUT_PERDIDO_S       = 300     # 5 minutos → modo perdido
TIMEOUT_ELIMINAR_S      = 600     # 10 minutos → eliminar sesión
VENTANA_PROMEDIO_S      = 30      # segundos de ventana para promedio ponderado
```

---

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama: `git checkout -b tipo/backend-nombre-tarea`
- **NUNCA** modificar archivos de `bus_app/`
- **ANTES** de escribir código: listar archivos a tocar y justificar
- Usar `_sesiones_lock` para todo acceso a `sesiones_activas`
- Un endpoint por PR — no mezclar cambios no relacionados

## ✅ Definition of Done
- [ ] `docker compose up api` arranca sin errores
- [ ] `GET /api/flota` devuelve `[]` si no hay contribuidores
- [ ] `POST /api/iniciar-sesion-bus` crea sesión y devuelve session_id
- [ ] Segundo usuario llamando `/api/iniciar-sesion-bus` recibe el mismo session_id
- [ ] `POST /api/contribuir-ubicacion` actualiza posición con promedio ponderado
- [ ] Sesión desaparece de `/api/flota` tras 10 minutos sin señal
- [ ] Commit: `feat(backend): descripción corta`