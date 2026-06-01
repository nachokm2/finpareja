from pydantic import BaseModel, EmailStr, ConfigDict


class UserResponse(BaseModel):
    """
    Response schema que coincide exactamente con lo que espera
    la app Flutter en UserModel.fromJson().
    Campos requeridos: id, email, is_active, full_name, phone_number, avatar_url, roles
    """
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    is_active: bool
    full_name: str
    phone_number: str | None = None
    avatar_url: str | None = None
    roles: list[str] = ["user"]


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone_number: str | None = None
    avatar_url: str | None = None
    currency: str | None = None
