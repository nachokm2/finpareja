from __future__ import annotations
from datetime import datetime

from sqlalchemy import String, Boolean, DateTime, ForeignKey, CheckConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class Category(Base):
    __tablename__ = "categorias"
    __table_args__ = (
        CheckConstraint(
            # es_sistema puede tener ambas FKs en NULL (categorías globales del sistema)
            "(es_sistema = TRUE) OR "
            "(usuario_id IS NOT NULL AND pareja_id IS NULL) OR "
            "(usuario_id IS NULL AND pareja_id IS NOT NULL)",
            name="categoria_owner_check",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int | None] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=True, index=True
    )
    pareja_id: Mapped[int | None] = mapped_column(
        ForeignKey("parejas.id", ondelete="CASCADE"), nullable=True, index=True
    )
    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    icono: Mapped[str | None] = mapped_column(String(50), nullable=True)
    color: Mapped[str | None] = mapped_column(String(7), nullable=True)
    tipo: Mapped[str] = mapped_column(String(10), nullable=False)  # 'ingreso' | 'gasto'
    es_sistema: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
