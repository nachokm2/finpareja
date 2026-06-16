from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import String, Boolean, Date, DateTime, ForeignKey, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class RecurringTransaction(Base):
    """
    Plantilla de transacción recurrente. No es una transacción en sí: cada vez
    que se 'materializa' (cuando [proxima_fecha] llega), genera una Transaction
    real y avanza [proxima_fecha] según la frecuencia.

    Frecuencias soportadas: 'mensual' | 'semanal'.
    """
    __tablename__ = "transacciones_recurrentes"

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
    tipo: Mapped[str] = mapped_column(String(10), nullable=False)  # 'ingreso' | 'gasto'
    monto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(500), nullable=True)
    frecuencia: Mapped[str] = mapped_column(String(20), nullable=False)  # 'mensual' | 'semanal'
    proxima_fecha: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    es_compartido: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    porcentaje_usuario: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), default=Decimal("100.00"), nullable=False
    )
    activo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
