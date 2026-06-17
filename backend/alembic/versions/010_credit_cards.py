"""tarjetas de credito: tarjetas, compras y pagos (+ tarjeta_id en transacciones)

Revision ID: 010
Revises: 009
Create Date: 2026-06-16
"""
from alembic import op
import sqlalchemy as sa

revision = "010"
down_revision = "009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "tarjetas_credito",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id"), nullable=True),
        sa.Column("nombre", sa.String(100), nullable=False),
        sa.Column("emisor", sa.String(100), nullable=True),
        sa.Column("ultimos_digitos", sa.String(4), nullable=True),
        sa.Column("cupo", sa.Numeric(15, 2), nullable=True),
        sa.Column("color", sa.String(20), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_tarjetas_usuario_id", "tarjetas_credito", ["usuario_id"])

    op.create_table(
        "compras_tarjeta",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("tarjeta_id", sa.BigInteger, sa.ForeignKey("tarjetas_credito.id", ondelete="CASCADE"), nullable=False),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("descripcion", sa.String(500), nullable=True),
        sa.Column("monto", sa.Numeric(15, 2), nullable=False),
        sa.Column("fecha", sa.Date, nullable=False),
        sa.Column("categoria_id", sa.BigInteger, sa.ForeignKey("categorias.id"), nullable=True),
        sa.Column("cuotas", sa.Integer, nullable=False, server_default="1"),
        sa.Column("valor_cuota", sa.Numeric(15, 2), nullable=True),
        sa.Column("interes", sa.Numeric(15, 2), nullable=True),
        sa.Column("transaction_id", sa.BigInteger, sa.ForeignKey("transacciones.id", ondelete="CASCADE"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("monto > 0", name="ck_compras_monto_positivo"),
        sa.CheckConstraint("cuotas >= 1", name="ck_compras_cuotas"),
    )
    op.create_index("ix_compras_tarjeta_id", "compras_tarjeta", ["tarjeta_id"])

    op.create_table(
        "pagos_tarjeta",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("tarjeta_id", sa.BigInteger, sa.ForeignKey("tarjetas_credito.id", ondelete="CASCADE"), nullable=False),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("monto", sa.Numeric(15, 2), nullable=False),
        sa.Column("fecha", sa.Date, nullable=False),
        sa.Column("nota", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("monto > 0", name="ck_pagos_tarjeta_monto_positivo"),
    )
    op.create_index("ix_pagos_tarjeta_id", "pagos_tarjeta", ["tarjeta_id"])

    op.add_column(
        "transacciones",
        sa.Column("tarjeta_id", sa.BigInteger, sa.ForeignKey("tarjetas_credito.id"), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("transacciones", "tarjeta_id")
    op.drop_table("pagos_tarjeta")
    op.drop_table("compras_tarjeta")
    op.drop_table("tarjetas_credito")
