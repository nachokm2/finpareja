from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, ConfigDict


class DebtCreate(BaseModel):
    acreedor: str
    descripcion: str | None = None
    monto_original: Decimal
    tasa_interes: Decimal = Decimal("0.00")
    fecha_inicio: date | None = None
    fecha_vencimiento: date | None = None
    tipo: str | None = None
    pareja_id: int | None = None


class DebtUpdate(BaseModel):
    acreedor: str | None = None
    descripcion: str | None = None
    tasa_interes: Decimal | None = None
    fecha_vencimiento: date | None = None
    estado: str | None = None


class DebtResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    usuario_id: int
    acreedor: str
    descripcion: str | None
    monto_original: Decimal
    monto_pendiente: Decimal
    tasa_interes: Decimal
    fecha_inicio: date | None
    fecha_vencimiento: date | None
    tipo: str | None
    estado: str
    created_at: datetime


class PaymentCreate(BaseModel):
    monto: Decimal
    fecha: date
    nota: str | None = None


class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    deuda_id: int
    monto: Decimal
    fecha: date
    nota: str | None
    created_at: datetime
