from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from ..dependencies import get_db, get_current_user
from ..models.user import User
from ..models.device_token import DeviceToken
from ..schemas.device import DeviceRegister, DeviceUnregister

router = APIRouter()


@router.post("/registrar", status_code=status.HTTP_204_NO_CONTENT)
async def register_device(
    body: DeviceRegister,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Registra (o reasigna) un token de dispositivo para push. Si el token ya
    existe, se actualiza su dueño y plataforma (idempotente).
    """
    existing = (await db.execute(
        select(DeviceToken).where(DeviceToken.token == body.token)
    )).scalar_one_or_none()

    if existing:
        existing.usuario_id = current_user.id
        existing.plataforma = body.plataforma
    else:
        db.add(DeviceToken(
            usuario_id=current_user.id,
            token=body.token,
            plataforma=body.plataforma,
        ))
    await db.commit()


@router.post("/eliminar", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_device(
    body: DeviceUnregister,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Elimina un token (al cerrar sesión) para no seguir enviándole push."""
    await db.execute(
        delete(DeviceToken).where(
            DeviceToken.token == body.token,
            DeviceToken.usuario_id == current_user.id,
        )
    )
    await db.commit()
