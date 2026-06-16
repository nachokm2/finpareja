"""
Notificaciones push vía Firebase Cloud Messaging (FCM).

Patrón opt-in con fallback (igual que el email/OTP): si FIREBASE_CREDENTIALS no
está configurado o el paquete firebase-admin no está instalado, los envíos se
registran en el log en vez de enviarse. Así el backend funciona en desarrollo y
en los tests sin credenciales, y nunca rompe una operación de negocio.
"""
from __future__ import annotations

import json
import logging

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..models.device_token import DeviceToken

logger = logging.getLogger("finpareja.push")

_app = None          # instancia firebase_admin inicializada (o None)
_initialized = False  # ya intentamos inicializar (evita reintentos en cada envío)


def _ensure_init() -> bool:
    """Inicializa Firebase una vez. Devuelve True si quedó operativo."""
    global _app, _initialized
    if _initialized:
        return _app is not None
    _initialized = True

    settings = get_settings()
    if not settings.firebase_credentials:
        logger.info("FIREBASE_CREDENTIALS no configurado: push en modo log.")
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(json.loads(settings.firebase_credentials))
        _app = firebase_admin.initialize_app(cred)
        logger.info("Firebase inicializado: push activo.")
        return True
    except Exception:
        logger.exception("No se pudo inicializar Firebase; push en modo log.")
        _app = None
        return False


def _send(tokens: list[str], title: str, body: str, data: dict | None) -> list[str]:
    """
    Envía a una lista de tokens. Devuelve los tokens inválidos (para purgarlos).
    En modo log no envía nada y devuelve [].
    """
    if not tokens:
        return []
    if not _ensure_init():
        logger.info("PUSH (log) -> %s | %s :: %s", title, body, tokens)
        return []

    from firebase_admin import messaging

    invalid: list[str] = []
    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
    )
    try:
        resp = messaging.send_each_for_multicast(message)
    except Exception:
        logger.exception("Fallo enviando push")
        return []

    for tok, res in zip(tokens, resp.responses):
        if not res.success:
            # Token no registrado/!inválido → marcar para purga.
            err = getattr(res.exception, "code", "") or ""
            if "registration-token-not-registered" in str(err) or "invalid-argument" in str(err):
                invalid.append(tok)
    return invalid


async def push_to_user(
    db: AsyncSession,
    user_id: int,
    title: str,
    body: str,
    data: dict | None = None,
) -> None:
    """
    Envía una notificación a todos los dispositivos de un usuario (best-effort).
    Nunca lanza: cualquier error se registra y se ignora. Purga tokens inválidos.
    """
    try:
        tokens = (await db.execute(
            select(DeviceToken.token).where(DeviceToken.usuario_id == user_id)
        )).scalars().all()
        invalid = _send(list(tokens), title, body, data)
        if invalid:
            await db.execute(delete(DeviceToken).where(DeviceToken.token.in_(invalid)))
            await db.commit()
    except Exception:
        logger.exception("push_to_user falló para usuario %s", user_id)
