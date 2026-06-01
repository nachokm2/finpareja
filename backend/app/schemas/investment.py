from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, ConfigDict


class InvestmentCreate(BaseModel):
    nombre: str
    tipo: str | None = None
    simbolo: str | None = None
    cantidad: Decimal | None = None
    precio_compra: Decimal | None = None
    precio_actual: Decimal | None = None
    moneda: str = "CLP"
    fecha_compra: date | None = None
    notas: str | None = None
    pareja_id: int | None = None


class InvestmentUpdate(BaseModel):
    nombre: str | None = None
    precio_actual: Decimal | None = None
    cantidad: Decimal | None = None
    notas: str | None = None


class InvestmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    usuario_id: int
    nombre: str
    tipo: str | None
    simbolo: str | None
    cantidad: Decimal | None
    precio_compra: Decimal | None
    precio_actual: Decimal | None
    moneda: str
    fecha_compra: date | None
    notas: str | None
    valor_actual: Decimal | None = None
    ganancia_perdida: Decimal | None = None
    created_at: datetime
