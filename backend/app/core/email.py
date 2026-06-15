"""
Envío de emails (códigos OTP).

Estrategia de degradación elegante:
- Si SMTP_HOST está configurado → envía el correo de verdad vía SMTP.
- Si no → registra el código en el log (visible en Railway). Permite que el
  flujo completo funcione end-to-end en dev o antes de contratar un proveedor.

Para producción real, basta con configurar las variables SMTP_* (p. ej.
Resend, SendGrid, Mailgun o Gmail con app password).
"""
import logging
import smtplib
from email.message import EmailMessage

from ..config import get_settings

logger = logging.getLogger("finpareja.email")
settings = get_settings()


def _send_smtp(to: str, subject: str, body: str) -> None:
    msg = EmailMessage()
    msg["From"] = settings.smtp_from
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content(body)

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as server:
        server.starttls()
        if settings.smtp_user:
            server.login(settings.smtp_user, settings.smtp_password)
        server.send_message(msg)


def send_otp_email(to: str, code: str, purpose: str) -> None:
    """
    Envía un código OTP. purpose: 'password_reset' | 'email_verification'.
    Nunca lanza excepción hacia el endpoint (el fallo de email no debe
    revelar si el usuario existe ni romper el flujo).
    """
    if purpose == "password_reset":
        subject = "FinPareja — Código para restablecer tu contraseña"
        intro = "Usa este código para restablecer tu contraseña:"
    else:
        subject = "FinPareja — Verifica tu correo"
        intro = "Usa este código para verificar tu cuenta:"

    body = (
        f"{intro}\n\n"
        f"    {code}\n\n"
        "El código expira en 15 minutos. Si no solicitaste esto, ignora este correo."
    )

    if not settings.smtp_host:
        # Sin SMTP: registrar para dev. NO usar en producción real.
        logger.warning(
            "EMAIL no enviado (SMTP no configurado). to=%s purpose=%s code=%s",
            to, purpose, code,
        )
        return

    try:
        _send_smtp(to, subject, body)
        logger.info("OTP enviado a %s (%s)", to, purpose)
    except Exception:
        logger.exception("Fallo enviando OTP a %s (%s)", to, purpose)
