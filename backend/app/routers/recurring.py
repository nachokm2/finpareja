import calendar
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..dependencies import get_db, get_current_user, assert_couple_member
from ..models.user import User
from ..models.recurring_transaction import RecurringTransaction
from ..models.transaction import Transaction
from ..schemas.recurring import RecurringCreate, RecurringUpdate, RecurringResponse

router = APIRouter()


def _advance(d: date, frecuencia: str) -> date:
    """Devuelve la siguiente fecha de generación según la frecuencia."""
    if frecuencia == "semanal":
        return d + timedelta(days=7)
    # mensual: suma un mes ajustando el día al último válido del mes destino.
    month = d.month + 1
    year = d.year + (month - 1) // 12
    month = (month - 1) % 12 + 1
    last_day = calendar.monthrange(year, month)[1]
    return date(year, month, min(d.day, last_day))


async def materialize_due(db: AsyncSession, user_id: int, today: date) -> int:
    """
    Genera las transacciones pendientes de todas las plantillas activas del
    usuario cuya proxima_fecha ya llegó, avanzando la fecha tras cada una.
    Devuelve cuántas transacciones se crearon. Idempotente respecto a 'today':
    correrla dos veces el mismo día no duplica nada.
    """
    recs = (await db.execute(
        select(RecurringTransaction).where(
            RecurringTransaction.usuario_id == user_id,
            RecurringTransaction.activo == True,  # noqa: E712
            RecurringTransaction.proxima_fecha <= today,
        )
    )).scalars().all()

    created = 0
    for r in recs:
        guard = 0  # tope de seguridad ante plantillas muy atrasadas
        while r.proxima_fecha <= today and guard < 366:
            db.add(Transaction(
                usuario_id=r.usuario_id,
                pareja_id=r.pareja_id,
                categoria_id=r.categoria_id,
                tipo=r.tipo,
                monto=r.monto,
                descripcion=r.descripcion,
                fecha=r.proxima_fecha,
                es_compartido=r.es_compartido,
                porcentaje_usuario=r.porcentaje_usuario,
                recurrente=True,
                frecuencia=r.frecuencia,
            ))
            r.proxima_fecha = _advance(r.proxima_fecha, r.frecuencia)
            created += 1
            guard += 1
    if created:
        await db.commit()
    return created


@router.get("", response_model=list[RecurringResponse])
async def list_recurring(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.execute(
        select(RecurringTransaction)
        .where(RecurringTransaction.usuario_id == current_user.id)
        .order_by(RecurringTransaction.proxima_fecha.asc())
    )).scalars().all()
    return rows


@router.post("", response_model=RecurringResponse, status_code=status.HTTP_201_CREATED)
async def create_recurring(
    body: RecurringCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await assert_couple_member(db, current_user.id, body.pareja_id)
    rec = RecurringTransaction(usuario_id=current_user.id, **body.model_dump())
    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    return rec


@router.patch("/{rec_id}", response_model=RecurringResponse)
async def update_recurring(
    rec_id: int,
    body: RecurringUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rec = await db.get(RecurringTransaction, rec_id)
    if not rec or rec.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Recurrente no encontrada")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(rec, field, value)
    await db.commit()
    await db.refresh(rec)
    return rec


@router.delete("/{rec_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recurring(
    rec_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rec = await db.get(RecurringTransaction, rec_id)
    if not rec or rec.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Recurrente no encontrada")
    await db.delete(rec)
    await db.commit()


@router.post("/procesar")
async def process_recurring(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Genera las transacciones recurrentes vencidas del usuario hasta hoy."""
    created = await materialize_due(db, current_user.id, date.today())
    return {"creadas": created}
