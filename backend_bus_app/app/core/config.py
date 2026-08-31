"""
Configuración centralizada — carga desde .env
"""

import os
from dotenv import load_dotenv

load_dotenv()

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
DB_NAME = os.getenv("DB_NAME", "san_antonio_db")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = int(os.getenv("DB_PORT", "5432"))

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
CORS_ORIGINS = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")
    if origin.strip()
]

# ---------------------------------------------------------------------------
# Rate limiting
# ---------------------------------------------------------------------------
RATE_LIMIT_PER_MINUTE = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))

# ---------------------------------------------------------------------------
# Auth — Conductores
# ---------------------------------------------------------------------------
CONDUCTORES_AUTORIZADOS = {
    "conductor_001": {
        "nombre": "Juan Pérez",
        "pin": os.getenv("CONDUCTOR_001_PIN", "1234"),
        "ruta_asignada": "SA_INTERNAL",
        "activo": True,
    },
    "conductor_002": {
        "nombre": "María Gómez",
        "pin": os.getenv("CONDUCTOR_002_PIN", "5678"),
        "ruta_asignada": "SA_INTERNAL",
        "activo": True,
    },
}

# ---------------------------------------------------------------------------
# GTFS
# ---------------------------------------------------------------------------
from pathlib import Path
GTFS_DIR = Path(__file__).parent.parent / "app" / "gtfs_san_antonio"
SHAPE_ID = "SA_R1"
TRIP_ID = "SA_IDA_001"

# ---------------------------------------------------------------------------
# Map matching thresholds
# ---------------------------------------------------------------------------
UMBRAL_DISTANCIA_RUTA_M = 35.0
UMBRAL_VELOCIDAD_MIN_MS = 1.4
UMBRAL_VELOCIDAD_MAX_MS = 16.0
UMBRAL_ASIGNACION_BUS_M = 200.0

# ---------------------------------------------------------------------------
# Session monitoring
# ---------------------------------------------------------------------------
GEOFENCING_SALIDA_M = 100.0
TIMEOUT_INCIERTO_S = 15
TIMEOUT_PERDIDO_S = 300
TIMEOUT_ELIMINAR_S = 600
VENTANA_PROMEDIO_S = 30

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
APP_TITLE = "San Antonio Bus Tracker API"
