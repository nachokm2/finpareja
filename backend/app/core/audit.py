"""
Helper para registrar eventos en el audit log inmutable.

La entrada se agrega a la sesión actual; el commit lo hace el endpoint llamador
(así el registro de auditoría participa de la misma transacción que la acción).
"""
from __future__ import annotations

from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.audit_log import AuditLog
from .observability import request_id_ctx


def _client_ip(request: Request | None) -> str | None:
    if request is None:
        return None
    fwd = request.headers.get("x-forwarded-for")
    if fwd:
        return fwd.split(",")[0].strip()
    return request.client.host if request.client else None


async def record_audit(
    db: AsyncSession,
    *,
    accion: str,
    usuario_id: int | None = None,
    entidad: str | None = None,
    entidad_id: int | None = None,
    detalle: str | None = None,
    request: Request | None = None,
) -> None:
    """Agrega una entrada de auditoría a la sesión (no hace commit)."""
    db.add(AuditLog(
        usuario_id=usuario_id,
        accion=accion,
        entidad=entidad,
        entidad_id=entidad_id,
        detalle=detalle,
        ip=_client_ip(request),
        request_id=request_id_ctx.get(),
    ))
