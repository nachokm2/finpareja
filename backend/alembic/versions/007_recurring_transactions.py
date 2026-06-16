"""plantillas de transacciones recurrentes

Revision ID: 007
Revises: 006
Create Date: 2026-06-15
"""
from alembic import op
import sqlalchemy as sa

revision = "007"
down_revision = "006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "transacciones_recurrentes",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id"), nullable=True),
        sa.Column("categoria_id", sa.BigInteger, sa.ForeignKey("categorias.id"), nullable=True),
        sa.Column("tipo", sa.String(10), nullable=False),
        sa.Column("monto", sa.Numeric(15, 2), nullable=False),
        sa.Column("descripcion", sa.String(500), nullable=True),
        sa.Column("frecuencia", sa.String(20), nullable=False),
        sa.Column("proxima_fecha", sa.Date, nullable=False),
        sa.Column("es_compartido", sa.Boolean, nullable=False, server_default=sa.text("false")),
        sa.Column("porcentaje_usuario", sa.Numeric(5, 2), nullable=False, server_default="100.00"),
        sa.Column("activo", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("monto > 0", name="ck_recurrentes_monto_positivo"),
        sa.CheckConstraint("tipo IN ('ingreso', 'gasto')", name="ck_recurrentes_tipo"),
        sa.CheckConstraint("frecuencia IN ('mensual', 'semanal')", name="ck_recurrentes_frecuencia"),
        sa.CheckConstraint("porcentaje_usuario >= 0 AND porcentaje_usuario <= 100", name="ck_recurrentes_porcentaje"),
    )
    op.create_index("ix_recurrentes_usuario_id", "transacciones_recurrentes", ["usuario_id"])
    op.create_index("ix_recurrentes_proxima_fecha", "transacciones_recurrentes", ["proxima_fecha"])


def downgrade() -> None:
    op.drop_table("transacciones_recurrentes")
