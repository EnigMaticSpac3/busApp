"""
API endpoints for Service Alerts — Phase 2A Event System.
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List

from ..models.service_alert import ServiceAlert, ServiceAlertCreate, alert_store
from ..services.websocket_manager import manager

router = APIRouter(prefix="/api/alerts", tags=["alerts"])


@router.get("", response_model=List[ServiceAlert])
async def get_alerts(
    route_id: Optional[str] = Query(None, description="Filter by route ID"),
    active_only: bool = Query(True, description="Only return active alerts"),
):
    """Get service alerts, optionally filtered by route."""
    return alert_store.get_alerts(route_id=route_id, active_only=active_only)


@router.get("/{alert_id}", response_model=ServiceAlert)
async def get_alert(alert_id: str):
    """Get a specific alert by ID."""
    alert = alert_store.get_alert(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert


@router.post("", response_model=ServiceAlert, status_code=201)
async def create_alert(data: ServiceAlertCreate):
    """Create a new service alert."""
    alert = ServiceAlert(**data.model_dump())
    stored = alert_store.add_alert(alert)
    # Broadcast via WebSocket (force=True for critical alert events)
    await manager.broadcast({
        "tipo": "alert",
        "evento": "alert:new",
        "datos": stored.model_dump(mode="json"),
    }, force=True)
    return stored


@router.put("/{alert_id}/expire")
async def expire_alert(alert_id: str):
    """Mark an alert as expired."""
    if not alert_store.expire_alert(alert_id):
        raise HTTPException(status_code=404, detail="Alert not found")
    alert = alert_store.get_alert(alert_id)
    # Broadcast via WebSocket
    await manager.broadcast({
        "tipo": "alert",
        "evento": "alert:expired",
        "datos": alert.model_dump(mode="json") if alert else {"alert_id": alert_id},
    }, force=True)
    return {"status": "expired"}


@router.delete("/{alert_id}")
async def delete_alert(alert_id: str):
    """Delete an alert."""
    if not alert_store.delete_alert(alert_id):
        raise HTTPException(status_code=404, detail="Alert not found")
    await manager.broadcast({
        "tipo": "alert",
        "evento": "alert:deleted",
        "datos": {"alert_id": alert_id},
    }, force=True)
    return {"status": "deleted"}
