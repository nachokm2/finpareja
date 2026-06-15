from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import String, Date, DateTime, ForeignKey, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class Settlement(Base):
    """
    Liquidación entre miembros de una pareja: un pago de [pagador_id] a
    [receptor_id] para saldar (parcial o totalmente) lo que se deben por
    gastos compartidos. Reduce el balance neto entre ambos.
    """
    __tablename__ = "liquidaciones"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    pareja_id: Mapped[int] = mapped_column(
        ForeignKey("parejas.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pagador_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False
    )
    receptor_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False
    )
    monto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    nota: Mapped[str | None] = mapped_column(String(500), nullable=True)
    fecha: Mapped[date] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
