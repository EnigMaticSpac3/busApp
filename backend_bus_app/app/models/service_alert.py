"""
ServiceAlert model and in-memory store for Phase 2A — Event System.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class AlertType(str, Enum):
    DETOUR = "DETOUR"
    CLOSURE = "CLOSURE"
    SUSPENSION = "SUSPENSION"
    SPECIAL_EVENT = "SPECIAL_EVENT"
    DELAY = "DELAY"
    GENERAL = "GENERAL"


class AlertSeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class ServiceAlert(BaseModel):
    alert_id: str = Field(default_factory=lambda: str(__import__('uuid').uuid4()))
    type: AlertType
    severity: AlertSeverity = AlertSeverity.MEDIUM
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    affected_routes: List[str] = []
    affected_stops: List[str] = []
    valid_from: datetime
    valid_until: Optional[datetime] = None
    source: str = "system"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class ServiceAlertCreate(BaseModel):
    type: AlertType
    severity: AlertSeverity = AlertSeverity.MEDIUM
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    affected_routes: List[str] = []
    affected_stops: List[str] = []
    valid_from: datetime
    valid_until: Optional[datetime] = None
    source: str = "manual"


class AlertStore:
    """In-memory store for service alerts. Will be replaced by PostgreSQL in Phase 3."""

    def __init__(self):
        self._alerts: dict[str, ServiceAlert] = {}

    def add_alert(self, alert: ServiceAlert) -> ServiceAlert:
        self._alerts[alert.alert_id] = alert
        return alert

    def get_alerts(
        self, route_id: Optional[str] = None, active_only: bool = True
    ) -> List[ServiceAlert]:
        alerts = list(self._alerts.values())
        if active_only:
            now = datetime.utcnow()
            alerts = [
                a for a in alerts
                if a.valid_from <= now and (a.valid_until is None or a.valid_until >= now)
            ]
        if route_id:
            alerts = [a for a in alerts if route_id in a.affected_routes]
        return sorted(alerts, key=lambda a: a.created_at, reverse=True)

    def get_alert(self, alert_id: str) -> Optional[ServiceAlert]:
        return self._alerts.get(alert_id)

    def expire_alert(self, alert_id: str) -> bool:
        if alert_id in self._alerts:
            self._alerts[alert_id].valid_until = datetime.utcnow()
            self._alerts[alert_id].updated_at = datetime.utcnow()
            return True
        return False

    def delete_alert(self, alert_id: str) -> bool:
        return self._alerts.pop(alert_id, None) is not None


# Global instance
alert_store = AlertStore()
