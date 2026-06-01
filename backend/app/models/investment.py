from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import String, Date, DateTime, ForeignKey, Numeric, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class Investment(Base):
    __tablename__ = "inversiones"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pareja_id: Mapped[int | None] = mapped_column(
        ForeignKey("parejas.id"), nullable=True
    )
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    tipo: Mapped[str | None] = mapped_column(String(50), nullable=True)
    simbolo: Mapped[str | None] = mapped_column(String(20), nullable=True)
    cantidad: Mapped[Decimal | None] = mapped_column(Numeric(20, 8), nullable=True)
    precio_compra: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    precio_actual: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    moneda: Mapped[str] = mapped_column(String(3), default="CLP", nullable=False)
    fecha_compra: Mapped[date | None] = mapped_column(Date, nullable=True)
    notas: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
