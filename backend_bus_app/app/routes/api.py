"""
Rutas de la API — Transita Backend.
"""

import time
import logging
from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect, Query, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import Optional

from ..models.schemas import (
    InicioSesion, AuthConductor, GpsConductor,
    SesionConductor, FinSesionConductor, UbicacionUsuario,
)
from ..services.auth_service import autenticar_conductor, validar_token, revocar_token
from ..services.session_store import session_store
from ..services.websocket_manager import manager
from ..services import gtfs_service
from ..services.geo_utils import haversine, map_matching, calcular_promedio_ponderado
from ..core.config import (
    GEOFENCING_SALIDA_M, TIMEOUT_INCIERTO_S, TIMEOUT_PERDIDO_S,
    TIMEOUT_ELIMINAR_S, UMBRAL_ASIGNACION_BUS_M, RATE_LIMIT_PER_MINUTE,
)

log = logging.getLogger(__name__)
router = APIRouter()

# Rate limiter
limiter = Limiter(key_func=get_remote_address)
router.state.limiter = limiter


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@router.get("/api/health")
async def health_check():
    return {"status": "ok", "service": "transita-api"}


# ---------------------------------------------------------------------------
# Rutas y paradas (GTFS)
# ---------------------------------------------------------------------------

@router.get("/api/ruta")
async def get_ruta():
    ruta_puntos = gtfs_service.get_ruta_puntos()
    from ..core.config import SHAPE_ID
    return {
        "ruta_id": SHAPE_ID,
        "puntos": [{"lat": p["lat"], "lon": p["lon"]} for p in ruta_puntos],
    }


@router.get("/api/rutas")
async def get_rutas():
    routes = gtfs_service.get_routes()
    if not routes:
        return {"rutas": [], "error": "GTFS routes.txt no encontrado"}

    sesiones = session_store.sesiones_activas
    import time as _time
    ahora = _time.time()

    resultado = []
    for ruta in routes:
        ruta_id = ruta.get("route_id", "")
        buses_activos = 0

        if ruta_id in sesiones:
            sesion = sesiones[ruta_id]
            seg = ahora - sesion["ultimo_gps"]
            if seg < 600:
                buses_activos = sum(
                    1 for c in sesion["contribuidores"].values()
                    if ahora - c["ts"] < 30
                )

        resultado.append({
            "ruta_id": ruta_id,
            "codigo": ruta.get("route_short_name", ""),
            "nombre": ruta.get("route_long_name", ""),
            "color": ruta.get("route_color", "007BFF"),
            "buses_activos": buses_activos,
        })

    return {"rutas": resultado}


@router.get("/api/rutas/{ruta_id}/paradas")
async def get_paradas_ruta(ruta_id: str):
    paradas = gtfs_service.obtener_paradas_por_ruta(ruta_id)
    paradas_ordenadas = sorted(paradas, key=lambda p: p.get("indice_ruta", 0))

    return {
        "ruta_id": ruta_id,
        "paradas": [
            {
                "stop_id": p["stop_id"],
                "nombre": p["nombre"],
                "lat": p["lat"],
                "lon": p["lon"],
                "secuencia": i,
            }
            for i, p in enumerate(paradas_ordenadas)
        ]
    }


# ---------------------------------------------------------------------------
# Flota
# ---------------------------------------------------------------------------

def _get_flota_data_completa() -> list:
    """Obtiene datos de la flota (pasajeros + conductores)."""
    resultado = []
    ahora = time.time()

    # Excluir sesiones que ya tienen conductor
    session_ids_conductores = {s["session_id"] for s in session_store.sesiones_conductor.values()}

    # Sesiones de pasajeros
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

    # Sesiones de conductor
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


@router.get("/api/flota")
async def get_flota():
    """Devuelve sesiones activas (buses dinámicos desde contribuidores y conductores)."""
    return _get_flota_data_completa()


# ---------------------------------------------------------------------------
# Sesión pasajero
# ---------------------------------------------------------------------------

@router.post("/api/iniciar-sesion-bus")
@limiter.limit(f"{RATE_LIMIT_PER_MINUTE}/minute")
async def iniciar_sesion_bus(request: Request, payload: InicioSesion):
    resultado = await session_store.crear_o_unir_sesion(payload.ruta_id, payload.usuario_id)
    return resultado


