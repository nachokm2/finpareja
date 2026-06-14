from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from ..dependencies import get_db, get_current_user, assert_couple_member
from ..models.user import User
from ..models.budget import Budget
from ..models.transaction import Transaction
from ..schemas.budget import BudgetCreate, BudgetUpdate, BudgetResponse, BudgetWithUsage

router = APIRouter()


@router.get("", response_model=list[BudgetWithUsage])
async def list_budgets(
    mes: int | None = Query(None),
    anio: int | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    budgets = (await db.execute(
        select(Budget).where(Budget.usuario_id == current_user.id)
    )).scalars().all()

    result = []
    for b in budgets:
        conds = [Transaction.usuario_id == current_user.id, Transaction.tipo == "gasto"]
        if b.categoria_id:
            conds.append(Transaction.categoria_id == b.categoria_id)
        if mes:
            conds.append(func.extract("month", Transaction.fecha) == mes)
        if anio:
            conds.append(func.extract("year", Transaction.fecha) == anio)

        spent = Decimal(str((await db.execute(
            select(func.coalesce(func.sum(Transaction.monto), 0)).where(and_(*conds))
        )).scalar_one()))

        pct = float(spent / b.monto_limite * 100) if b.monto_limite > 0 else 0.0
        result.append(BudgetWithUsage(
            id=b.id, usuario_id=b.usuario_id, categoria_id=b.categoria_id,
            monto_limite=b.monto_limite, periodo=b.periodo, mes=b.mes, anio=b.anio,
            alerta_porcentaje=b.alerta_porcentaje,
            monto_gastado=spent, porcentaje_usado=round(pct, 2),
            alerta_activa=pct >= float(b.alerta_porcentaje),
        ))
    return result


@router.post("", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
async def create_budget(
    body: BudgetCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await assert_couple_member(db, current_user.id, body.pareja_id)
    b = Budget(usuario_id=current_user.id, **body.model_dump())
    db.add(b)
    await db.commit()
    await db.refresh(b)
    return b


@router.patch("/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    budget_id: int,
    body: BudgetUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    b = await db.get(Budget, budget_id)
    if not b or b.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Presupuesto no encontrado")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(b, field, value)
    await db.commit()
    await db.refresh(b)
    return b


@router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_budget(
    budget_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    b = await db.get(Budget, budget_id)
    if not b or b.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Presupuesto no encontrado")
    await db.delete(b)
    await db.commit()
