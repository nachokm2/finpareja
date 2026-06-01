from decimal import Decimal
from pydantic import BaseModel, ConfigDict


class BudgetCreate(BaseModel):
    categoria_id: int | None = None
    monto_limite: Decimal
    periodo: str = "mensual"
    mes: int | None = None
    anio: int | None = None
    alerta_porcentaje: Decimal = Decimal("80.00")
    pareja_id: int | None = None


class BudgetUpdate(BaseModel):
    monto_limite: Decimal | None = None
    alerta_porcentaje: Decimal | None = None


class BudgetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    usuario_id: int
    categoria_id: int | None
    monto_limite: Decimal
    periodo: str
    mes: int | None
    anio: int | None
    alerta_porcentaje: Decimal


class BudgetWithUsage(BudgetResponse):
    monto_gastado: Decimal = Decimal("0.00")
    porcentaje_usado: float = 0.0
    alerta_activa: bool = False