# ---------------------------------------------------------------------------
# Auth conductor
# ---------------------------------------------------------------------------

@router.post("/api/auth/conductor")
@limiter.limit("10/minute")
async def auth_conductor(request: Request, payload: AuthConductor):
    """Verifica PIN y devuelve token de sesión conductor."""
    resultado = autenticar_conductor(payload.pin)
    if resultado is None:
        raise HTTPException(status_code=401, detail="PIN inválido o conductor inactivo")
    return resultado


# ---------------------------------------------------------------------------
# Sesión conductor
# ---------------------------------------------------------------------------

@router.post("/api/sesion-conductor")
async def iniciar_sesion_conductor(payload: SesionConductor):
    # Validar token
    info = validar_token(payload.conductor_token)
    if info is None:
        raise HTTPException(status_code=401, detail="Token de conductor inválido o expirado")

    resultado = await session_store.crear_sesion_conductor(payload.conductor_token, payload.ruta_id)
    return resultado


@router.post("/api/sesion-conductor/fin")
async def finalizar_sesion_conductor(payload: FinSesionConductor):
    # Validar token
    info = validar_token(payload.conductor_token)
    if info is None:
        raise HTTPException(status_code=401, detail="Token de conductor inválido o expirado")

    eliminado = await session_store.eliminar_sesion_conductor(payload.conductor_token)

    if eliminado:
        flota_actual = _get_flota_data_completa()
        await manager.broadcast({"tipo": "flota", "datos": flota_actual})

    revocar_token(payload.conductor_token)
    return {"estado": "ok", "mensaje": "sesión finalizada"}


# ---------------------------------------------------------------------------
# GPS conductor
# ---------------------------------------------------------------------------

@router.post("/api/gps-conductor")
@limiter.limit(f"{RATE_LIMIT_PER_MINUTE}/minute")
async def gps_conductor(request: Request, payload: GpsConductor):
    # Validar token
    info = validar_token(payload.conductor_token)
    if info is None:
        raise HTTPException(status_code=401, detail="Token de conductor inválido o expirado")

    sesion = await session_store.actualizar_gps_conductor(
        payload.conductor_token, payload.lat, payload.lng,
        payload.speed if payload.speed is not None else 0.0
    )

    if sesion is None:
        raise HTTPException(status_code=404, detail="Sesión de conductor no encontrada")

    flota_actual = _get_flota_data_completa()
    await manager.broadcast({"tipo": "flota", "datos": flota_actual})

    return {
        "estado": "aceptado",
        "session_id": sesion["session_id"],
        "bus_id": f"Conductor-{sesion['session_id'][:4]}",
    }


# ---------------------------------------------------------------------------
# Contribuir ubicación (crowdsourcing)
# ---------------------------------------------------------------------------

