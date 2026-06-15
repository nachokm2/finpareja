from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, EmailStr


class CoupleCreate(BaseModel):
    nombre: str | None = None


class CoupleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str | None
    currency: str
    created_at: datetime
    member_count: int = 0


class InviteRequest(BaseModel):
    email: EmailStr


class AcceptInviteRequest(BaseModel):
    token: str


class SettleRequest(BaseModel):
    monto: Decimal
    fecha: date
    nota: str | None = None


class SettlementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    pagador_id: int
    receptor_id: int
    monto: Decimal
    nota: str | None
    fecha: date
    created_at: datetime
