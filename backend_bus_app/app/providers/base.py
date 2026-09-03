"""
Abstract base class for transit data providers.
Each provider wraps an external data source (GTFS, MiBus API, etc.)
and exposes a unified interface for the rest of the application.
"""

from abc import ABC, abstractmethod
from typing import Optional


class TransitProvider(ABC):
    """Interface that every transit data provider must implement."""

    @abstractmethod
    def get_routes(self) -> list[dict]:
        """Return available routes."""
        ...

    @abstractmethod
    def get_route_shape(self, shape_id: str) -> list[dict]:
        """Return ordered points for a given shape/route."""
        ...

    @abstractmethod
    def get_stops(self, trip_id: str) -> list[dict]:
        """Return ordered stops for a given trip."""
        ...

    @abstractmethod
    def get_stops_for_route(self, route_id: str) -> list[dict]:
        """Return stops associated with a route."""
        ...

    @abstractmethod
    def get_shape_to_route_code(self) -> dict[str, str]:
        """Return mapping of shape_id → route short name."""
        ...

    @abstractmethod
    def get_trip_ids(self) -> list[str]:
        """Return all trip IDs."""
        ...

    @abstractmethod
    def get_alerts(self) -> list[dict]:
        """Return active service alerts (if provider supports them)."""
        ...
