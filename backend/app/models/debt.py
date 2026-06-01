from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import String, Date, DateTime, ForeignKey, Numeric, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Debt(Base):
    __tablename__ = "deudas"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pareja_id: Mapped[int | None] = mapped_column(
        ForeignKey("parejas.id"), nullable=True
    )
    acreedor: Mapped[str] = mapped_column(String(255), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    monto_original: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    monto_pendiente: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    tasa_interes: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), default=Decimal("0.00"), nullable=False
    )
    fecha_inicio: Mapped[date | None] = mapped_column(Date, nullable=True)
    fecha_vencimiento: Mapped[date | None] = mapped_column(Date, nullable=True)
    tipo: Mapped[str | None] = mapped_column(String(30), nullable=True)
    estado: Mapped[str] = mapped_column(String(20), default="activa", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    payments: Mapped[list[DebtPayment]] = relationship(
        back_populates="debt", cascade="all, delete-orphan"
    )


class DebtPayment(Base):
    __tablename__ = "pagos_deuda"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    deuda_id: Mapped[int] = mapped_column(
        ForeignKey("deudas.id", ondelete="CASCADE"), nullable=False, index=True
    )
    monto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    fecha: Mapped[date] = mapped_column(Date, nullable=False)
    nota: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    debt: Mapped[Debt] = relationship(back_populates="payments")
