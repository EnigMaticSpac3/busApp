"""
Redis service — connection management, cache, and pub/sub.

Provides a thin async wrapper around redis.asyncio with graceful fallback
when Redis is unavailable. All public methods are safe to call even if
the connection has not been established or Redis is down.
"""

import asyncio
import json
import logging
from typing import Optional, Callable, Any

from ..core.config import REDIS_URL

log = logging.getLogger(__name__)


class RedisService:
    """Manages a single async Redis connection plus pub/sub helpers."""

    def __init__(self):
        self._client = None
        self._pubsub = None
        self._listener_task = None
        self._connected = False
        self._handlers: list[Callable[[dict], Any]] = []

    # ------------------------------------------------------------------
    # Connection lifecycle
    # ------------------------------------------------------------------

    async def connect(self) -> bool:
        """Try to connect to Redis. Returns True on success."""
        try:
            import redis.asyncio as aioredis

            self._client = aioredis.from_url(
                REDIS_URL,
                decode_responses=True,
                socket_connect_timeout=3,
            )
            await self._client.ping()
            self._connected = True
            log.info(f"Redis conectado: {REDIS_URL}")
            return True
        except Exception as e:
            log.warning(f"Redis no disponible ({e}). Usando fallback in-memory.")
            self._connected = False
            return False

    async def disconnect(self):
        """Gracefully close the Redis connection."""
        if self._listener_task and not self._listener_task.done():
            self._listener_task.cancel()
        if self._pubsub:
            try:
                await self._pubsub.unsubscribe()
            except Exception:
                pass
        if self._client:
            try:
                await self._client.aclose()
            except Exception:
                pass
        self._connected = False
        log.info("Redis desconectado")

    @property
    def is_connected(self) -> bool:
        return self._connected

    # ------------------------------------------------------------------
    # Cache helpers
    # ------------------------------------------------------------------

    async def get(self, key: str) -> Optional[str]:
        if not self._connected:
            return None
        try:
            return await self._client.get(key)
        except Exception as e:
            log.warning(f"Redis GET error: {e}")
            return None

    async def set(self, key: str, value: str, ttl_seconds: Optional[int] = None) -> bool:
        if not self._connected:
            return False
        try:
            if ttl_seconds:
                await self._client.setex(key, ttl_seconds, value)
            else:
                await self._client.set(key, value)
            return True
        except Exception as e:
            log.warning(f"Redis SET error: {e}")
            return False

    async def delete(self, key: str) -> bool:
        if not self._connected:
            return False
        try:
            await self._client.delete(key)
            return True
        except Exception as e:
            log.warning(f"Redis DEL error: {e}")
            return False

    async def get_json(self, key: str) -> Optional[dict]:
        raw = await self.get(key)
        if raw is None:
            return None
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return None

    async def set_json(self, key: str, data: dict, ttl_seconds: Optional[int] = None) -> bool:
        return await self.set(key, json.dumps(data), ttl_seconds)

    # ------------------------------------------------------------------
    # Pub/Sub
    # ------------------------------------------------------------------

    async def publish(self, channel: str, data: dict) -> bool:
        """Publish a JSON message to a Redis channel."""
        if not self._connected:
            return False
        try:
            await self._client.publish(channel, json.dumps(data))
            return True
        except Exception as e:
            log.warning(f"Redis PUBLISH error: {e}")
            return False

    async def subscribe(self, channel: str, handler: Callable[[dict], Any]):
        """
        Subscribe to a channel. Messages are dispatched to `handler`.
        A background listener task is started automatically.
        """
        if not self._connected:
            return

        self._handlers.append(handler)

        if self._pubsub is None:
            self._pubsub = self._client.pubsub()
            await self._pubsub.subscribe(**{channel: self._message_callback})
            self._listener_task = __import__("asyncio").create_task(self._listen())
            log.info(f"Suscrito a canal Redis: {channel}")
        else:
            # Already have pubsub — just add the subscription
            await self._pubsub.subscribe(**{channel: self._message_callback})

    async def _listen(self):
        """Background loop that reads messages from the pub/sub channel."""
        try:
            async for message in self._pubsub.listen():
                if message["type"] == "message":
                    try:
                        data = json.loads(message["data"])
                        for handler in self._handlers:
                            await handler(data)
                    except (json.JSONDecodeError, TypeError) as e:
                        log.warning(f"Redis message parse error: {e}")
        except asyncio.CancelledError:
            pass
        except Exception as e:
            log.error(f"Redis listener error: {e}")

    # ------------------------------------------------------------------
    # Utility
    # ------------------------------------------------------------------

    async def ping(self) -> bool:
        if not self._connected:
            return False
        try:
            await self._client.ping()
            return True
        except Exception:
            return False


# Global instance
redis_service = RedisService()
