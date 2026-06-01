from __future__ import annotations
from decimal import Decimal

from sqlalchemy import String, DateTime, ForeignKey, Integer, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from ..database import Base


class Budget(Base):
    __tablename__ = "presupuestos"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pareja_id: Mapped[int | None] = mapped_column(
        ForeignKey("parejas.id"), nullable=True
    )
    categoria_id: Mapped[int | None] = mapped_column(
        ForeignKey("categorias.id"), nullable=True
    )
    monto_limite: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    periodo: Mapped[str] = mapped_column(String(10), default="mensual", nullable=False)
    mes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    anio: Mapped[int | None] = mapped_column(Integer, nullable=True)
    alerta_porcentaje: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), default=Decimal("80.00"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
