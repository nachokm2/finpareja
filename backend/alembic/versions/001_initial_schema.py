"""initial schema

Revision ID: 001
Revises:
Create Date: 2026-05-31
"""
from alembic import op
import sqlalchemy as sa

revision = "001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── usuarios ─────────────────────────────────────────────────────────────
    op.create_table(
        "usuarios",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("phone_number", sa.String(20), nullable=True),
        sa.Column("avatar_url", sa.String(500), nullable=True),
        sa.Column("currency", sa.String(3), server_default="CLP", nullable=False),
        sa.Column("locale", sa.String(10), server_default="es-CL", nullable=False),
        sa.Column("is_active", sa.Boolean, server_default=sa.true(), nullable=False),
        sa.Column("is_verified", sa.Boolean, server_default=sa.false(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_usuarios_email", "usuarios", ["email"], unique=True)

    # ── refresh_tokens ────────────────────────────────────────────────────────
    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token_hash", sa.String(255), nullable=False),
        sa.Column("device_info", sa.String(500), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"])
    op.create_index("ix_refresh_tokens_token_hash", "refresh_tokens", ["token_hash"], unique=True)

    # ── parejas ───────────────────────────────────────────────────────────────
    op.create_table(
        "parejas",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("nombre", sa.String(255), nullable=True),
        sa.Column("currency", sa.String(3), server_default="CLP", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # ── pareja_miembros ───────────────────────────────────────────────────────
    op.create_table(
        "pareja_miembros",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id", ondelete="CASCADE"), nullable=False),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("rol", sa.String(20), server_default="member", nullable=False),
        sa.Column("joined_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("pareja_id", "usuario_id", name="uq_pareja_usuario"),
    )
    op.create_index("ix_pareja_miembros_usuario_id", "pareja_miembros", ["usuario_id"])
    op.create_index("ix_pareja_miembros_pareja_id", "pareja_miembros", ["pareja_id"])

    # ── pareja_invitaciones ───────────────────────────────────────────────────
    op.create_table(
        "pareja_invitaciones",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id", ondelete="CASCADE"), nullable=False),
        sa.Column("invitado_por", sa.BigInteger, sa.ForeignKey("usuarios.id"), nullable=False),
        sa.Column("email_invitado", sa.String(255), nullable=False),
        sa.Column("token", sa.String(255), nullable=False),
        sa.Column("estado", sa.String(20), server_default="pending", nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_pareja_invitaciones_token", "pareja_invitaciones", ["token"], unique=True)

    # ── categorias ────────────────────────────────────────────────────────────
    op.create_table(
        "categorias",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=True),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id", ondelete="CASCADE"), nullable=True),
        sa.Column("nombre", sa.String(100), nullable=False),
        sa.Column("icono", sa.String(50), nullable=True),
        sa.Column("color", sa.String(7), nullable=True),
        sa.Column("tipo", sa.String(10), nullable=False),
        sa.Column("es_sistema", sa.Boolean, server_default=sa.false(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint(
            "(es_sistema = TRUE) OR "
            "(usuario_id IS NOT NULL AND pareja_id IS NULL) OR "
            "(usuario_id IS NULL AND pareja_id IS NOT NULL)",
            name="categoria_owner_check",
        ),
    )
    op.create_index("ix_categorias_usuario_id", "categorias", ["usuario_id"])

    # ── transacciones ─────────────────────────────────────────────────────────
    op.create_table(
        "transacciones",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id"), nullable=True),
        sa.Column("categoria_id", sa.BigInteger, sa.ForeignKey("categorias.id"), nullable=True),
        sa.Column("tipo", sa.String(10), nullable=False),
        sa.Column("monto", sa.Numeric(15, 2), nullable=False),
        sa.Column("moneda", sa.String(3), server_default="CLP", nullable=False),
        sa.Column("descripcion", sa.String(500), nullable=True),
        sa.Column("fecha", sa.Date, nullable=False),
        sa.Column("es_compartido", sa.Boolean, server_default=sa.false(), nullable=False),
        sa.Column("porcentaje_usuario", sa.Numeric(5, 2), server_default="100.00", nullable=False),
        sa.Column("recurrente", sa.Boolean, server_default=sa.false(), nullable=False),
        sa.Column("frecuencia", sa.String(20), nullable=True),
        sa.Column("notas", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_transacciones_usuario_id", "transacciones", ["usuario_id"])
    op.create_index("ix_transacciones_fecha", "transacciones", ["fecha"])
    op.create_index("ix_transacciones_tipo", "transacciones", ["tipo"])

    # ── presupuestos ──────────────────────────────────────────────────────────
    op.create_table(
        "presupuestos",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id"), nullable=True),
        sa.Column("categoria_id", sa.BigInteger, sa.ForeignKey("categorias.id"), nullable=True),
        sa.Column("monto_limite", sa.Numeric(15, 2), nullable=False),
        sa.Column("periodo", sa.String(10), server_default="mensual", nullable=False),
        sa.Column("mes", sa.Integer, nullable=True),
        sa.Column("anio", sa.Integer, nullable=True),
        sa.Column("alerta_porcentaje", sa.Numeric(5, 2), server_default="80.00", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_presupuestos_usuario_id", "presupuestos", ["usuario_id"])

    # ── metas_ahorro ──────────────────────────────────────────────────────────
    op.create_table(
        "metas_ahorro",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id"), nullable=True),
        sa.Column("nombre", sa.String(255), nullable=False),
        sa.Column("descripcion", sa.Text, nullable=True),
        sa.Column("monto_objetivo", sa.Numeric(15, 2), nullable=False),
        sa.Column("monto_actual", sa.Numeric(15, 2), server_default="0.00", nullable=False),
        sa.Column("moneda", sa.String(3), server_default="CLP", nullable=False),
        sa.Column("fecha_objetivo", sa.Date, nullable=True),
        sa.Column("icono", sa.String(50), nullable=True),
        sa.Column("color", sa.String(7), nullable=True),
        sa.Column("estado", sa.String(20), server_default="activa", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # ── aportes_meta ──────────────────────────────────────────────────────────
    op.create_table(
        "aportes_meta",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("meta_id", sa.BigInteger, sa.ForeignKey("metas_ahorro.id", ondelete="CASCADE"), nullable=False),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id"), nullable=False),
        sa.Column("monto", sa.Numeric(15, 2), nullable=False),
        sa.Column("nota", sa.String(500), nullable=True),
        sa.Column("fecha", sa.Date, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_aportes_meta_meta_id", "aportes_meta", ["meta_id"])

    # ── deudas ────────────────────────────────────────────────────────────────
    op.create_table(
        "deudas",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id"), nullable=True),
        sa.Column("acreedor", sa.String(255), nullable=False),
        sa.Column("descripcion", sa.Text, nullable=True),
        sa.Column("monto_original", sa.Numeric(15, 2), nullable=False),
        sa.Column("monto_pendiente", sa.Numeric(15, 2), nullable=False),
        sa.Column("tasa_interes", sa.Numeric(5, 2), server_default="0.00", nullable=False),
        sa.Column("fecha_inicio", sa.Date, nullable=True),
        sa.Column("fecha_vencimiento", sa.Date, nullable=True),
        sa.Column("tipo", sa.String(30), nullable=True),
        sa.Column("estado", sa.String(20), server_default="activa", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_deudas_usuario_id", "deudas", ["usuario_id"])

    # ── pagos_deuda ───────────────────────────────────────────────────────────
    op.create_table(
        "pagos_deuda",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("deuda_id", sa.BigInteger, sa.ForeignKey("deudas.id", ondelete="CASCADE"), nullable=False),
        sa.Column("monto", sa.Numeric(15, 2), nullable=False),
        sa.Column("fecha", sa.Date, nullable=False),
        sa.Column("nota", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_pagos_deuda_deuda_id", "pagos_deuda", ["deuda_id"])

    # ── inversiones ───────────────────────────────────────────────────────────
    op.create_table(
        "inversiones",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pareja_id", sa.BigInteger, sa.ForeignKey("parejas.id"), nullable=True),
        sa.Column("nombre", sa.String(255), nullable=False),
        sa.Column("tipo", sa.String(50), nullable=True),
        sa.Column("simbolo", sa.String(20), nullable=True),
        sa.Column("cantidad", sa.Numeric(20, 8), nullable=True),
        sa.Column("precio_compra", sa.Numeric(15, 2), nullable=True),
        sa.Column("precio_actual", sa.Numeric(15, 2), nullable=True),
        sa.Column("moneda", sa.String(3), server_default="CLP", nullable=False),
        sa.Column("fecha_compra", sa.Date, nullable=True),
        sa.Column("notas", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_inversiones_usuario_id", "inversiones", ["usuario_id"])


def downgrade() -> None:
    op.drop_table("inversiones")
    op.drop_table("pagos_deuda")
    op.drop_table("deudas")
    op.drop_table("aportes_meta")
    op.drop_table("metas_ahorro")
    op.drop_table("presupuestos")
    op.drop_table("transacciones")
    op.drop_table("categorias")
    op.drop_table("pareja_invitaciones")
    op.drop_table("pareja_miembros")
    op.drop_table("parejas")
    op.drop_table("refresh_tokens")
    op.drop_table("usuarios")
