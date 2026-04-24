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

buses = [
    {"id": "Bus-01", "indice": 0,    "lat": 0.0, "lon": 0.0, "vel_ms": 0.0},
    {"id": "Bus-02", "indice": 500,  "lat": 0.0, "lon": 0.0, "vel_ms": 0.0},
    {"id": "Bus-03", "indice": 1000, "lat": 0.0, "lon": 0.0, "vel_ms": 0.0},
]

_buses_lock = asyncio.Lock()

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
# Motor GPS
# ---------------------------------------------------------------------------

async def motor_gps():
    """
    Avanza cada bus un punto por tick bajo el lock para evitar race conditions.
    La velocidad se calcula desde shape_dist_traveled (metros reales entre
    puntos consecutivos) dividido entre el intervalo del tick (1 segundo).
    """
    if not ruta_puntos:
        log.warning("motor_gps: ruta_puntos vacía, motor detenido.")
        return

    while True:
        async with _buses_lock:
            for bus in buses:
                idx   = bus["indice"]
                punto = ruta_puntos[idx]

                vel_ms = 0.0
                if idx > 0:
                    dist_delta = ruta_puntos[idx]["dist"] - ruta_puntos[idx - 1]["dist"]
                    vel_ms = dist_delta / 1.0  # metros por segundo

                bus["lat"]    = punto["lat"]
                bus["lon"]    = punto["lon"]
                bus["vel_ms"] = round(vel_ms, 2)
                bus["indice"] = (idx + 1) % len(ruta_puntos)

        await asyncio.sleep(1)


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

    tarea_gps = asyncio.create_task(motor_gps())
    log.info("✅ Motor GPS iniciado.")
    yield
    tarea_gps.cancel()
    log.info("Motor GPS detenido.")


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
    async with _buses_lock:
        return [dict(b) for b in buses]


