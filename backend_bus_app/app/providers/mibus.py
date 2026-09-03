"""
MiBus provider — wraps the existing GTFS file-based service.
When a real MiBus API becomes available, replace the internals
while keeping the same TransitProvider interface.
"""

from typing import Optional
from .base import TransitProvider
from ..services import gtfs_service


class MiBusProvider(TransitProvider):
    """TransitProvider backed by local GTFS files."""

    def get_routes(self) -> list[dict]:
        return gtfs_service.get_routes()

    def get_route_shape(self, shape_id: str) -> list[dict]:
        # Current GTFS service only loads a single shape (SA_R1).
        # Return it regardless of shape_id for now.
        return gtfs_service.get_ruta_puntos()

    def get_stops(self, trip_id: str) -> list[dict]:
        return gtfs_service.get_paradas_info()

    def get_stops_for_route(self, route_id: str) -> list[dict]:
        return gtfs_service.obtener_paradas_por_ruta(route_id)

    def get_shape_to_route_code(self) -> dict[str, str]:
        return gtfs_service.get_shape_to_route_code()

    def get_trip_ids(self) -> list[str]:
        # The GTFS service doesn't expose trip IDs directly yet.
        # Return empty list; will be implemented when multi-trip support lands.
        return []

    def get_alerts(self) -> list[dict]:
        # No external alert source yet; alerts come from the in-memory store.
        return []


# Singleton — import this wherever you need a provider
provider = MiBusProvider()
