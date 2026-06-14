from typing import AsyncGenerator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from .database import AsyncSessionLocal
from .config import get_settings
from .core.security import decode_access_token

settings = get_settings()
bearer_scheme = HTTPBearer()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
):
    from .models.user import User

    user_id = decode_access_token(
        credentials.credentials,
        settings.secret_key,
        settings.algorithm,
    )
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = await db.get(User, user_id)
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado o inactivo",
        )
    return user


async def assert_couple_member(db: AsyncSession, user_id: int, pareja_id: int | None) -> None:
    """
    Verifica que [user_id] sea miembro de [pareja_id].

    Previene IDOR (OWASP API #1): sin esta comprobación, un usuario podría
    enviar el pareja_id de otra pareja en el body y contaminar sus datos.
    Si pareja_id es None, la entidad es personal y no requiere validación.
    """
    if pareja_id is None:
        return

    from .models.couple import CoupleMember

    result = await db.execute(
        select(CoupleMember).where(
            CoupleMember.pareja_id == pareja_id,
            CoupleMember.usuario_id == user_id,
        )
    )
    if result.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No perteneces a esta pareja",
        )
