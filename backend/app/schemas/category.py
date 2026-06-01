from datetime import datetime
from pydantic import BaseModel, ConfigDict


class CategoryCreate(BaseModel):
    nombre: str
    icono: str | None = None
    color: str | None = None
    tipo: str  # 'ingreso' | 'gasto'
    pareja_id: int | None = None  # si es None, es categoría personal


class CategoryUpdate(BaseModel):
    nombre: str | None = None
    icono: str | None = None
    color: str | None = None


class CategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    icono: str | None
    color: str | None
    tipo: str
    es_sistema: bool
    usuario_id: int | None
    pareja_id: int | None
    created_at: datetime
