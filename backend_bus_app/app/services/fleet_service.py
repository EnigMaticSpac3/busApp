"""
Fleet data aggregation — combines passenger sessions and driver sessions.
Extracted from routes to allow use by both HTTP and WebSocket handlers.
"""

import time
import logging

from ..services.session_store import session_store

log = logging.getLogger(__name__)


def get_fleet_data() -> list:
    """Return active fleet data (passenger + driver sessions)."""
    resultado = []
    ahora = time.time()

    # Exclude sessions that already have a driver
    session_ids_conductores = {
        s["session_id"] for s in session_store.sesiones_conductor.values()
    }

    # Passenger sessions
    for sesion in session_store.sesiones_activas.values():
        if sesion["session_id"] in session_ids_conductores:
            continue

        seg = ahora - sesion["ultimo_gps"]
        if seg > 600:
            continue

        modo = (
            "activo" if seg < 15 else
            "incierto" if seg < 300 else
            "perdido"
        )
        contribuidores_activos = sum(
            1 for c in sesion["contribuidores"].values()
            if ahora - c["ts"] < 30
        )
        resultado.append({
            "bus_id": f"Bus-{sesion['session_id']}",
            "session_id": sesion["session_id"],
            "ruta_id": sesion["ruta_id"],
            "lat": sesion["lat"],
            "lon": sesion["lon"],
            "vel_ms": sesion["vel_ms"],
            "indice_ruta": sesion.get("indice_ruta", 0),
            "modo": modo,
            "tipo": "pasajero",
            "segundos_sin_senal": round(seg, 0),
            "contribuidores_activos": contribuidores_activos,
        })

    # Driver sessions
    for token, sesion in session_store.sesiones_conductor.items():
        seg = ahora - sesion.get("ultimo_gps", sesion["inicio"])
        resultado.append({
            "bus_id": f"Conductor-{sesion['session_id'][:4]}",
            "session_id": sesion["session_id"],
            "ruta_id": sesion["ruta_id"],
            "lat": sesion.get("lat", 0.0),
            "lon": sesion.get("lon", 0.0),
            "vel_ms": sesion.get("vel_ms", 0.0),
            "indice_ruta": 0,
            "modo": "activo",
            "tipo": "conductor",
            "segundos_sin_senal": round(seg, 0),
            "contribuidores_activos": 1,
        })

    return resultado
