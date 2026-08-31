"""
Servicio de carga y cache de datos GTFS en memoria.
"""

import csv
import logging
from pathlib import Path
from typing import Optional
from ..core.config import GTFS_DIR, SHAPE_ID, TRIP_ID

log = logging.getLogger(__name__)

# Cache en memoria
_ruta_puntos: list = []
_paradas_info: list = []
_paradas_cache: dict[str, list] = {}
_shape_to_route_code: dict[str, str] = {}
_routes_cache: Optional[list] = None


def get_ruta_puntos() -> list:
    return _ruta_puntos


def get_paradas_info() -> list:
    return _paradas_info


def get_shape_to_route_code() -> dict:
    return _shape_to_route_code


def get_routes() -> list:
    return _routes_cache or []


def _leer_csv_gtfs(nombre_archivo: str) -> list[dict]:
    ruta = GTFS_DIR / nombre_archivo
    if not ruta.exists():
        raise FileNotFoundError(f"Archivo GTFS no encontrado: {ruta}")
    with open(ruta, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def _gtfs_time_a_segundos(tiempo_str: str) -> int:
    h, m, s = tiempo_str.strip().split(":")
    return int(h) * 3600 + int(m) * 60 + int(s)


def cargar_ruta_desde_gtfs() -> list:
    shapes = _leer_csv_gtfs("shapes.txt")
    puntos = [
        {
            "lat": float(row["shape_pt_lat"]),
            "lon": float(row["shape_pt_lon"]),
            "secuencia": int(row["shape_pt_sequence"]),
            "dist": float(row["shape_dist_traveled"]),
        }
        for row in shapes
        if row["shape_id"] == SHAPE_ID
    ]
    puntos.sort(key=lambda p: p["secuencia"])
    log.info(f"Ruta cargada desde GTFS: {len(puntos)} puntos, {puntos[-1]['dist']/1000:.2f} km")
    return puntos


def cargar_paradas_desde_gtfs(ruta: list) -> list:
    stops_raw = _leer_csv_gtfs("stops.txt")
    stops_dict = {
        row["stop_id"]: {
            "nombre": row["stop_name"],
            "lat": float(row["stop_lat"]),
            "lon": float(row["stop_lon"]),
        }
        for row in stops_raw
    }

    stop_times = _leer_csv_gtfs("stop_times.txt")
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

        indice_cercano = min(
            range(len(ruta)),
            key=lambda i: abs(ruta[i]["dist"] - dist_gtfs)
        )

        paradas.append({
            "stop_id": stop_id,
            "nombre": stop["nombre"],
            "lat": stop["lat"],
            "lon": stop["lon"],
            "indice_ruta": indice_cercano,
            "dist_ruta": dist_gtfs,
            "llegada_seg": _gtfs_time_a_segundos(row["arrival_time"]),
        })

    log.info(f"Paradas cargadas desde GTFS: {len(paradas)}")
    return paradas


def obtener_paradas_por_ruta(ruta_id: str) -> list:
    if ruta_id in _paradas_cache:
        return _paradas_cache[ruta_id]

    try:
        trips = _leer_csv_gtfs("trips.txt")
        trips_ruta = [t for t in trips if t.get("route_id", "") == ruta_id]

        if not trips_ruta:
            log.info(f"Ruta '{ruta_id}' no encontrada en trips.txt — sin paradas")
            _paradas_cache[ruta_id] = []
            return []

        trip_id = trips_ruta[0]["trip_id"]
        shape_id = trips_ruta[0].get("shape_id", "")

        shapes = _leer_csv_gtfs("shapes.txt")
        shape_puntos = [
            {
                "lat": float(row["shape_pt_lat"]),
                "lon": float(row["shape_pt_lon"]),
                "secuencia": int(row["shape_pt_sequence"]),
                "dist": float(row["shape_dist_traveled"]),
            }
            for row in shapes
            if row["shape_id"] == shape_id
        ]
        shape_puntos.sort(key=lambda p: p["secuencia"])

        if not shape_puntos:
            log.warning(f"No se encontró shape '{shape_id}' para trip '{trip_id}'")
            _paradas_cache[ruta_id] = []
            return []

        stop_times = _leer_csv_gtfs("stop_times.txt")
        stops_raw = _leer_csv_gtfs("stops.txt")
        stops_dict = {
            row["stop_id"]: {
                "nombre": row["stop_name"],
                "lat": float(row["stop_lat"]),
                "lon": float(row["stop_lon"]),
            }
            for row in stops_raw
        }

        paradas_trip = sorted(
            [r for r in stop_times if r["trip_id"] == trip_id],
            key=lambda r: int(r["stop_sequence"])
        )

        paradas = []
        for row in paradas_trip:
            stop_id = row["stop_id"]
            if stop_id not in stops_dict:
                continue

            stop = stops_dict[stop_id]
            dist_gtfs = float(row.get("shape_dist_traveled", 0))

            indice_cercano = min(
                range(len(shape_puntos)),
                key=lambda i: abs(shape_puntos[i]["dist"] - dist_gtfs)
            )

            paradas.append({
                "stop_id": stop_id,
                "nombre": stop["nombre"],
                "lat": stop["lat"],
                "lon": stop["lon"],
                "indice_ruta": indice_cercano,
                "dist_ruta": dist_gtfs,
                "llegada_seg": _gtfs_time_a_segundos(row["arrival_time"]),
            })

        _paradas_cache[ruta_id] = paradas
        log.info(f"Paradas cargadas para ruta '{ruta_id}': {len(paradas)}")
        return paradas

    except Exception as e:
        log.error(f"Error cargando paradas para ruta '{ruta_id}': {e}")
        _paradas_cache[ruta_id] = []
        return []


def cargar_gtfs_completo():
    """Carga todos los datos GTFS al startup."""
    global _ruta_puntos, _paradas_info, _shape_to_route_code, _routes_cache

    log.info(f"Cargando datos desde: {GTFS_DIR}")

    if not GTFS_DIR.exists():
        raise FileNotFoundError(
            f"No se encontró la carpeta GTFS en {GTFS_DIR}. "
            "Verifica que 'gtfs_san_antonio/' esté dentro de 'app/'."
        )

    _ruta_puntos = cargar_ruta_desde_gtfs()
    _paradas_info = cargar_paradas_desde_gtfs(_ruta_puntos)

    if len(_ruta_puntos) < 10:
        raise ValueError("La ruta tiene muy pocos puntos, verifica shapes.txt")
    if not _paradas_info:
        raise ValueError("No se encontraron paradas para el trip_id configurado")

    # Precargar paradas para todas las rutas
    try:
        _routes_cache = _leer_csv_gtfs("routes.txt")
        for ruta in _routes_cache:
            r_id = ruta.get("route_id", "")
            if r_id:
                obtener_paradas_por_ruta(r_id)
        log.info(f"Paradas precargadas para {len(_routes_cache)} ruta(s) en caché")
    except Exception as e:
        log.warning(f"No se pudieron precargar todas las rutas: {e}")

    # Mapeo shape_id -> route_code
    try:
        trips_data = _leer_csv_gtfs("trips.txt")
        route_id_to_code = {
            r["route_id"]: r.get("route_short_name", r["route_id"])
            for r in (_routes_cache or [])
        }
        for trip in trips_data:
            sid = trip["shape_id"]
            rid = trip["route_id"]
            _shape_to_route_code[sid] = route_id_to_code.get(rid, sid)
        log.info(f"Rutas cargadas desde GTFS: {_shape_to_route_code}")
    except Exception as e:
        log.warning(f"No se pudo cargar mapping de rutas: {e}")
