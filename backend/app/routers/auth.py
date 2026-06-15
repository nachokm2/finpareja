from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..dependencies import get_db, get_current_user
from ..config import get_settings
from ..core.email import send_otp_email
from ..core.rate_limit import limiter
from ..core.security import (
    verify_password,
    hash_password,
    create_access_token,
    create_refresh_token,
    hash_token,
    generate_otp,
    verify_otp,
)
from ..models.user import User, RefreshToken
from ..models.auth_token import AuthToken
from ..schemas.auth import (
    LoginRequest, RegisterRequest, TokenResponse, RefreshRequest, LogoutRequest,
    ForgotPasswordRequest, ResetPasswordRequest, VerifyEmailRequest,
    ResendVerificationRequest,
)
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


async def _create_and_send_otp(db: AsyncSession, user: User, purpose: str) -> None:
    """Genera un OTP, invalida los anteriores del mismo propósito y lo envía."""
    # Invalida OTPs previos no usados (un solo código activo por propósito).
    previous = await db.execute(
        select(AuthToken).where(
            AuthToken.user_id == user.id,
            AuthToken.purpose == purpose,
            AuthToken.used_at.is_(None),
        )
    )
    now = datetime.now(timezone.utc)
    for tok in previous.scalars().all():
        tok.used_at = now

    code, code_hash = generate_otp()
    db.add(AuthToken(
        user_id=user.id,
        purpose=purpose,
        code_hash=code_hash,
        expires_at=now + timedelta(minutes=15),
    ))
    await db.commit()
    send_otp_email(user.email, code, purpose)


async def _consume_otp(db: AsyncSession, user: User, purpose: str, code: str) -> bool:
    """Verifica y marca como usado un OTP válido. False si no existe/expiró."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(AuthToken).where(
            AuthToken.user_id == user.id,
            AuthToken.purpose == purpose,
            AuthToken.used_at.is_(None),
            AuthToken.expires_at > now,
        )
    )
    for tok in result.scalars().all():
        if verify_otp(code, tok.code_hash):
            tok.used_at = now
            return True
    return False


@router.post("/login", response_model=TokenResponse)
@limiter.limit("5/minute")
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
@limiter.limit("3/minute")
async def register(body: RegisterRequest, request: Request, db: AsyncSession = Depends(get_db)):
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

    # Envía código de verificación de email (best-effort, no bloquea el registro).
    await _create_and_send_otp(db, user, "email_verification")
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


async def _get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email.lower()))
    return result.scalar_one_or_none()


# Respuesta genérica: no revela si el correo existe (evita enumeration).
_GENERIC_OK = {"message": "Si el correo existe, enviamos un código."}


@router.post("/forgot-password")
@limiter.limit("3/minute")
async def forgot_password(
    body: ForgotPasswordRequest, request: Request, db: AsyncSession = Depends(get_db)
):
    user = await _get_user_by_email(db, body.email)
    if user is not None:
        await _create_and_send_otp(db, user, "password_reset")
    return _GENERIC_OK


@router.post("/reset-password")
@limiter.limit("5/minute")
async def reset_password(
    body: ResetPasswordRequest, request: Request, db: AsyncSession = Depends(get_db)
):
    user = await _get_user_by_email(db, body.email)
    if user is None or not await _consume_otp(db, user, "password_reset", body.code):
        raise HTTPException(status_code=400, detail="Código inválido o expirado")

    user.password_hash = hash_password(body.new_password)
    # Por seguridad, revoca todas las sesiones activas tras el cambio.
    sessions = await db.execute(
        select(RefreshToken).where(
            RefreshToken.user_id == user.id, RefreshToken.revoked_at.is_(None)
        )
    )
    now = datetime.now(timezone.utc)
    for s in sessions.scalars().all():
        s.revoked_at = now
    await db.commit()
    return {"message": "Contraseña actualizada. Inicia sesión nuevamente."}


@router.post("/verify-email")
@limiter.limit("5/minute")
async def verify_email(
    body: VerifyEmailRequest, request: Request, db: AsyncSession = Depends(get_db)
):
    user = await _get_user_by_email(db, body.email)
    if user is None or not await _consume_otp(db, user, "email_verification", body.code):
        raise HTTPException(status_code=400, detail="Código inválido o expirado")
    user.is_verified = True
    await db.commit()
    return {"message": "Correo verificado correctamente."}


@router.post("/resend-verification")
@limiter.limit("3/minute")
async def resend_verification(
    body: ResendVerificationRequest, request: Request, db: AsyncSession = Depends(get_db)
):
    user = await _get_user_by_email(db, body.email)
    if user is not None and not user.is_verified:
        await _create_and_send_otp(db, user, "email_verification")
    return _GENERIC_OK
