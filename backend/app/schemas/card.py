from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, field_validator


# ── Tarjeta ──────────────────────────────────────────────────────────────────
class CardCreate(BaseModel):
    nombre: str
    emisor: str | None = None
    ultimos_digitos: str | None = None
    cupo: Decimal | None = None
    color: str | None = None
    pareja_id: int | None = None


class CardResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    usuario_id: int
    nombre: str
    emisor: str | None
    ultimos_digitos: str | None
    cupo: Decimal | None
    color: str | None


class CardSummary(CardResponse):
    saldo_pendiente: Decimal = Decimal("0")
    total_compras: Decimal = Decimal("0")
    total_pagado: Decimal = Decimal("0")
    cupo_disponible: Decimal | None = None


# ── Compra ───────────────────────────────────────────────────────────────────
class PurchaseCreate(BaseModel):
    descripcion: str | None = None
    monto: Decimal
    fecha: date
    categoria_id: int | None = None
    cuotas: int = 1
    valor_cuota: Decimal | None = None
    interes: Decimal | None = None

    @field_validator("monto")
    @classmethod
    def _monto(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("monto debe ser mayor a 0")
        return v

    @field_validator("cuotas")
    @classmethod
    def _cuotas(cls, v: int) -> int:
        if v < 1:
            raise ValueError("cuotas debe ser al menos 1")
        return v


class PurchaseResponse(BaseModel):
    id: int
    tarjeta_id: int
    descripcion: str | None
    monto: Decimal
    fecha: date
    categoria_id: int | None
    cuotas: int
    valor_cuota: Decimal | None
    interes: Decimal | None
    deuda: Decimal  # cuánto aporta esta compra a la deuda (con intereses)


# ── Pago ─────────────────────────────────────────────────────────────────────
class PaymentCreate(BaseModel):
    monto: Decimal
    fecha: date
    nota: str | None = None

    @field_validator("monto")
    @classmethod
    def _monto(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("monto debe ser mayor a 0")
        return v


class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tarjeta_id: int
    monto: Decimal
    fecha: date
    nota: str | None
