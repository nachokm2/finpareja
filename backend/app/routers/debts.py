from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..dependencies import get_db, get_current_user
from ..models.user import User
from ..models.debt import Debt, DebtPayment
from ..schemas.debt import DebtCreate, DebtUpdate, DebtResponse, PaymentCreate

router = APIRouter()


@router.get("", response_model=list[DebtResponse])
async def list_debts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    debts = (await db.execute(
        select(Debt).where(Debt.usuario_id == current_user.id).order_by(Debt.created_at.desc())
    )).scalars().all()
    return debts


@router.post("", response_model=DebtResponse, status_code=status.HTTP_201_CREATED)
async def create_debt(
    body: DebtCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    data = body.model_dump()
    monto_original = data.pop("monto_original")
    d = Debt(
        usuario_id=current_user.id,
        monto_original=monto_original,
        monto_pendiente=monto_original,
        **data,
    )
    db.add(d)
    await db.commit()
    await db.refresh(d)
    return d


@router.post("/{debt_id}/pagos", response_model=DebtResponse, status_code=status.HTTP_201_CREATED)
async def add_payment(
    debt_id: int,
    body: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    d = await db.get(Debt, debt_id)
    if not d or d.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Deuda no encontrada")

    db.add(DebtPayment(deuda_id=debt_id, monto=body.monto, fecha=body.fecha, nota=body.nota))
    d.monto_pendiente = max(d.monto_pendiente - body.monto, 0)
    if d.monto_pendiente == 0:
        d.estado = "pagada"
    await db.commit()
    await db.refresh(d)
    return d


@router.patch("/{debt_id}", response_model=DebtResponse)
async def update_debt(
    debt_id: int,
    body: DebtUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    d = await db.get(Debt, debt_id)
    if not d or d.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Deuda no encontrada")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(d, field, value)
    await db.commit()
    await db.refresh(d)
    return d


@router.delete("/{debt_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_debt(
    debt_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    d = await db.get(Debt, debt_id)
    if not d or d.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Deuda no encontrada")
    await db.delete(d)
    await db.commit()
