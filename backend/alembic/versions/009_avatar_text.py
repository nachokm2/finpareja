"""avatar_url a TEXT (permite imagen embebida en base64)

Revision ID: 009
Revises: 008
Create Date: 2026-06-16
"""
from alembic import op
import sqlalchemy as sa

revision = "009"
down_revision = "008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "usuarios", "avatar_url",
        existing_type=sa.String(500),
        type_=sa.Text(),
        existing_nullable=True,
    )


def downgrade() -> None:
    op.alter_column(
        "usuarios", "avatar_url",
        existing_type=sa.Text(),
        type_=sa.String(500),
        existing_nullable=True,
    )
