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
from ..models.settlement import Settlement
from ..schemas.couple import (
    CoupleCreate, CoupleResponse, InviteRequest, AcceptInviteRequest,
    SettleRequest, SettlementResponse,
)

router = APIRouter()


async def _get_membership(db: AsyncSession, user_id: int) -> CoupleMember:
    """Devuelve la membresía de pareja del usuario o lanza 404."""
    m = (await db.execute(
        select(CoupleMember).where(CoupleMember.usuario_id == user_id)
    )).scalar_one_or_none()
    if m is None:
        raise HTTPException(status_code=404, detail="No perteneces a ninguna pareja")
    return m


async def _partner_id(db: AsyncSession, pareja_id: int, user_id: int) -> int | None:
    """ID del otro miembro de la pareja (None si todavía no se unió nadie)."""
    rows = (await db.execute(
        select(CoupleMember.usuario_id).where(
            CoupleMember.pareja_id == pareja_id,
            CoupleMember.usuario_id != user_id,
        )
    )).scalars().all()
    return rows[0] if rows else None


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


async def _shared_owed_to(db: AsyncSession, pareja_id: int, payer_id: int, other_id: int) -> Decimal:
    """
    Cuánto le debe [other_id] a [payer_id] por gastos compartidos que pagó
    [payer_id]. Cada gasto compartido lo paga quien lo registró por el monto
    total; la parte que NO le corresponde (100 - porcentaje_usuario) es lo
    que le debe el otro.
    """
    rows = (await db.execute(
        select(Transaction.monto, Transaction.porcentaje_usuario).where(
            Transaction.usuario_id == payer_id,
            Transaction.pareja_id == pareja_id,
            Transaction.es_compartido == True,  # noqa: E712
            Transaction.tipo == "gasto",
        )
    )).all()
    total = Decimal("0")
    for monto, pct in rows:
        parte_otro = monto * (Decimal("100") - pct) / Decimal("100")
        total += parte_otro
    return total


async def _settlements_sum(db: AsyncSession, pagador_id: int, receptor_id: int) -> Decimal:
    total = (await db.execute(
        select(func.coalesce(func.sum(Settlement.monto), Decimal("0"))).where(
            Settlement.pagador_id == pagador_id,
            Settlement.receptor_id == receptor_id,
        )
    )).scalar_one()
    return Decimal(str(total))


@router.get("/balance")
async def couple_balance(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Balance neto de gastos compartidos entre los dos miembros.

    balance > 0  → la pareja te debe (tú pagaste de más)
    balance < 0  → tú le debes a la pareja
    balance == 0 → están a mano

    Cálculo:
      lo que el otro me debe  = gastos compartidos que YO pagué × parte del otro
      lo que yo le debo       = gastos compartidos que el OTRO pagó × mi parte
      neto bruto = (me debe) - (le debo)
      ajuste por liquidaciones: + lo que YO ya le pagué, - lo que ÉL ya me pagó
    """
    membership = await _get_membership(db, current_user.id)
    pareja_id = membership.pareja_id
    other_id = await _partner_id(db, pareja_id, current_user.id)

    if other_id is None:
        return {
            "pareja_id": pareja_id,
            "balance": Decimal("0"),
            "te_deben": Decimal("0"),
            "debes": Decimal("0"),
            "tiene_pareja_completa": False,
        }

    me_debe = await _shared_owed_to(db, pareja_id, current_user.id, other_id)
    le_debo = await _shared_owed_to(db, pareja_id, other_id, current_user.id)

    # Liquidaciones: lo que yo ya pagué reduce lo que debo; lo que él me pagó
    # reduce lo que me deben.
    yo_pague = await _settlements_sum(db, current_user.id, other_id)
    el_pago = await _settlements_sum(db, other_id, current_user.id)

    te_deben = me_debe - el_pago
    debes = le_debo - yo_pague
    balance = te_deben - debes

    return {
        "pareja_id": pareja_id,
        "balance": balance,
        "te_deben": te_deben if te_deben > 0 else Decimal("0"),
        "debes": debes if debes > 0 else Decimal("0"),
        "tiene_pareja_completa": True,
    }


@router.post("/liquidar", response_model=SettlementResponse, status_code=status.HTTP_201_CREATED)
async def settle(
    body: SettleRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Registra un pago del usuario actual al otro miembro para saldar deuda."""
    if body.monto <= 0:
        raise HTTPException(status_code=400, detail="El monto debe ser mayor a 0")

    membership = await _get_membership(db, current_user.id)
    other_id = await _partner_id(db, membership.pareja_id, current_user.id)
    if other_id is None:
        raise HTTPException(status_code=400, detail="Tu pareja aún no tiene un segundo miembro")

    settlement = Settlement(
        pareja_id=membership.pareja_id,
        pagador_id=current_user.id,
        receptor_id=other_id,
        monto=body.monto,
        nota=body.nota,
        fecha=body.fecha,
    )
    db.add(settlement)
    await db.commit()
    await db.refresh(settlement)
    return settlement


@router.get("/liquidaciones", response_model=list[SettlementResponse])
async def list_settlements(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Historial de liquidaciones de la pareja (ambas direcciones)."""
    membership = await _get_membership(db, current_user.id)
    rows = (await db.execute(
        select(Settlement)
        .where(Settlement.pareja_id == membership.pareja_id)
        .order_by(Settlement.fecha.desc(), Settlement.id.desc())
    )).scalars().all()
    return rows
