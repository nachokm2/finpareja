import secrets
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from ..dependencies import get_db, get_current_user
from ..models.user import User
from ..models.couple import Couple, CoupleMember, CoupleInvitation
from ..models.transaction import Transaction
from ..schemas.couple import CoupleCreate, CoupleResponse, InviteRequest, AcceptInviteRequest

router = APIRouter()


async def _net_worth_for(db: AsyncSession, usuario_id: int) -> tuple[Decimal, Decimal]:
    """Devuelve (ingresos_acumulados, gastos_acumulados) de un usuario."""
    rows = (await db.execute(
        select(Transaction.tipo, func.coalesce(func.sum(Transaction.monto), Decimal("0")).label("total"))
        .where(Transaction.usuario_id == usuario_id)
        .group_by(Transaction.tipo)
    )).all()
    ingresos = Decimal("0")
    gastos = Decimal("0")
    for tipo, total in rows:
        if tipo == "ingreso":
            ingresos = total
        else:
            gastos = total
    return ingresos, gastos


def _to_response(couple: Couple, member_count: int) -> CoupleResponse:
    return CoupleResponse(
        id=couple.id,
        nombre=couple.nombre,
        currency=couple.currency,
        created_at=couple.created_at,
        member_count=member_count,
    )


@router.post("", response_model=CoupleResponse, status_code=status.HTTP_201_CREATED)
async def create_couple(
    body: CoupleCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(select(CoupleMember).where(CoupleMember.usuario_id == current_user.id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Ya perteneces a una pareja")

    couple = Couple(nombre=body.nombre)
    db.add(couple)
    await db.flush()
    db.add(CoupleMember(pareja_id=couple.id, usuario_id=current_user.id, rol="admin"))
    await db.commit()
    await db.refresh(couple)
    return _to_response(couple, 1)


@router.get("/me", response_model=CoupleResponse)
async def get_my_couple(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    m = (await db.execute(select(CoupleMember).where(CoupleMember.usuario_id == current_user.id))).scalar_one_or_none()
    if m is None:
        raise HTTPException(status_code=404, detail="No perteneces a ninguna pareja")
    couple = await db.get(Couple, m.pareja_id)
    count = len((await db.execute(select(CoupleMember).where(CoupleMember.pareja_id == couple.id))).scalars().all())
    return _to_response(couple, count)


@router.post("/invite", status_code=status.HTTP_201_CREATED)
async def invite_partner(
    body: InviteRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    m = (await db.execute(select(CoupleMember).where(CoupleMember.usuario_id == current_user.id))).scalar_one_or_none()
    if m is None:
        raise HTTPException(status_code=400, detail="Primero debes crear una pareja")
    token = secrets.token_urlsafe(32)
    db.add(CoupleInvitation(
        pareja_id=m.pareja_id,
        invitado_por=current_user.id,
        email_invitado=body.email.lower(),
        token=token,
        expires_at=datetime.now(timezone.utc) + timedelta(days=7),
    ))
    await db.commit()
    return {"message": "Invitación creada", "token": token}


@router.post("/accept")
async def accept_invitation(
    body: AcceptInviteRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    now = datetime.now(timezone.utc)
    inv = (await db.execute(
        select(CoupleInvitation).where(
            CoupleInvitation.token == body.token,
            CoupleInvitation.estado == "pending",
            CoupleInvitation.expires_at > now,
        )
    )).scalar_one_or_none()
    if inv is None:
        raise HTTPException(status_code=400, detail="Invitación inválida o expirada")
    db.add(CoupleMember(pareja_id=inv.pareja_id, usuario_id=current_user.id, rol="member"))
    inv.estado = "accepted"
    await db.commit()
    return {"message": "Te uniste a la pareja exitosamente"}


@router.get("/resumen")
async def couple_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Patrimonio combinado de la pareja desglosado por miembro.
    Consolida los datos reales de cada usuario (no fabrica nada en el cliente).
    """
    membership = (await db.execute(
        select(CoupleMember).where(CoupleMember.usuario_id == current_user.id)
    )).scalar_one_or_none()
    if membership is None:
        raise HTTPException(status_code=404, detail="No perteneces a ninguna pareja")

    members = (await db.execute(
        select(CoupleMember).where(CoupleMember.pareja_id == membership.pareja_id)
    )).scalars().all()

    miembros_data = []
    patrimonio_total = Decimal("0")
    for m in members:
        user = await db.get(User, m.usuario_id)
        ingresos, gastos = await _net_worth_for(db, m.usuario_id)
        patrimonio = ingresos - gastos
        patrimonio_total += patrimonio
        miembros_data.append({
            "usuario_id": m.usuario_id,
            "nombre": user.full_name if user else "Usuario",
            "rol": m.rol,
            "ingresos": ingresos,
            "gastos": gastos,
            "patrimonio": patrimonio,
        })

    # Porcentaje de aporte de cada miembro al patrimonio combinado
    for md in miembros_data:
        md["porcentaje"] = (
            round(float(md["patrimonio"] / patrimonio_total * 100), 2)
            if patrimonio_total > 0 else 0.0
        )

    return {
        "pareja_id": membership.pareja_id,
        "patrimonio_combinado": patrimonio_total,
        "miembros": miembros_data,
    }
