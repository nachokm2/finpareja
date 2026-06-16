"""
Observabilidad: logging estructurado, correlación de requests y Sentry.

- Logging JSON a stdout (Railway lo indexa). En desarrollo se puede usar
  formato legible (LOG_JSON=false).
- Cada request recibe un X-Request-ID que se propaga al cliente y se inyecta
  en cada línea de log, para poder rastrear una petición de punta a punta.
- Sentry es opt-in: solo se inicializa si SENTRY_DSN está configurado y el
  paquete sentry-sdk está instalado (no es obligatorio para desarrollo).
"""
from __future__ import annotations

import json
import logging
import sys
import time
import uuid
from contextvars import ContextVar

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

# ID de la request en curso, accesible desde cualquier punto del código async.
request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")


class RequestIdFilter(logging.Filter):
    """Inyecta el request_id del contexto en cada LogRecord."""

    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_ctx.get()
        return True


class JsonFormatter(logging.Formatter):
    """Formatea cada log como una línea JSON (un objeto por línea)."""

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
            "request_id": getattr(record, "request_id", "-"),
        }
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def configure_logging(level: str = "INFO", json_logs: bool = True) -> None:
    """Configura el logging raíz. Idempotente (reemplaza handlers previos)."""
    handler = logging.StreamHandler(sys.stdout)
    handler.addFilter(RequestIdFilter())
    if json_logs:
        handler.setFormatter(JsonFormatter())
    else:
        handler.setFormatter(
            logging.Formatter(
                "%(asctime)s %(levelname)s [%(request_id)s] %(name)s: %(message)s"
            )
        )

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level.upper())

    # Uvicorn duplica logs con sus propios handlers; los dejamos propagar al raíz.
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        lg = logging.getLogger(name)
        lg.handlers.clear()
        lg.propagate = True


class RequestContextMiddleware(BaseHTTPMiddleware):
    """Asigna/propaga X-Request-ID y registra una línea de acceso por request."""

    async def dispatch(self, request: Request, call_next):
        rid = request.headers.get("X-Request-ID") or uuid.uuid4().hex[:16]
        token = request_id_ctx.set(rid)
        start = time.perf_counter()
        try:
            response = await call_next(request)
            elapsed_ms = round((time.perf_counter() - start) * 1000, 1)
            response.headers["X-Request-ID"] = rid
            logging.getLogger("finpareja.access").info(
                "%s %s -> %s (%sms)",
                request.method,
                request.url.path,
                response.status_code,
                elapsed_ms,
            )
            return response
        finally:
            request_id_ctx.reset(token)


def init_sentry(dsn: str, environment: str, release: str | None = None) -> bool:
    """
    Inicializa Sentry si hay DSN y el paquete está disponible.
    Devuelve True si se activó. No falla si sentry-sdk no está instalado.
    """
    if not dsn:
        return False
    try:
        import sentry_sdk
    except ImportError:
        logging.getLogger("finpareja").warning(
            "SENTRY_DSN configurado pero sentry-sdk no está instalado; Sentry desactivado."
        )
        return False

    sentry_sdk.init(
        dsn=dsn,
        environment=environment,
        release=release,
        traces_sample_rate=0.1,
        # No enviar PII por defecto (cumplimiento Ley 19.628 / privacidad).
        send_default_pii=False,
    )
    return True
