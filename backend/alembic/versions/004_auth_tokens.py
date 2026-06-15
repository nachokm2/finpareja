"""tabla auth_tokens (OTP para reset de contraseña y verificación de email)

Revision ID: 004
Revises: 003
Create Date: 2026-06-15
"""
from alembic import op
import sqlalchemy as sa

revision = "004"
down_revision = "003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "auth_tokens",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.BigInteger, sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.Column("purpose", sa.String(30), nullable=False),
        sa.Column("code_hash", sa.String(255), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_auth_tokens_user_id", "auth_tokens", ["user_id"])
    op.create_index("ix_auth_tokens_purpose", "auth_tokens", ["purpose"])
    op.create_index("ix_auth_tokens_code_hash", "auth_tokens", ["code_hash"])


def downgrade() -> None:
    op.drop_table("auth_tokens")
