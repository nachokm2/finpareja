"""constraints de integridad financiera (DATA-01)

Agrega CHECK constraints que el modelo no garantizaba:
  - montos siempre positivos
  - 'tipo' restringido a valores válidos
  - porcentajes en rango 0-100

Estos constraints protegen contra datos corruptos sin importar si el bug
viene del cliente, del backend o de una inserción manual.

Revision ID: 003
Revises: 002
Create Date: 2026-06-14
"""
from alembic import op

revision = "003"
down_revision = "002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Transacciones ────────────────────────────────────────────────────────
    op.create_check_constraint(
        "ck_transacciones_monto_positivo", "transacciones", "monto > 0"
    )
    op.create_check_constraint(
        "ck_transacciones_tipo_valido",
        "transacciones",
        "tipo IN ('ingreso', 'gasto')",
    )
    op.create_check_constraint(
        "ck_transacciones_porcentaje_rango",
        "transacciones",
        "porcentaje_usuario >= 0 AND porcentaje_usuario <= 100",
    )

    # ── Presupuestos ─────────────────────────────────────────────────────────
    op.create_check_constraint(
        "ck_presupuestos_monto_positivo", "presupuestos", "monto_limite > 0"
    )
    op.create_check_constraint(
        "ck_presupuestos_alerta_rango",
        "presupuestos",
        "alerta_porcentaje >= 0 AND alerta_porcentaje <= 100",
    )

    # ── Metas de ahorro ──────────────────────────────────────────────────────
    op.create_check_constraint(
        "ck_metas_objetivo_positivo", "metas_ahorro", "monto_objetivo > 0"
    )
    op.create_check_constraint(
        "ck_metas_actual_no_negativo", "metas_ahorro", "monto_actual >= 0"
    )

    # ── Aportes a metas ──────────────────────────────────────────────────────
    op.create_check_constraint(
        "ck_aportes_monto_positivo", "aportes_meta", "monto > 0"
    )

    # ── Categorías ───────────────────────────────────────────────────────────
    op.create_check_constraint(
        "ck_categorias_tipo_valido",
        "categorias",
        "tipo IN ('ingreso', 'gasto')",
    )

    # ── Deudas ───────────────────────────────────────────────────────────────
    op.create_check_constraint(
        "ck_deudas_original_positivo", "deudas", "monto_original > 0"
    )
    op.create_check_constraint(
        "ck_deudas_pendiente_no_negativo", "deudas", "monto_pendiente >= 0"
    )

    # ── Pagos de deuda ───────────────────────────────────────────────────────
    op.create_check_constraint(
        "ck_pagos_monto_positivo", "pagos_deuda", "monto > 0"
    )


def downgrade() -> None:
    op.drop_constraint("ck_pagos_monto_positivo", "pagos_deuda", type_="check")
    op.drop_constraint("ck_deudas_pendiente_no_negativo", "deudas", type_="check")
    op.drop_constraint("ck_deudas_original_positivo", "deudas", type_="check")
    op.drop_constraint("ck_categorias_tipo_valido", "categorias", type_="check")
    op.drop_constraint("ck_aportes_monto_positivo", "aportes_meta", type_="check")
    op.drop_constraint("ck_metas_actual_no_negativo", "metas_ahorro", type_="check")
    op.drop_constraint("ck_metas_objetivo_positivo", "metas_ahorro", type_="check")
    op.drop_constraint("ck_presupuestos_alerta_rango", "presupuestos", type_="check")
    op.drop_constraint("ck_presupuestos_monto_positivo", "presupuestos", type_="check")
    op.drop_constraint("ck_transacciones_porcentaje_rango", "transacciones", type_="check")
    op.drop_constraint("ck_transacciones_tipo_valido", "transacciones", type_="check")
    op.drop_constraint("ck_transacciones_monto_positivo", "transacciones", type_="check")
