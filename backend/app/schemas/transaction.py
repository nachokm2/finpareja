from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, field_validator


class TransactionCreate(BaseModel):
    tipo: str  # 'ingreso' | 'gasto'
    monto: Decimal
    moneda: str = "CLP"
    descripcion: str | None = None
    fecha: date
    categoria_id: int | None = None
    es_compartido: bool = False
    porcentaje_usuario: Decimal = Decimal("100.00")
    recurrente: bool = False
    frecuencia: str | None = None
    notas: str | None = None
    pareja_id: int | None = None
    tarjeta_id: int | None = None

    @field_validator("tipo")
    @classmethod
    def validate_tipo(cls, v: str) -> str:
        if v not in ("ingreso", "gasto"):
            raise ValueError("tipo debe ser 'ingreso' o 'gasto'")
        return v

    @field_validator("monto")
    @classmethod
    def validate_monto(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("monto debe ser mayor a 0")
        return v


class TransactionUpdate(BaseModel):
    tipo: str | None = None
    monto: Decimal | None = None
    descripcion: str | None = None
    fecha: date | None = None
    categoria_id: int | None = None
    es_compartido: bool | None = None
    porcentaje_usuario: Decimal | None = None
    notas: str | None = None


class CategorySummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nombre: str
    icono: str | None
    color: str | None


class TransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    usuario_id: int
    tipo: str
    monto: Decimal
    moneda: str
    descripcion: str | None
    fecha: date
    categoria_id: int | None
    tarjeta_id: int | None = None
    category: CategorySummary | None = None
    es_compartido: bool
    porcentaje_usuario: Decimal
    recurrente: bool
    frecuencia: str | None
    notas: str | None
    created_at: datetime


class TransactionListResponse(BaseModel):
    items: list[TransactionResponse]
    total: int
    page: int
    page_size: int
