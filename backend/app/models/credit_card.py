from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import String, Integer, Date, DateTime, ForeignKey, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class CreditCard(Base):
    """
    Tarjeta de crédito registrada SOLO para control financiero (no se realizan
    pagos desde la app). El saldo se calcula desde compras - pagos.
    """
    __tablename__ = "tarjetas_credito"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pareja_id: Mapped[int | None] = mapped_column(ForeignKey("parejas.id"), nullable=True)
    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    emisor: Mapped[str | None] = mapped_column(String(100), nullable=True)
    ultimos_digitos: Mapped[str | None] = mapped_column(String(4), nullable=True)
    cupo: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class CardPurchase(Base):
    """
    Compra realizada con una tarjeta. Puede ser al contado (cuotas=1) o en
    cuotas. La deuda que aporta esta compra es:
      - cuotas <= 1 → monto
      - cuotas  > 1 → valor_cuota * cuotas (incluye intereses)
    """
    __tablename__ = "compras_tarjeta"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    tarjeta_id: Mapped[int] = mapped_column(
        ForeignKey("tarjetas_credito.id", ondelete="CASCADE"), nullable=False, index=True
    )
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False
    )
    descripcion: Mapped[str | None] = mapped_column(String(500), nullable=True)
    monto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)  # precio compra
    fecha: Mapped[date] = mapped_column(Date, nullable=False)
    categoria_id: Mapped[int | None] = mapped_column(ForeignKey("categorias.id"), nullable=True)
    cuotas: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    valor_cuota: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    interes: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    # Si la compra proviene de un gasto, queda enlazada (se borra junto al gasto).
    transaction_id: Mapped[int | None] = mapped_column(
        ForeignKey("transacciones.id", ondelete="CASCADE"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class CardPayment(Base):
    """Pago realizado a la deuda de una tarjeta (reduce el saldo pendiente)."""
    __tablename__ = "pagos_tarjeta"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    tarjeta_id: Mapped[int] = mapped_column(
        ForeignKey("tarjetas_credito.id", ondelete="CASCADE"), nullable=False, index=True
    )
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False
    )
    monto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    fecha: Mapped[date] = mapped_column(Date, nullable=False)
    nota: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
