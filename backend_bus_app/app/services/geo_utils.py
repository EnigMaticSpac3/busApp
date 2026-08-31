"""
Utilidades geográficas — haversine, map matching.
"""

import math
import logging
from typing import Optional
from ..core.config import (
    UMBRAL_DISTANCIA_RUTA_M,
    UMBRAL_VELOCIDAD_MIN_MS,
    UMBRAL_VELOCIDAD_MAX_MS,
)
from ..services.gtfs_service import get_ruta_puntos

log = logging.getLogger(__name__)


def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Distancia en metros entre dos coordenadas."""
    R = 6_371_000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    a = (
        math.sin(math.radians(lat2 - lat1) / 2) ** 2
        + math.cos(phi1) * math.cos(phi2)
        * math.sin(math.radians(lon2 - lon1) / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def map_matching(lat: float, lon: float, velocidad_ms: float, precision_m: Optional[float] = None) -> Optional[dict]:
    """
    Determina si el usuario está en una zona donde podría estar en un bus.
    """
    ruta_puntos = get_ruta_puntos()

    # Filtro 0: precisión GPS suficiente
    if precision_m is not None and precision_m > 50:
        return None

    # Filtro 1: velocidad coherente con un bus
    if not (UMBRAL_VELOCIDAD_MIN_MS <= velocidad_ms <= UMBRAL_VELOCIDAD_MAX_MS):
        return None

    # Filtro 2: proximidad a la ruta
    if not ruta_puntos:
        return None

    dist_minima_ruta = float("inf")
    indice_cercano = 0
    for i, punto in enumerate(ruta_puntos):
        d = haversine(lat, lon, punto["lat"], punto["lon"])
        if d < dist_minima_ruta:
            dist_minima_ruta = d
            indice_cercano = i

    if dist_minima_ruta > UMBRAL_DISTANCIA_RUTA_M:
        return None

    return {
        "valido": True,
        "distancia_ruta": dist_minima_ruta,
        "indice_ruta": indice_cercano,
    }


def calcular_promedio_ponderado(contribuidores: dict) -> tuple[float, float, float]:
    """Promedio ponderado por recencia — señales más recientes tienen más peso."""
    import time

    ahora = time.time()
    lats, lons, vels, pesos = [], [], [], []

    for datos in contribuidores.values():
        antiguedad = ahora - datos["ts"]
        if antiguedad > 30 or datos["lat"] == 0.0:
            continue
        peso = 1.0 / (1.0 + antiguedad)
        lats.append(datos["lat"] * peso)
        lons.append(datos["lon"] * peso)
        vels.append(datos["vel_ms"] * peso)
        pesos.append(peso)

    if not pesos:
        return 0.0, 0.0, 0.0

    total = sum(pesos)
    return sum(lats) / total, sum(lons) / total, sum(vels) / total
