from datetime import datetime
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
