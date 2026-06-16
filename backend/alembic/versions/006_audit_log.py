"""audit log inmutable (append-only) para acciones sensibles

Revision ID: 006
Revises: 005
Create Date: 2026-06-15
"""
from alembic import op
import sqlalchemy as sa

revision = "006"
down_revision = "005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "audit_log",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("usuario_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="SET NULL"), nullable=True),
        sa.Column("accion", sa.String(50), nullable=False),
        sa.Column("entidad", sa.String(50), nullable=True),
        sa.Column("entidad_id", sa.Integer, nullable=True),
        sa.Column("detalle", sa.String(500), nullable=True),
        sa.Column("ip", sa.String(64), nullable=True),
        sa.Column("request_id", sa.String(32), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_audit_log_usuario_id", "audit_log", ["usuario_id"])
    op.create_index("ix_audit_log_created_at", "audit_log", ["created_at"])

    # Inmutabilidad a nivel de base de datos: rechaza UPDATE y DELETE.
    # Garantiza que el registro de auditoría no se pueda alterar ni borrar,
    # incluso por código de aplicación con bugs o por accesos directos a la DB.
    op.execute(
        """
        CREATE OR REPLACE FUNCTION audit_log_no_mutate() RETURNS trigger AS $$
        BEGIN
            RAISE EXCEPTION 'audit_log es inmutable: operacion % no permitida', TG_OP;
        END;
        $$ LANGUAGE plpgsql;
        """
    )
    op.execute(
        """
        CREATE TRIGGER trg_audit_log_no_mutate
        BEFORE UPDATE OR DELETE ON audit_log
        FOR EACH ROW EXECUTE FUNCTION audit_log_no_mutate();
        """
    )


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_audit_log_no_mutate ON audit_log;")
    op.execute("DROP FUNCTION IF EXISTS audit_log_no_mutate();")
    op.drop_table("audit_log")
