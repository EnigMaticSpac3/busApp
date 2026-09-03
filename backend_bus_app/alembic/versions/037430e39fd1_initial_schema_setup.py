"""initial schema setup — Alembic infrastructure ready

This migration marks the initialization of Alembic for the Transita backend.
Currently, the application uses Pydantic models only (no SQLAlchemy ORM models).
No database tables are created here.

When SQLAlchemy models are added (e.g., app/models/base.py), run:
    alembic revision --autogenerate -m "description"
to auto-generate migrations from model definitions.

Revision ID: 037430e39fd1
Revises: 
Create Date: 2026-09-02 22:02:11.145104

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '037430e39fd1'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """No-op — no SQLAlchemy models exist yet.

    When models are added, this will be superseded by autogenerate.
    """
    pass


def downgrade() -> None:
    """No-op — nothing to downgrade."""
    pass
