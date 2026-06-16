from __future__ import annotations
from datetime import datetime

from sqlalchemy import String, DateTime, ForeignKey, Integer, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class AuditLog(Base):
    """
    Registro de auditoría append-only de acciones sensibles (login, movimientos
    de dinero, cambios de seguridad). Inmutabilidad:
      - A nivel de aplicación nunca se exponen UPDATE/DELETE sobre esta tabla.
      - A nivel de base de datos (Postgres) la migración instala un trigger que
        rechaza UPDATE y DELETE, de modo que el log no se puede alterar.

    No almacena datos sensibles (montos exactos opcionales en 'detalle', nunca
    contraseñas ni tokens) para cumplir con la Ley 19.628.
    """
    __tablename__ = "audit_log"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int | None] = mapped_column(
        ForeignKey("usuarios.id", ondelete="SET NULL"), nullable=True, index=True
    )
    accion: Mapped[str] = mapped_column(String(50), nullable=False)
    entidad: Mapped[str | None] = mapped_column(String(50), nullable=True)
    entidad_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    detalle: Mapped[str | None] = mapped_column(String(500), nullable=True)
    ip: Mapped[str | None] = mapped_column(String(64), nullable=True)
    request_id: Mapped[str | None] = mapped_column(String(32), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
