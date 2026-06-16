from datetime import date
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


async def _spent_for_budget(
    db: AsyncSession,
    budget: Budget,
    usuario_id: int,
    mes: int | None,
    anio: int | None,
) -> Decimal:
    """Suma de gastos del usuario que cuentan contra un presupuesto en el periodo."""
    conds = [Transaction.usuario_id == usuario_id, Transaction.tipo == "gasto"]
    if budget.categoria_id:
        conds.append(Transaction.categoria_id == budget.categoria_id)
    if mes:
        conds.append(func.extract("month", Transaction.fecha) == mes)
    if anio:
        conds.append(func.extract("year", Transaction.fecha) == anio)
    return Decimal(str((await db.execute(
        select(func.coalesce(func.sum(Transaction.monto), 0)).where(and_(*conds))
    )).scalar_one()))


def _with_usage(budget: Budget, spent: Decimal) -> BudgetWithUsage:
    pct = float(spent / budget.monto_limite * 100) if budget.monto_limite > 0 else 0.0
    return BudgetWithUsage(
        id=budget.id, usuario_id=budget.usuario_id, categoria_id=budget.categoria_id,
        monto_limite=budget.monto_limite, periodo=budget.periodo,
        mes=budget.mes, anio=budget.anio, alerta_porcentaje=budget.alerta_porcentaje,
        monto_gastado=spent, porcentaje_usado=round(pct, 2),
        alerta_activa=pct >= float(budget.alerta_porcentaje),
    )


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
        spent = await _spent_for_budget(db, b, current_user.id, mes, anio)
        result.append(_with_usage(b, spent))
    return result


@router.get("/alertas", response_model=list[BudgetWithUsage])
async def budget_alerts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Presupuestos que alcanzaron o superaron su umbral de alerta en el periodo
    vigente. Es la base de las notificaciones de presupuesto (FIN-04): el
    cliente lo consulta tras crear un gasto y muestra un aviso si hay alertas.

    Cada presupuesto se evalúa en su propio periodo: si tiene mes/año fijos se
    usan esos; si no, el mes y año actuales.
    """
    today = date.today()
    budgets = (await db.execute(
        select(Budget).where(Budget.usuario_id == current_user.id)
    )).scalars().all()
    alerts = []
    for b in budgets:
        mes = b.mes or today.month
        anio = b.anio or today.year
        spent = await _spent_for_budget(db, b, current_user.id, mes, anio)
        usage = _with_usage(b, spent)
        if usage.alerta_activa:
            alerts.append(usage)
    return alerts


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
