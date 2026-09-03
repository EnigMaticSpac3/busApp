"""
WebSocket endpoint for real-time fleet tracking.
"""

import logging
from typing import Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query

from ..services.websocket_manager import manager
from ..services.fleet_service import get_fleet_data

log = logging.getLogger(__name__)

ws_router = APIRouter()


@ws_router.websocket("/ws/flota")
async def websocket_flota(websocket: WebSocket, token: Optional[str] = Query(None)):
    """WebSocket endpoint for real-time fleet updates."""
    await manager.connect(websocket, token)
    try:
        # Send current state on connect
        flota_actual = get_fleet_data()
        await manager.send_personal(websocket, {"tipo": "flota", "datos": flota_actual})

        # Keep connection alive — read client messages (ping/pong)
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        log.warning(f"WebSocket error: {e}")
        manager.disconnect(websocket)