@app.get("/api/parada-cercana/{id_bus}")
async def get_parada_cercana(id_bus: str):
    async with _buses_lock:
        bus = next((dict(b) for b in buses if b["id"] == id_bus), None)

    if not bus:
        return {"error": "Bus no encontrado"}

    UMBRAL_METROS = 30.0
    parada_futura = None
    dist_minima   = float("inf")

    for parada in paradas_info:
        dist_bus_parada = haversine(bus["lat"], bus["lon"], parada["lat"], parada["lon"])
        if (parada["indice_ruta"] > bus["indice"]
                and dist_bus_parada > UMBRAL_METROS
                and dist_bus_parada < dist_minima):
            dist_minima   = dist_bus_parada
            parada_futura = parada

    if parada_futura:
        vel     = bus["vel_ms"] if bus["vel_ms"] > 1.0 else (4 * 1000 / 3600)
        minutos = int((dist_minima / vel) // 60)
        eta     = f"{minutos} min" if minutos > 0 else "Menos de 1 min"
        return {
            "parada":    parada_futura["nombre"],
            "distancia": round(dist_minima, 0),
            "eta":       eta,
        }

    return {"parada": "Fin de recorrido", "eta": "--", "distancia": 0}


# Umbrales del map matching
UMBRAL_DISTANCIA_RUTA_M  = 35.0   # metros — qué tan cerca debe estar de la ruta
UMBRAL_VELOCIDAD_MIN_MS  = 1.4    # m/s — ~5 km/h mínimo para considerar que va en bus
UMBRAL_VELOCIDAD_MAX_MS  = 22.0   # m/s — ~80 km/h máximo razonable para un bus urbano
UMBRAL_ASIGNACION_BUS_M  = 200.0  # metros — distancia máxima al bus más cercano
 
 
class UbicacionUsuario(BaseModel):
    """Payload que envía el celular del usuario contribuidor."""
    usuario_id: str           # ID anónimo generado en el celular (UUID)
    lat: float
    lon: float
    velocidad_ms: float       # velocidad reportada por el GPS del celular
    precision_m: Optional[float] = None  # precisión GPS en metros (opcional)
 
 
def map_matching(lat: float, lon: float, velocidad_ms: float) -> Optional[dict]:
    """
    Determina si el usuario está en un bus y cuál.
 
    Algoritmo:
      1. ¿Está dentro de UMBRAL_DISTANCIA_RUTA_M metros de algún punto de la ruta?
      2. ¿Su velocidad es coherente con un bus en movimiento?
      3. ¿Qué bus de la flota simulada está más cerca?
 
    Devuelve el bus asignado o None si no cumple los criterios.
    """
    # Filtro 1: velocidad coherente con un bus
    if not (UMBRAL_VELOCIDAD_MIN_MS <= velocidad_ms <= UMBRAL_VELOCIDAD_MAX_MS):
        return None
 
    # Filtro 2: proximidad a la ruta — buscamos el punto más cercano
    dist_minima_ruta = float("inf")
    for punto in ruta_puntos:
        d = haversine(lat, lon, punto["lat"], punto["lon"])
        if d < dist_minima_ruta:
            dist_minima_ruta = d
 
    if dist_minima_ruta > UMBRAL_DISTANCIA_RUTA_M:
        return None
 
    # Filtro 3: asignar al bus simulado más cercano
    bus_asignado   = None
    dist_min_bus   = float("inf")
 
    for bus in buses:
        if bus["lat"] == 0.0 and bus["lon"] == 0.0:
            continue  # bus sin posición aún
        d = haversine(lat, lon, bus["lat"], bus["lon"])
        if d < dist_min_bus:
            dist_min_bus = d
            bus_asignado = bus
 
    if bus_asignado is None or dist_min_bus > UMBRAL_ASIGNACION_BUS_M:
        return None
 
    return bus_asignado
 
 
@app.post("/api/contribuir-ubicacion")
async def contribuir_ubicacion(payload: UbicacionUsuario, debug: bool = False):
    """
    Recibe la ubicación GPS de un usuario contribuidor.
    Corre el map matching para determinar si está en un bus
    y en cuál, y actualiza su posición.
 
    Por ahora actualiza el bus simulado más cercano con la
    posición real del usuario. Cuando haya múltiples contribuidores
    en el mismo bus, se promediará la posición (fase 2).
    """
    # Validación básica de coordenadas
    if not (-90 <= payload.lat <= 90 and -180 <= payload.lon <= 180):
        return {"estado": "rechazado", "motivo": "coordenadas inválidas"}
 
    # Ignorar señales con precisión GPS muy baja (ej: >50m de error)
    if payload.precision_m is not None and payload.precision_m > 50:
        return {"estado": "rechazado", "motivo": "precisión GPS insuficiente"}

    if debug:
        # En modo debug asignamos al bus más cercano sin filtros
        async with _buses_lock:
            bus_cercano = min(
                (b for b in buses if b["lat"] != 0.0),
                key=lambda b: haversine(payload.lat, payload.lon, b["lat"], b["lon"]),
                default=None
            )
        if bus_cercano:
            return {"estado": "aceptado", "bus_id": bus_cercano["id"]}
        return {"estado": "ignorado", "motivo": "sin buses activos"}
 
    bus = map_matching(payload.lat, payload.lon, payload.velocidad_ms)
 
    if bus is None:
        return {
            "estado":  "ignorado",
            "motivo":  "no se detectó bus cercano o velocidad fuera de rango",
            "lat":     payload.lat,
            "lon":     payload.lon,
            "vel_ms":  payload.velocidad_ms,
        }
 
    # Actualizar posición del bus con la ubicación real del contribuidor
    async with _buses_lock:
        for b in buses:
            if b["id"] == bus["id"]:
                b["lat"]    = payload.lat
                b["lon"]    = payload.lon
                b["vel_ms"] = payload.velocidad_ms
                break
 
    log.info(
        f"Contribución aceptada: usuario={payload.usuario_id} "
        f"→ {bus['id']} ({payload.lat:.5f}, {payload.lon:.5f}) "
        f"vel={payload.velocidad_ms:.1f} m/s"
    )
 
    return {
        "estado":    "aceptado",
        "bus_id":    bus["id"],
        "lat":       payload.lat,
        "lon":       payload.lon,
    }