@router.post("/api/contribuir-ubicacion")
@limiter.limit(f"{RATE_LIMIT_PER_MINUTE}/minute")
async def contribuir_ubicacion(request: Request, payload: UbicacionUsuario):
    es_conductor = payload.conductor_token is not None

    # Map matching: solo para pasajeros
    if not es_conductor:
        map_result = map_matching(payload.lat, payload.lon, payload.velocidad_ms, payload.precision_m)
        if map_result is None:
            return {
                "estado": "ignorado",
                "motivo": "ubicación fuera de ruta o velocidad incompatible con bus",
                "lat": payload.lat,
                "lon": payload.lon,
                "vel_ms": payload.velocidad_ms,
            }
    else:
        map_result = {"indice_ruta": 0}

    if es_conductor:
        # Modo conductor
        info = validar_token(payload.conductor_token)
        if info is None:
            raise HTTPException(status_code=401, detail="Token de conductor inválido o expirado")

        sesion = await session_store.actualizar_gps_conductor(
            payload.conductor_token, payload.lat, payload.lon, payload.velocidad_ms
        )

        if sesion is None:
            # Crear sesión automáticamente
            resultado = await session_store.crear_sesion_conductor(
                payload.conductor_token, payload.ruta_id
            )
            sesion = await session_store.get_sesion_conductor(payload.conductor_token)

        flota_actual = _get_flota_data_completa()
        await manager.broadcast({"tipo": "flota", "datos": flota_actual})

        return {
            "estado": "aceptado",
            "tipo": "conductor",
            "session_id": sesion["session_id"],
            "bus_id": f"Conductor-{sesion['session_id'][:4]}",
            "lat": payload.lat,
            "lon": payload.lon,
        }

    # Modo pasajero
    sesion = await session_store.get_sesion(payload.ruta_id)
    if sesion is None:
        raise HTTPException(
            status_code=400,
            detail="No hay sesión activa para esta ruta. Llama primero a /api/iniciar-sesion-bus"
        )

    if sesion["session_id"] != payload.session_id:
        raise HTTPException(status_code=400, detail="session_id no coincide con la sesión activa")

    # Actualizar contribuidor
    ahora = time.time()
    sesion["contribuidores"][payload.usuario_id] = {
        "lat": payload.lat,
        "lon": payload.lon,
        "vel_ms": payload.velocidad_ms,
        "ts": ahora,
    }

    # Promedio ponderado
    lat_prom, lon_prom, vel_prom = calcular_promedio_ponderado(sesion["contribuidores"])
    if lat_prom != 0.0:
        sesion["lat"] = lat_prom
        sesion["lon"] = lon_prom
        sesion["vel_ms"] = vel_prom

    sesion["ultimo_gps"] = ahora
    sesion["indice_ruta"] = map_result.get("indice_ruta", 0)
    sesion["modo"] = "activo"

    # Broadcast
    flota_actual = _get_flota_data_completa()
    await manager.broadcast({"tipo": "flota", "datos": flota_actual})

    return {
        "estado": "aceptado",
        "session_id": sesion["session_id"],
        "bus_id": f"Bus-{sesion['session_id']}",
        "lat": sesion["lat"],
        "lon": sesion["lon"],
    }


# ---------------------------------------------------------------------------
# ETA por parada
# ---------------------------------------------------------------------------

@router.get("/api/eta/{parada_id}")
async def get_eta_parada(parada_id: str):
    paradas_info = gtfs_service.get_paradas_info()
    ruta_puntos = gtfs_service.get_ruta_puntos()
    shape_to_route_code = gtfs_service.get_shape_to_route_code()

    # Encontrar la parada
    parada = next((p for p in paradas_info if p["stop_id"] == parada_id), None)
    if parada is None:
        raise HTTPException(status_code=404, detail="Parada no encontrada")

    ahora = time.time()
    buses = []

    # Buscar buses activos
    for sesion in session_store.sesiones_activas.values():
        seg = ahora - sesion["ultimo_gps"]
        if seg > 300:
            continue

        if sesion["lat"] == 0.0:
            continue

        distancia = haversine(
            sesion["lat"], sesion["lon"],
            parada["lat"], parada["lon"]
        )

        if distancia > UMBRAL_ASIGNACION_BUS_M:
            continue

        velocidad_prom = sesion.get("vel_ms", 5.0)
        if velocidad_prom > 0:
            minutos = distancia / (velocidad_prom * 60)
        else:
            minutos = 99

        if minutos < 1:
            eta = "Menos de 1 min"
        else:
            eta = f"{int(round(minutos))} min"

        ruta_codigo = shape_to_route_code.get(sesion["ruta_id"], sesion["ruta_id"])

        buses.append({
            "ruta_id": sesion["ruta_id"],
            "ruta_codigo": ruta_codigo,
            "bus_id": f"Bus-{sesion['session_id']}",
            "eta": eta,
            "distancia": round(distancia, 0),
        })

    buses.sort(key=lambda b: b["distancia"])

    return {
        "parada": parada["nombre"],
        "parada_id": parada_id,
        "buses": buses,
    }


# ---------------------------------------------------------------------------
# WebSocket
# ---------------------------------------------------------------------------

@router.websocket("/ws/flota")
async def websocket_endpoint(websocket: WebSocket, token: Optional[str] = Query(None)):
    """Endpoint WebSocket para tiempo real de la flota."""
    await manager.connect(websocket, token)
    try:
        # Enviar estado actual
        flota_actual = _get_flota_data_completa()
        await manager.send_personal(websocket, {"tipo": "flota", "datos": flota_actual})

        # Mantener conexión viva
        while True:
            data = await websocket.receive_text()
            # Ping/pong o mensajes del cliente
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        log.warning(f"WebSocket error: {e}")
        manager.disconnect(websocket)
