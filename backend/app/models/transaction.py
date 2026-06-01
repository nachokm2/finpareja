from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import String, Boolean, Date, DateTime, ForeignKey, Numeric, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base
from .category import Category


class Transaction(Base):
    __tablename__ = "transacciones"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pareja_id: Mapped[int | None] = mapped_column(
        ForeignKey("parejas.id"), nullable=True, index=True
    )
    categoria_id: Mapped[int | None] = mapped_column(
        ForeignKey("categorias.id"), nullable=True
    )
    tipo: Mapped[str] = mapped_column(String(10), nullable=False)  # 'ingreso' | 'gasto'
    monto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    moneda: Mapped[str] = mapped_column(String(3), default="CLP", nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(500), nullable=True)
    fecha: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    es_compartido: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    porcentaje_usuario: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), default=Decimal("100.00"), nullable=False
    )
    recurrente: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    frecuencia: Mapped[str | None] = mapped_column(String(20), nullable=True)
    notas: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    category: Mapped[Category | None] = relationship(lazy="joined")
