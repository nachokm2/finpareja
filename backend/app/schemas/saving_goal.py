from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, ConfigDict


class SavingGoalCreate(BaseModel):
    nombre: str
    descripcion: str | None = None
    monto_objetivo: Decimal
    moneda: str = "CLP"
    fecha_objetivo: date | None = None
    icono: str | None = None
    color: str | None = None
    pareja_id: int | None = None


class SavingGoalUpdate(BaseModel):
    nombre: str | None = None
    descripcion: str | None = None
    monto_objetivo: Decimal | None = None
    fecha_objetivo: date | None = None
    icono: str | None = None
    color: str | None = None
    estado: str | None = None


class SavingGoalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    usuario_id: int
    pareja_id: int | None
    nombre: str
    descripcion: str | None
    monto_objetivo: Decimal
    monto_actual: Decimal
    moneda: str
    fecha_objetivo: date | None
    icono: str | None
    color: str | None
    estado: str
    progreso_porcentaje: float = 0.0
    created_at: datetime


class ContributionCreate(BaseModel):
    monto: Decimal
    nota: str | None = None
    fecha: date


class ContributionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    meta_id: int
    usuario_id: int
    monto: Decimal
    nota: str | None
    fecha: date
    created_at: datetime
