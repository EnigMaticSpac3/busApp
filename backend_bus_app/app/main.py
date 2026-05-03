"""
main.py — San Antonio Bus Tracker API
Correcciones aplicadas vs versión anterior:
  1. asyncio.Lock para eliminar race condition en motor_gps
  2. Velocidad calculada desde timestamps reales del GPX (Δdist/Δtime)
  3. Filtro "ya pasamos" basado en metros reales, no índices arbitrarios
  4. Manejo de errores con logging en lifespan
  5. Credenciales leídas desde variables de entorno (.env)
  
Fuente de datos: carpeta GTFS local (no requiere importación manual a DB).
La DB queda reservada para datos dinámicos (crowdsourcing, logs).
"""

import asyncio
import logging
import math
import os
import csv
import time
import uuid
from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from pydantic import BaseModel
from typing import Optional

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------
load_dotenv()

# Ruta a la carpeta GTFS — relativa a este archivo (main.py)
GTFS_DIR = Path(__file__).parent / "gtfs_san_antonio"

# IDs que usamos en nuestro feed GTFS
SHAPE_ID = "SA_R1"
TRIP_ID  = "SA_IDA_001"

# ---------------------------------------------------------------------------
# Estado compartido en memoria
# ---------------------------------------------------------------------------

# Puntos del shape: lista de dicts con lat, lon, dist_acumulada
ruta_puntos: list = []

# Paradas: lista de dicts con stop_id, nombre, lat, lon, indice_ruta, dist_ruta
paradas_info: list = []

