"""
Transita API — Modular architecture.
"""

import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import CORS_ORIGINS, APP_TITLE
from .services.gtfs_service import cargar_gtfs_completo
from .services.websocket_manager import manager
from .services.session_store import session_store
from .routes.api import router

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Session monitor
# ---------------------------------------------------------------------------
async def monitor_sesiones():
    """Verifica y limpia sesiones expiradas cada 60 segundos."""
    while True:
        await asyncio.sleep(60)
        try:
            import time

            ahora = time.time()
            rutas_a_eliminar = []

            async with session_store._sesiones_lock:
                for ruta_id, sesion in session_store.sesiones_activas.items():
                    seg_sin_senal = ahora - sesion["ultimo_gps"]

                    # Geofencing
                    if sesion["lat"] != 0.0:
                        from .services.geo_utils import haversine
                        from .services.gtfs_service import get_ruta_puntos
                        from .core.config import GEOFENCING_SALIDA_M, TIMEOUT_ELIMINAR_S
                        from .core.config import TIMEOUT_INCIERTO_S, TIMEOUT_PERDIDO_S

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

                    # Modo basado en tiempo
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


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        cargar_gtfs_completo()
    except Exception as e:
        log.error(f"Error al cargar datos GTFS: {e}")
        raise

    log.info("Datos GTFS cargados, esperando contribuidores...")

    tarea_monitor = asyncio.create_task(monitor_sesiones())
    log.info("Monitor de sesiones iniciado (cada 60s)")

    yield

    # Graceful shutdown
    tarea_monitor.cancel()
    await manager.close_all("Server shutting down")
    log.info("Servidor detenido.")


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(title=APP_TITLE, lifespan=lifespan)

# CORS — whitelist desde .env
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Incluir rutas
app.include_router(router)
