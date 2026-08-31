"""
Servicio de autenticación de conductores.
Almacena tokens emitidos y los valida en cada request.
"""

import uuid
import time
import logging
from typing import Optional
from ..core.config import CONDUCTORES_AUTORIZADOS

log = logging.getLogger(__name__)

# Almacén de tokens válidos: token -> {conductor_id, nombre, ruta_asignada, issued_at}
_tokens_validos: dict[str, dict] = {}

# TTL del token: 12 horas (conductor trabaja 8-12h)
TOKEN_TTL_S = 12 * 60 * 60


def autenticar_conductor(pin: str) -> Optional[dict]:
    """
    Verifica PIN y devuelve token si es válido.
    Almacena el token para validación posterior.
    """
    for conductor_id, conductor in CONDUCTORES_AUTORIZADOS.items():
        if conductor["pin"] == pin and conductor["activo"]:
            token = str(uuid.uuid4())
            _tokens_validos[token] = {
                "conductor_id": conductor_id,
                "nombre": conductor["nombre"],
                "ruta_asignada": conductor["ruta_asignada"],
                "issued_at": time.time(),
            }
            log.info(f"Token emitido para conductor {conductor_id}")
            return {
                "token": token,
                "conductor_id": conductor_id,
                "nombre": conductor["nombre"],
                "ruta_asignada": conductor["ruta_asignada"],
            }
    return None


def validar_token(token: str) -> Optional[dict]:
    """
    Valida que un token exista y no haya expirado.
    Retorna info del conductor o None si inválido.
    """
    info = _tokens_validos.get(token)
    if info is None:
        return None

    # Verificar expiración
    if time.time() - info["issued_at"] > TOKEN_TTL_S:
        del _tokens_validos[token]
        log.info(f"Token expirado para conductor {info['conductor_id']}")
        return None

    return info


def revocar_token(token: str) -> bool:
    """Revoca un token (logout)."""
    if token in _tokens_validos:
        del _tokens_validos[token]
        return True
    return False
