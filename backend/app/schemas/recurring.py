from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, field_validator


class RecurringCreate(BaseModel):
    tipo: str  # 'ingreso' | 'gasto'
    monto: Decimal
    descripcion: str | None = None
    categoria_id: int | None = None
    frecuencia: str  # 'mensual' | 'semanal'
    proxima_fecha: date
    es_compartido: bool = False
    porcentaje_usuario: Decimal = Decimal("100.00")
    pareja_id: int | None = None

    @field_validator("tipo")
    @classmethod
    def _validate_tipo(cls, v: str) -> str:
        if v not in ("ingreso", "gasto"):
            raise ValueError("tipo debe ser 'ingreso' o 'gasto'")
        return v

    @field_validator("frecuencia")
    @classmethod
    def _validate_frecuencia(cls, v: str) -> str:
        if v not in ("mensual", "semanal"):
            raise ValueError("frecuencia debe ser 'mensual' o 'semanal'")
        return v

    @field_validator("monto")
    @classmethod
    def _validate_monto(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("monto debe ser mayor a 0")
        return v


class RecurringUpdate(BaseModel):
    monto: Decimal | None = None
    descripcion: str | None = None
    frecuencia: str | None = None
    proxima_fecha: date | None = None
    activo: bool | None = None

    @field_validator("frecuencia")
    @classmethod
    def _validate_frecuencia(cls, v: str | None) -> str | None:
        if v is not None and v not in ("mensual", "semanal"):
            raise ValueError("frecuencia debe ser 'mensual' o 'semanal'")
        return v


class RecurringResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    usuario_id: int
    pareja_id: int | None
    categoria_id: int | None
    tipo: str
    monto: Decimal
    descripcion: str | None
    frecuencia: str
    proxima_fecha: date
    es_compartido: bool
    porcentaje_usuario: Decimal
    activo: bool