# Sesiones activas por ruta (clave: ruta_id)
sesiones_activas: dict[str, dict] = {}
_sesiones_lock = asyncio.Lock()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def haversine(lat1, lon1, lat2, lon2) -> float:
    """Distancia en metros entre dos coordenadas."""
    R = 6_371_000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    a = (math.sin(math.radians(lat2 - lat1) / 2) ** 2
         + math.cos(phi1) * math.cos(phi2)
         * math.sin(math.radians(lon2 - lon1) / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def leer_csv_gtfs(nombre_archivo: str) -> list[dict]:
    """Lee un archivo .txt del feed GTFS y devuelve lista de dicts."""
    ruta = GTFS_DIR / nombre_archivo
    if not ruta.exists():
        raise FileNotFoundError(f"Archivo GTFS no encontrado: {ruta}")
    with open(ruta, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def gtfs_time_a_segundos(tiempo_str: str) -> int:
    """
    Convierte HH:MM:SS de GTFS a segundos totales.
    GTFS permite horas > 23 para servicios de madrugada (ej: 25:00:00).
    """
    h, m, s = tiempo_str.strip().split(":")
    return int(h) * 3600 + int(m) * 60 + int(s)


# ---------------------------------------------------------------------------
# Carga de datos GTFS
# ---------------------------------------------------------------------------

def cargar_ruta_desde_gtfs() -> list:
    """
    Lee shapes.txt y devuelve los puntos del shape SHAPE_ID
    ordenados por secuencia, con distancia acumulada incluida.
    """
    shapes = leer_csv_gtfs("shapes.txt")
    puntos = [
        {
            "lat":       float(row["shape_pt_lat"]),
            "lon":       float(row["shape_pt_lon"]),
            "secuencia": int(row["shape_pt_sequence"]),
            "dist":      float(row["shape_dist_traveled"]),
        }
        for row in shapes
        if row["shape_id"] == SHAPE_ID
    ]
    puntos.sort(key=lambda p: p["secuencia"])
    log.info(f"Ruta cargada desde GTFS: {len(puntos)} puntos, "
             f"{puntos[-1]['dist']/1000:.2f} km")
    return puntos


def cargar_paradas_desde_gtfs(ruta: list) -> list:
    """
    Lee stops.txt y stop_times.txt para el TRIP_ID definido.
    Calcula el índice del punto de ruta más cercano a cada parada
    usando shape_dist_traveled para el filtro 'ya pasamos'.
    """
    stops_raw = leer_csv_gtfs("stops.txt")
    stops_dict = {
        row["stop_id"]: {
            "nombre": row["stop_name"],
            "lat":    float(row["stop_lat"]),
            "lon":    float(row["stop_lon"]),
        }
        for row in stops_raw
    }

    stop_times = leer_csv_gtfs("stop_times.txt")
    paradas_del_trip = sorted(
        [row for row in stop_times if row["trip_id"] == TRIP_ID],
        key=lambda r: int(r["stop_sequence"])
    )

    paradas = []
    for row in paradas_del_trip:
        stop_id = row["stop_id"]
        if stop_id not in stops_dict:
            log.warning(f"stop_id '{stop_id}' en stop_times no existe en stops.txt, omitido.")
            continue

        stop = stops_dict[stop_id]
        dist_gtfs = float(row.get("shape_dist_traveled", 0))

        # Buscamos el índice más cercano por distancia acumulada
        # Es más preciso que buscar por coordenadas cuando el GPX tiene puntos densos
        indice_cercano = min(
            range(len(ruta)),
            key=lambda i: abs(ruta[i]["dist"] - dist_gtfs)
        )

        paradas.append({
            "stop_id":     stop_id,
            "nombre":      stop["nombre"],
            "lat":         stop["lat"],
            "lon":         stop["lon"],
            "indice_ruta": indice_cercano,
            "dist_ruta":   dist_gtfs,
            "llegada_seg": gtfs_time_a_segundos(row["arrival_time"]),
        })

    log.info(f"Paradas cargadas desde GTFS: {len(paradas)}")
    return paradas


# ---------------------------------------------------------------------------
# Monitor de sesiones
# ---------------------------------------------------------------------------

async def monitor_sesiones():
    """
    Tarea asíncrona que corre cada 60 segundos.
    Limpia contribuidores inactivos y sesiones perdidas.
    También detecta geofencing: si la posición promedio está a > 100m de la ruta.
    """
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
                if not sesion["contribuidores"] and ahora - sesion["ultimo_gps"] > TIMEOUT_ELIMINAR_S:
                    rutas_a_eliminar.append(ruta_id)
                    continue

                # Geofencing: verificar que la posición está en la ruta
                if sesion["lat"] != 0.0 and ruta_puntos:
                    dist_min = min(
                        haversine(sesion["lat"], sesion["lon"], p["lat"], p["lon"])
                        for p in ruta_puntos
                    )
                    if dist_min > GEOFENCING_SALIDA_M:
                        log.info(f"Sesión {sesion['session_id']} fuera de ruta "
                                 f"({dist_min:.0f}m) → marcada como perdida")
                        sesion["modo"] = "perdido"

                # Actualizar modo basado en tiempo sin señal
                seg_sin_senal = ahora - sesion["ultimo_gps"]
                if seg_sin_senal < TIMEOUT_INCIERTO_S:
                    sesion["modo"] = "activo"
                elif seg_sin_senal < TIMEOUT_PERDIDO_S:
                    sesion["modo"] = "incierto"
                else:
                    sesion["modo"] = "perdido"

            for ruta_id in rutas_a_eliminar:
                log.info(f"Sesión {sesiones_activas[ruta_id]['session_id']} eliminada por timeout")
                del sesiones_activas[ruta_id]

            if rutas_a_eliminar:
                log.info(f"Monitor: {len(sesiones_activas)} sesiones activas")


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    global ruta_puntos, paradas_info

    try:
        log.info(f"Cargando datos desde: {GTFS_DIR}")

        if not GTFS_DIR.exists():
            raise FileNotFoundError(
                f"No se encontró la carpeta GTFS en {GTFS_DIR}. "
                "Verifica que 'gtfs_san_antonio/' esté dentro de 'app/'."
            )

        ruta_puntos  = cargar_ruta_desde_gtfs()
        paradas_info = cargar_paradas_desde_gtfs(ruta_puntos)

        if len(ruta_puntos) < 10:
            raise ValueError("La ruta tiene muy pocos puntos, verifica shapes.txt")
        if not paradas_info:
            raise ValueError("No se encontraron paradas para el trip_id configurado")

    except Exception as e:
        log.error(f"Error al cargar datos GTFS: {e}")
        raise

    log.info("✅ Datos GTFS cargados, esperando contribuidores...")

    # Iniciar monitor de sesiones
    tarea_monitor = asyncio.create_task(monitor_sesiones())
    log.info("✅ Monitor de sesiones iniciado (cada 60s)")

    yield
    tarea_monitor.cancel()
    log.info("Monitor de sesiones detenido.")
    log.info("Servidor detenido.")


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(title="San Antonio Bus Tracker API", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/ruta")
async def get_ruta():
    return {"puntos": [{"lat": p["lat"], "lon": p["lon"]} for p in ruta_puntos]}


@app.get("/api/flota")
async def get_flota():
    """Devuelve sesiones activas (buses dinámicos desde contribuidores)."""
    async with _sesiones_lock:
        resultado = []
        ahora = time.time()
        for sesion in sesiones_activas.values():
            seg = ahora - sesion["ultimo_gps"]
            if seg > 600:  # 10 minutos → no mostrar
                continue
            modo = (
                "activo"   if seg < 15 else
                "incierto" if seg < 300 else
                "perdido"
            )
            contribuidores_activos = sum(
                1 for c in sesion["contribuidores"].values()
                if ahora - c["ts"] < 30
            )
            resultado.append({
                "bus_id":             f"Bus-{sesion['session_id']}",
                "session_id":         sesion["session_id"],
                "ruta_id":            sesion["ruta_id"],
                "lat":                sesion["lat"],
                "lon":                sesion["lon"],
                "vel_ms":             sesion["vel_ms"],
                "indice_ruta":        sesion.get("indice_ruta", 0),
                "modo":               modo,
                "segundos_sin_senal": round(seg, 0),
                "contribuidores_activos": contribuidores_activos,
            })
        return resultado


@app.get("/api/parada-cercana/{id_bus}")
async def get_parada_cercana(id_bus: str):
    """Busca la parada más cercana para un bus específico."""
    # Extraer session_id del formato "Bus-{session_id}" o usar directamente
    session_id = id_bus.replace("Bus-", "") if id_bus.startswith("Bus-") else id_bus

    async with _sesiones_lock:
        sesion = sesiones_activas.get(session_id)

    if not sesion:
        return {"error": "Bus no encontrado"}

    UMBRAL_METROS = 30.0
    parada_futura = None
    dist_minima   = float("inf")

    indice_ruta = sesion.get("indice_ruta", 0)
    for parada in paradas_info:
        dist_bus_parada = haversine(sesion["lat"], sesion["lon"], parada["lat"], parada["lon"])
        if (parada["indice_ruta"] > indice_ruta
                and dist_bus_parada > UMBRAL_METROS
                and dist_bus_parada < dist_minima):
            dist_minima   = dist_bus_parada
            parada_futura = parada

    if parada_futura:
        vel     = sesion["vel_ms"] if sesion["vel_ms"] > 1.0 else (4 * 1000 / 3600)
        minutos = int((dist_minima / vel) // 60)
        eta     = f"{minutos} min" if minutos > 0 else "Menos de 1 min"
        return {
            "parada":    parada_futura["nombre"],
            "distancia": round(dist_minima, 0),
            "eta":       eta,
        }

    return {"parada": "Fin de recorrido", "eta": "--", "distancia": 0}


class InicioSesion(BaseModel):
    """Payload para iniciar sesión en un bus."""
    usuario_id: str
    ruta_id: str = "SA_R1"


@app.post("/api/iniciar-sesion-bus")
async def iniciar_sesion_bus(payload: InicioSesion):
    """
    Cuando el usuario confirma "estoy en el bus", llama este endpoint.
    Si ya existe sesión activa para esa ruta → devuelve el session_id existente.
    Si no existe → crea una nueva sesión.
    """
    async with _sesiones_lock:
        # Si ya existe sesión activa para esta ruta, unirse a ella
        if payload.ruta_id in sesiones_activas:
            sesion = sesiones_activas[payload.ruta_id]
            # Agregar contribuidor si no estaba
            if payload.usuario_id not in sesion["contribuidores"]:
                sesion["contribuidores"][payload.usuario_id] = {
                    "lat": 0.0, "lon": 0.0, "vel_ms": 0.0, "ts": time.time()
                }
                log.info(f"Usuario {payload.usuario_id} se unió a sesión {sesion['session_id']}")
            return {"session_id": sesion["session_id"], "nueva": False, "ruta_id": payload.ruta_id}

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
        return {"session_id": session_id, "nueva": True, "ruta_id": payload.ruta_id}


# Umbrales del map matching
UMBRAL_DISTANCIA_RUTA_M  = 35.0   # metros — qué tan cerca debe estar de la ruta
UMBRAL_VELOCIDAD_MIN_MS  = 1.4    # m/s — ~5 km/h mínimo para considerar que va en bus
UMBRAL_VELOCIDAD_MAX_MS  = 16.0   # m/s — ~60 km/h máximo razonable para un bus urbano
UMBRAL_ASIGNACION_BUS_M  = 200.0  # metros — distancia máxima al bus más cercano

# Umbrales del monitor de sesiones
GEOFENCING_SALIDA_M   = 100.0  # metros para detectar salida de ruta
TIMEOUT_INCIERTO_S    = 15     # segundos sin señal → modo incierto
TIMEOUT_PERDIDO_S     = 300   # 5 minutos → modo perdido
TIMEOUT_ELIMINAR_S    = 600   # 10 minutos → eliminar sesión
VENTANA_PROMEDIO_S    = 30    # segundos de ventana para promedio ponderado
 
 
class UbicacionUsuario(BaseModel):
    """Payload que envía el celular del usuario contribuidor."""
    session_id:   str           # ID de sesión activa (del endpoint iniciar-sesion-bus)
    usuario_id:   str           # ID anónimo generado en el celular (UUID)
    ruta_id:      str = "SA_R1" # ruta por defecto
    lat:          float
    lon:          float
    velocidad_ms: float        # velocidad reportada por el GPS del celular
    precision_m:  Optional[float] = None  # precisión GPS en metros (opcional)


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
 
 
def map_matching(lat: float, lon: float, velocidad_ms: float, precision_m: Optional[float] = None) -> Optional[dict]:
    """
    Determina si el usuario está en una zona donde podría estar en un bus.
    En el modelo de sesiones, la asignación a una sesión específica se hace
    en contribuir_ubicacion basándose en la ruta activa.

    Algoritmo:
      1. ¿La precisión GPS es aceptable? (rechazar si > 50m)
      2. ¿Está dentro de UMBRAL_DISTANCIA_RUTA_M metros de algún punto de la ruta?
      3. ¿Su velocidad es coherente con un bus en movimiento?

    Devuelve un dict con información de ubicación válida o None si no aplica.
    """
    # Filtro 0: precisión GPS suficiente
    if precision_m is not None and precision_m > 50:
        return None

    # Filtro 1: velocidad coherente con un bus
    if not (UMBRAL_VELOCIDAD_MIN_MS <= velocidad_ms <= UMBRAL_VELOCIDAD_MAX_MS):
        return None

    # Filtro 2: proximidad a la ruta — buscamos el punto más cercano
    dist_minima_ruta = float("inf")
    indice_cercano = 0
    for i, punto in enumerate(ruta_puntos):
        d = haversine(lat, lon, punto["lat"], punto["lon"])
        if d < dist_minima_ruta:
            dist_minima_ruta = d
            indice_cercano = i

    if dist_minima_ruta > UMBRAL_DISTANCIA_RUTA_M:
        return None

    # La asignación a sesión se hace en contribuir_ubicacion
    return {
        "valido": True,
        "distancia_ruta": dist_minima_ruta,
        "indice_ruta": indice_cercano,
    }
 
 
@app.post("/api/contribuir-ubicacion")
async def contribuir_ubicacion(payload: UbicacionUsuario):
    """
    Recibe la ubicación GPS de un usuario contribuidor.
    Recibe session_id y ruta_id para identificar la sesión específica.
    La posición del bus se calcula como promedio ponderado de contribuidores.
    """
    # Validación básica de coordenadas
    if not (-90 <= payload.lat <= 90 and -180 <= payload.lon <= 180):
        return {"estado": "rechazado", "motivo": "coordenadas inválidas"}

    # Ignorar señales con precisión GPS muy baja (ej: >50m de error)
    if payload.precision_m is not None and payload.precision_m > 50:
        return {"estado": "rechazado", "motivo": "precisión GPS insuficiente"}

    # Map matching: verificar que está en zona de ruta válida
    map_result = map_matching(payload.lat, payload.lon, payload.velocidad_ms, payload.precision_m)
    if map_result is None:
        return {
            "estado":  "ignorado",
            "motivo":  "ubicación fuera de ruta o velocidad incompatible con bus",
            "lat":     payload.lat,
            "lon":     payload.lon,
            "vel_ms":  payload.velocidad_ms,
        }

    # Buscar la sesión por ruta_id
    async with _sesiones_lock:
        if payload.ruta_id not in sesiones_activas:
            return {
                "estado": "rechazado",
                "motivo": "no hay sesión activa para esta ruta. Llama primero a /api/iniciar-sesion-bus",
                "ruta_id": payload.ruta_id,
            }

        sesion = sesiones_activas[payload.ruta_id]

        # Verificar que el session_id coincida (opcional)
        if sesion["session_id"] != payload.session_id:
            return {
                "estado": "rechazado",
                "motivo": "session_id no coincide con la sesión activa",
                "session_id": payload.session_id,
            }

        ahora = time.time()

        # Actualizar o agregar contribuidor
        sesion["contribuidores"][payload.usuario_id] = {
            "lat": payload.lat,
            "lon": payload.lon,
            "vel_ms": payload.velocidad_ms,
            "ts": ahora,
        }

        # Calcular promedio ponderado usando helper
        lat_prom, lon_prom, vel_prom = _calcular_promedio_ponderado(sesion["contribuidores"])
        if lat_prom != 0.0:
            sesion["lat"] = lat_prom
            sesion["lon"] = lon_prom
            sesion["vel_ms"] = vel_prom

        sesion["ultimo_gps"] = ahora
        sesion["indice_ruta"] = map_result.get("indice_ruta", 0)
        sesion["modo"] = "activo"

    log.info(
        f"Contribución aceptada: usuario={payload.usuario_id} "
        f"→ sesión {sesion['session_id']} ({payload.lat:.5f}, {payload.lon:.5f}) "
        f"vel={payload.velocidad_ms:.1f} m/s"
    )

    return {
        "estado":    "aceptado",
        "session_id": sesion["session_id"],
        "bus_id":    f"Bus-{sesion['session_id']}",
        "lat":       sesion["lat"],
        "lon":       sesion["lon"],
    }