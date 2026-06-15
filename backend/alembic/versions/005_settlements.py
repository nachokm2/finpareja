"""tabla liquidaciones (settlements entre miembros de pareja)

Revision ID: 005
Revises: 004
Create Date: 2026-06-15
"""
from alembic import op
import sqlalchemy as sa

revision = "005"
down_revision = "004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "liquidaciones",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pagador_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("receptor_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("monto", sa.Numeric(15, 2), nullable=False),
        sa.Column("nota", sa.String(500), nullable=True),
        sa.Column("fecha", sa.Date, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("monto > 0", name="ck_liquidaciones_monto_positivo"),
    )
    op.create_index("ix_liquidaciones_pareja_id", "liquidaciones", ["pareja_id"])


def downgrade() -> None:
    op.drop_table("liquidaciones")
