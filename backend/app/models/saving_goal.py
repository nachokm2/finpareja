from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import String, Boolean, Date, DateTime, ForeignKey, Numeric, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class SavingGoal(Base):
    __tablename__ = "metas_ahorro"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pareja_id: Mapped[int | None] = mapped_column(
        ForeignKey("parejas.id"), nullable=True
    )
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    monto_objetivo: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    monto_actual: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), default=Decimal("0.00"), nullable=False
    )
    moneda: Mapped[str] = mapped_column(String(3), default="CLP", nullable=False)
    fecha_objetivo: Mapped[date | None] = mapped_column(Date, nullable=True)
    icono: Mapped[str | None] = mapped_column(String(50), nullable=True)
    color: Mapped[str | None] = mapped_column(String(7), nullable=True)
    estado: Mapped[str] = mapped_column(String(20), default="activa", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    contributions: Mapped[list[SavingGoalContribution]] = relationship(
        back_populates="goal", cascade="all, delete-orphan"
    )


class SavingGoalContribution(Base):
    __tablename__ = "aportes_meta"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    meta_id: Mapped[int] = mapped_column(
        ForeignKey("metas_ahorro.id", ondelete="CASCADE"), nullable=False, index=True
    )
    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"), nullable=False)
    monto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    nota: Mapped[str | None] = mapped_column(String(500), nullable=True)
    fecha: Mapped[date] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    goal: Mapped[SavingGoal] = relationship(back_populates="contributions")
