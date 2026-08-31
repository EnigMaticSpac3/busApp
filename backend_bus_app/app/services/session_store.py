"""
Almacén de sesiones con soporte de persistencia en memoria.
"""

import asyncio
import time
import logging
from typing import Optional

log = logging.getLogger(__name__)


class SessionStore:
    """Almacén de sesiones de pasajeros y conductores."""

    def __init__(self):
        self.sesiones_activas: dict[str, dict] = {}
        self._sesiones_lock = asyncio.Lock()

        self.sesiones_conductor: dict[str, dict] = {}
        self._sesiones_conductor_lock = asyncio.Lock()

        self.ultimo_gps_conductor: dict[str, dict] = {}

    # --- Sesiones de pasajeros ---

    async def get_sesion(self, ruta_id: str) -> Optional[dict]:
        async with self._sesiones_lock:
            return self.sesiones_activas.get(ruta_id)

    async def crear_o_unir_sesion(self, ruta_id: str, usuario_id: str, session_id_hint: Optional[str] = None) -> dict:
        """Crea o une a una sesión existente."""
        async with self._sesiones_lock:
            import uuid

            # Si ya existe sesión activa, unirse
            if ruta_id in self.sesiones_activas:
                sesion = self.sesiones_activas[ruta_id]
                if usuario_id not in sesion["contribuidores"]:
                    sesion["contribuidores"][usuario_id] = {
                        "lat": 0.0, "lon": 0.0, "vel_ms": 0.0, "ts": time.time()
                    }
                    log.info(f"Usuario {usuario_id} se unió a sesión {sesion['session_id']}")
                return {"session_id": sesion["session_id"], "nueva": False, "ruta_id": ruta_id}

            # Crear nueva sesión
            session_id = str(uuid.uuid4())
            self.sesiones_activas[ruta_id] = {
                "session_id": session_id,
                "ruta_id": ruta_id,
                "lat": 0.0,
                "lon": 0.0,
                "vel_ms": 0.0,
                "indice_ruta": 0,
                "modo": "incierto",
                "ultimo_gps": time.time(),
                "contribuidores": {
                    usuario_id: {"lat": 0.0, "lon": 0.0, "vel_ms": 0.0, "ts": time.time()}
                }
            }
            log.info(f"Nueva sesión {session_id} creada para ruta {ruta_id}")
            return {"session_id": session_id, "nueva": True, "ruta_id": ruta_id}

    # --- Sesiones de conductor ---

    async def get_sesion_conductor(self, token: str) -> Optional[dict]:
        async with self._sesiones_conductor_lock:
            return self.sesiones_conductor.get(token)

    async def crear_sesion_conductor(self, token: str, ruta_id: str) -> dict:
        """Crea sesión de conductor."""
        async with self._sesiones_conductor_lock:
            import uuid

            if token in self.sesiones_conductor:
                sesion = self.sesiones_conductor[token]
                return {"session_id": sesion["session_id"], "estado": "activa", "inicio": sesion["inicio"]}

            session_id = str(uuid.uuid4())
            self.sesiones_conductor[token] = {
                "session_id": session_id,
                "conductor_token": token,
                "ruta_id": ruta_id,
                "inicio": time.time(),
                "ultimo_gps": time.time(),
                "activo": True,
                "tipo": "conductor",
            }
            log.info(f"Sesión conductor iniciada: {session_id} para ruta {ruta_id}")
            return {"session_id": session_id, "estado": "activa", "inicio": time.time()}

    async def eliminar_sesion_conductor(self, token: str) -> bool:
        """Elimina sesión de conductor."""
        async with self._sesiones_conductor_lock:
            if token in self.sesiones_conductor:
                del self.sesiones_conductor[token]
                log.info(f"Sesión de conductor {token[:8]}... finalizada")
                return True
            return False

    async def actualizar_gps_conductor(self, token: str, lat: float, lon: float, vel_ms: float) -> Optional[dict]:
        """Actualiza posición del conductor."""
        async with self._sesiones_conductor_lock:
            if token not in self.sesiones_conductor:
                return None

            sesion = self.sesiones_conductor[token]
            sesion["lat"] = lat
            sesion["lon"] = lon
            sesion["vel_ms"] = vel_ms
            sesion["ultimo_gps"] = time.time()
            sesion["activo"] = True
            return sesion


# Instancia global
session_store = SessionStore()
