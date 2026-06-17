from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from ..dependencies import get_db, get_current_user
from ..models.user import User
from ..models.credit_card import CreditCard, CardPurchase, CardPayment
from ..schemas.card import (
    CardCreate, CardResponse, CardSummary,
    PurchaseCreate, PurchaseResponse,
    PaymentCreate, PaymentResponse,
)

router = APIRouter()


def purchase_owed(p: CardPurchase) -> Decimal:
    """Deuda que aporta una compra (con intereses si es en cuotas)."""
    if p.cuotas and p.cuotas > 1:
        if p.valor_cuota is not None:
            return p.valor_cuota * p.cuotas
        return p.monto
    return p.monto


async def _get_owned_card(db: AsyncSession, card_id: int, user_id: int) -> CreditCard:
    card = await db.get(CreditCard, card_id)
    if card is None or card.usuario_id != user_id:
        raise HTTPException(status_code=404, detail="Tarjeta no encontrada")
    return card


async def _totals(db: AsyncSession, card_id: int) -> tuple[Decimal, Decimal]:
    """Devuelve (total_compras_con_interes, total_pagado) de una tarjeta."""
    purchases = (await db.execute(
        select(CardPurchase).where(CardPurchase.tarjeta_id == card_id)
    )).scalars().all()
    total_compras = sum((purchase_owed(p) for p in purchases), Decimal("0"))
    total_pagado = (await db.execute(
        select(func.coalesce(func.sum(CardPayment.monto), 0)).where(
            CardPayment.tarjeta_id == card_id
        )
    )).scalar_one()
    return total_compras, Decimal(str(total_pagado))


def _summary(card: CreditCard, total_compras: Decimal, total_pagado: Decimal) -> CardSummary:
    saldo = total_compras - total_pagado
    return CardSummary(
        id=card.id, usuario_id=card.usuario_id, nombre=card.nombre,
        emisor=card.emisor, ultimos_digitos=card.ultimos_digitos,
        cupo=card.cupo, color=card.color,
        saldo_pendiente=saldo, total_compras=total_compras, total_pagado=total_pagado,
        cupo_disponible=(card.cupo - saldo) if card.cupo is not None else None,
    )


# ── Tarjetas ─────────────────────────────────────────────────────────────────
@router.post("", response_model=CardResponse, status_code=status.HTTP_201_CREATED)
async def create_card(
    body: CardCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    card = CreditCard(usuario_id=current_user.id, **body.model_dump())
    db.add(card)
    await db.commit()
    await db.refresh(card)
    return card


@router.get("", response_model=list[CardSummary])
async def list_cards(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cards = (await db.execute(
        select(CreditCard).where(CreditCard.usuario_id == current_user.id)
        .order_by(CreditCard.created_at.asc())
    )).scalars().all()
    result = []
    for card in cards:
        tc, tp = await _totals(db, card.id)
        result.append(_summary(card, tc, tp))
    return result


@router.get("/{card_id}", response_model=CardSummary)
async def get_card(
    card_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    card = await _get_owned_card(db, card_id, current_user.id)
    tc, tp = await _totals(db, card.id)
    return _summary(card, tc, tp)


@router.delete("/{card_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_card(
    card_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    card = await _get_owned_card(db, card_id, current_user.id)
    await db.delete(card)
    await db.commit()


# ── Compras ──────────────────────────────────────────────────────────────────
def _to_purchase_response(p: CardPurchase) -> PurchaseResponse:
    return PurchaseResponse(
        id=p.id, tarjeta_id=p.tarjeta_id, descripcion=p.descripcion,
        monto=p.monto, fecha=p.fecha, categoria_id=p.categoria_id,
        cuotas=p.cuotas, valor_cuota=p.valor_cuota, interes=p.interes,
        deuda=purchase_owed(p),
    )


@router.post("/{card_id}/compras", response_model=PurchaseResponse, status_code=status.HTTP_201_CREATED)
async def add_purchase(
    card_id: int,
    body: PurchaseCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_card(db, card_id, current_user.id)

    cuotas = body.cuotas
    valor_cuota = body.valor_cuota
    interes = body.interes
    if cuotas > 1:
        # Si no dan el valor de cuota, se reparte el monto sin interés.
        if valor_cuota is None:
            valor_cuota = (body.monto / cuotas).quantize(Decimal("0.01"))
            interes = interes if interes is not None else Decimal("0")
        else:
            total = valor_cuota * cuotas
            interes = interes if interes is not None else (total - body.monto)
    else:
        cuotas = 1
        valor_cuota = None
        interes = None

    purchase = CardPurchase(
        tarjeta_id=card_id, usuario_id=current_user.id,
        descripcion=body.descripcion, monto=body.monto, fecha=body.fecha,
        categoria_id=body.categoria_id, cuotas=cuotas,
        valor_cuota=valor_cuota, interes=interes,
    )
    db.add(purchase)
    await db.commit()
    await db.refresh(purchase)
    return _to_purchase_response(purchase)


@router.get("/{card_id}/compras", response_model=list[PurchaseResponse])
async def list_purchases(
    card_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_card(db, card_id, current_user.id)
    rows = (await db.execute(
        select(CardPurchase).where(CardPurchase.tarjeta_id == card_id)
        .order_by(CardPurchase.fecha.desc(), CardPurchase.id.desc())
    )).scalars().all()
    return [_to_purchase_response(p) for p in rows]


@router.delete("/{card_id}/compras/{purchase_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_purchase(
    card_id: int,
    purchase_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_card(db, card_id, current_user.id)
    p = await db.get(CardPurchase, purchase_id)
    if p is None or p.tarjeta_id != card_id:
        raise HTTPException(status_code=404, detail="Compra no encontrada")
    await db.delete(p)
    await db.commit()


# ── Pagos ────────────────────────────────────────────────────────────────────
@router.post("/{card_id}/pagos", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
async def add_payment(
    card_id: int,
    body: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_card(db, card_id, current_user.id)
    payment = CardPayment(
        tarjeta_id=card_id, usuario_id=current_user.id,
        monto=body.monto, fecha=body.fecha, nota=body.nota,
    )
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return payment


@router.get("/{card_id}/pagos", response_model=list[PaymentResponse])
async def list_payments(
    card_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_card(db, card_id, current_user.id)
    rows = (await db.execute(
        select(CardPayment).where(CardPayment.tarjeta_id == card_id)
        .order_by(CardPayment.fecha.desc(), CardPayment.id.desc())
    )).scalars().all()
    return rows
