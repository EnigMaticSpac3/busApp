"""
Pydantic models con validación estricta.
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional
import re


class InicioSesion(BaseModel):
    """Payload para iniciar sesión en un bus."""
    usuario_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[a-zA-Z0-9_-]+$")
    ruta_id: str = Field(default="SA_R1", min_length=1, max_length=32, pattern=r"^[A-Z0-9_-]+$")


class AuthConductor(BaseModel):
    """Payload para autenticar conductor."""
    pin: str = Field(..., min_length=4, max_length=8, pattern=r"^\d+$")


class GpsConductor(BaseModel):
    """Payload para recibir GPS del conductor cada 5 segundos."""
    conductor_token: str = Field(..., min_length=1, max_length=128)
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    accuracy: Optional[float] = Field(None, ge=0)
    speed: Optional[float] = Field(None, ge=0)


class SesionConductor(BaseModel):
    """Payload para iniciar sesión de conductor."""
    conductor_token: str = Field(..., min_length=1, max_length=128)
    ruta_id: str = Field(..., min_length=1, max_length=32, pattern=r"^[A-Z0-9_-]+$")


class FinSesionConductor(BaseModel):
    """Payload para finalizar sesión de conductor."""
    conductor_token: str = Field(..., min_length=1, max_length=128)


class UbicacionUsuario(BaseModel):
    """Payload que envía el celular del usuario contribuidor."""
    session_id: Optional[str] = Field(None, min_length=1, max_length=64)
    conductor_token: Optional[str] = Field(None, min_length=1, max_length=128)
    usuario_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[a-zA-Z0-9_-]+$")
    ruta_id: str = Field(default="SA_R1", min_length=1, max_length=32, pattern=r"^[A-Z0-9_-]+$")
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    velocidad_ms: float = Field(..., ge=0)
    precision_m: Optional[float] = Field(None, ge=0)

    @field_validator("usuario_id")
    @classmethod
    def sanitize_usuario_id(cls, v: str) -> str:
        return v.strip()

    @field_validator("conductor_token")
    @classmethod
    def sanitize_token(cls, v: Optional[str]) -> Optional[str]:
        return v.strip() if v else v
