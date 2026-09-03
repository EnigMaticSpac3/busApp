"""
Session monitor — background task that verifies and cleans expired sessions.
Extracted from main.py for cleaner separation of concerns.
"""

import asyncio
import time
import logging

from ..services.session_store import session_store
from ..core.config import (
    GEOFENCING_SALIDA_M,
    TIMEOUT_INCIERTO_S,
    TIMEOUT_PERDIDO_S,
    TIMEOUT_ELIMINAR_S,
)

log = logging.getLogger(__name__)


async def monitor_sesiones():
    """Verify and clean expired sessions every 60 seconds."""
    while True:
        await asyncio.sleep(60)
        try:
            ahora = time.time()
            rutas_a_eliminar = []

            async with session_store._sesiones_lock:
                for ruta_id, sesion in session_store.sesiones_activas.items():
                    seg_sin_senal = ahora - sesion["ultimo_gps"]

                    # Geofencing
                    if sesion["lat"] != 0.0:
                        from ..services.geo_utils import haversine
                        from ..services.gtfs_service import get_ruta_puntos

                        ruta_puntos = get_ruta_puntos()
                        if ruta_puntos:
                            dist_min = min(
                                haversine(sesion["lat"], sesion["lon"], p["lat"], p["lon"])
                                for p in ruta_puntos
                            )
                            if dist_min > GEOFENCING_SALIDA_M:
                                log.info(
                                    f"Sesión {sesion['session_id']} fuera de ruta "
                                    f"({dist_min:.0f}m) → marcada como perdida"
                                )
                                sesion["modo"] = "perdido"

                    # Timeout
                    if seg_sin_senal > TIMEOUT_ELIMINAR_S:
                        contribuidores_activos = any(
                            ahora - c["ts"] < 30
                            for c in sesion["contribuidores"].values()
                        )
                        if not contribuidores_activos:
                            rutas_a_eliminar.append(ruta_id)
                            continue

                    # Mode based on time
                    if seg_sin_senal < TIMEOUT_INCIERTO_S:
                        sesion["modo"] = "activo"
                    elif seg_sin_senal < TIMEOUT_PERDIDO_S:
                        sesion["modo"] = "incierto"
                    else:
                        sesion["modo"] = "perdido"

                for ruta_id in rutas_a_eliminar:
                    log.info(
                        f"Sesión {session_store.sesiones_activas[ruta_id]['session_id']} "
                        f"eliminada por timeout"
                    )
                    del session_store.sesiones_activas[ruta_id]

                if rutas_a_eliminar:
                    log.info(f"Monitor: {len(session_store.sesiones_activas)} sesiones activas")

        except Exception as e:
            log.error(f"Error en monitor de sesiones: {e}")
