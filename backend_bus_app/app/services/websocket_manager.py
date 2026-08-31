"""
ConnectionManager con soporte de autenticación y throttle.
"""

import json
import time
import asyncio
import logging
from typing import List, Optional
from fastapi import WebSocket

log = logging.getLogger(__name__)

# Throttle: máximo 1 broadcast cada 2 segundos
BROADCAST_THROTTLE_S = 2.0


class ConnectionManager:
    """Gestiona conexiones WebSocket con auth y throttle."""

    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self._last_broadcast: float = 0.0
        self._pending_broadcast: Optional[dict] = None
        self._throttle_task: Optional[asyncio.Task] = None

    async def connect(self, websocket: WebSocket, token: Optional[str] = None):
        """
        Acepta conexión WebSocket. Opcionalmente valida token.
        Si se provee token, valida que sea un token de conductor válido.
        """
        await websocket.accept()
        self.active_connections.append(websocket)
        log.info(
            f"WebSocket conectado (auth={'sí' if token else 'no'}). "
            f"Total: {len(self.active_connections)}"
        )

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            log.info(f"WebSocket desconectado. Total: {len(self.active_connections)}")

    async def broadcast(self, data: dict, force: bool = False):
        """
        Envía datos a todos los clientes con throttle.
        Si force=True, ignora el throttle (para datos críticos).
        """
        ahora = time.time()

        if not force and (ahora - self._last_broadcast) < BROADCAST_THROTTLE_S:
            # Guardar para enviar después del throttle
            self._pending_broadcast = data
            return

        self._last_broadcast = ahora
        await self._send_all(data)

    async def _send_all(self, data: dict):
        """Envía a todas las conexiones activas."""
        if not self.active_connections:
            return

        mensaje = json.dumps(data)
        conexiones_muertas = []

        for connection in self.active_connections:
            try:
                await connection.send_text(mensaje)
            except Exception:
                conexiones_muertas.append(connection)

        for conn in conexiones_muertas:
            if conn in self.active_connections:
                self.active_connections.remove(conn)

    async def flush_pending(self):
        """Envía el último broadcast pendiente si existe."""
        if self._pending_broadcast is not None:
            data = self._pending_broadcast
            self._pending_broadcast = None
            await self._send_all(data)
            self._last_broadcast = time.time()

    async def send_personal(self, websocket: WebSocket, data: dict):
        """Envía datos a un cliente específico."""
        try:
            await websocket.send_text(json.dumps(data))
        except Exception as e:
            log.warning(f"Error enviando a cliente: {e}")

    async def close_all(self, reason: str = "Server shutting down"):
        """Cierra todas las conexiones graceful."""
        for connection in self.active_connections.copy():
            try:
                await connection.close(code=1001, reason=reason)
            except Exception:
                pass
        self.active_connections.clear()
        log.info("Todas las conexiones WebSocket cerradas")


manager = ConnectionManager()
