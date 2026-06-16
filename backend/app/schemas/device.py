from pydantic import BaseModel


class DeviceRegister(BaseModel):
    token: str
    plataforma: str | None = None


class DeviceUnregister(BaseModel):
    token: str
