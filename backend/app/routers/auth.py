from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..dependencies import get_db, get_current_user
from ..config import get_settings
from ..core.security import (
    verify_password,
    hash_password,
    create_access_token,
    create_refresh_token,
    hash_token,
)
from ..models.user import User, RefreshToken
from ..schemas.auth import LoginRequest, RegisterRequest, TokenResponse, RefreshRequest, LogoutRequest
from ..schemas.user import UserResponse

router = APIRouter()
settings = get_settings()


def _issue_tokens(user_id: int) -> tuple[str, str, str]:
    """Devuelve (access_token, raw_refresh, hashed_refresh)."""
    access = create_access_token(
        subject=user_id,
        secret_key=settings.secret_key,
        algorithm=settings.algorithm,
        expires_minutes=settings.access_token_expire_minutes,
    )
    raw_refresh, hashed_refresh = create_refresh_token()
    return access, raw_refresh, hashed_refresh


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, request: Request, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email.lower()))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales incorrectas")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cuenta desactivada")

    access, raw_refresh, hashed_refresh = _issue_tokens(user.id)
    db.add(RefreshToken(
        user_id=user.id,
        token_hash=hashed_refresh,
        device_info=request.headers.get("user-agent"),
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days),
    ))
    await db.commit()
    return TokenResponse(access_token=access, refresh_token=raw_refresh)


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.email == body.email.lower()))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="El correo ya está registrado")

    user = User(
        email=body.email.lower(),
        password_hash=hash_password(body.password),
        full_name=body.full_name,
        phone_number=body.phone_number,
        avatar_url=body.avatar_url,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return {"message": "Cuenta creada exitosamente", "id": user.id}


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, request: Request, db: AsyncSession = Depends(get_db)):
    token_hash = hash_token(body.refresh_token)
    now = datetime.now(timezone.utc)

    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked_at.is_(None),
            RefreshToken.expires_at > now,
        )
    )
    stored = result.scalar_one_or_none()
    if stored is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token inválido o expirado")

    # Rotación: revocar el anterior, emitir nuevo par
    stored.revoked_at = now
    access, raw_refresh, hashed_refresh = _issue_tokens(stored.user_id)
    db.add(RefreshToken(
        user_id=stored.user_id,
        token_hash=hashed_refresh,
        device_info=request.headers.get("user-agent"),
        expires_at=now + timedelta(days=settings.refresh_token_expire_days),
    ))
    await db.commit()
    return TokenResponse(access_token=access, refresh_token=raw_refresh)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(body: LogoutRequest, db: AsyncSession = Depends(get_db)):
    token_hash = hash_token(body.refresh_token)
    result = await db.execute(select(RefreshToken).where(RefreshToken.token_hash == token_hash))
    stored = result.scalar_one_or_none()
    if stored and stored.revoked_at is None:
        stored.revoked_at = datetime.now(timezone.utc)
        await db.commit()


@router.get("/me", response_model=UserResponse)
async def me(current_user: User = Depends(get_current_user)):
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        is_active=current_user.is_active,
        full_name=current_user.full_name,
        phone_number=current_user.phone_number,
        avatar_url=current_user.avatar_url,
        roles=["user"],
    )
