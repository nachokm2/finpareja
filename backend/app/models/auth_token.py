from __future__ import annotations
from datetime import datetime

from sqlalchemy import String, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class AuthToken(Base):
    """
    Códigos de un solo uso (OTP) para recuperación de contraseña y
    verificación de email. Se guarda solo el hash del código, nunca el
    código en claro (mismo criterio que refresh_tokens).
    """
    __tablename__ = "auth_tokens"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # 'password_reset' | 'email_verification'
    purpose: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
