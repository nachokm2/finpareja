from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..dependencies import get_db, get_current_user
from ..models.user import User
from ..models.saving_goal import SavingGoal, SavingGoalContribution
from ..schemas.saving_goal import (
    SavingGoalCreate, SavingGoalUpdate, SavingGoalResponse,
    ContributionCreate,
)

router = APIRouter()


def _response(g: SavingGoal) -> SavingGoalResponse:
    pct = float(g.monto_actual / g.monto_objetivo * 100) if g.monto_objetivo > 0 else 0.0
    return SavingGoalResponse(
        id=g.id, usuario_id=g.usuario_id, pareja_id=g.pareja_id,
        nombre=g.nombre, descripcion=g.descripcion,
        monto_objetivo=g.monto_objetivo, monto_actual=g.monto_actual,
        moneda=g.moneda, fecha_objetivo=g.fecha_objetivo,
        icono=g.icono, color=g.color, estado=g.estado,
        progreso_porcentaje=round(pct, 2),
        created_at=g.created_at,
    )


@router.get("", response_model=list[SavingGoalResponse])
async def list_goals(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    goals = (await db.execute(
        select(SavingGoal).where(SavingGoal.usuario_id == current_user.id)
        .order_by(SavingGoal.created_at.desc())
    )).scalars().all()
    return [_response(g) for g in goals]


@router.post("", response_model=SavingGoalResponse, status_code=status.HTTP_201_CREATED)
async def create_goal(
    body: SavingGoalCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    g = SavingGoal(usuario_id=current_user.id, **body.model_dump())
    db.add(g)
    await db.commit()
    await db.refresh(g)
    return _response(g)


@router.post("/{goal_id}/aportes", response_model=SavingGoalResponse, status_code=status.HTTP_201_CREATED)
async def add_contribution(
    goal_id: int,
    body: ContributionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    g = await db.get(SavingGoal, goal_id)
    if not g or g.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Meta no encontrada")

    db.add(SavingGoalContribution(
        meta_id=goal_id, usuario_id=current_user.id,
        monto=body.monto, nota=body.nota, fecha=body.fecha,
    ))
    g.monto_actual = g.monto_actual + body.monto
    if g.monto_actual >= g.monto_objetivo:
        g.estado = "completada"
    await db.commit()
    await db.refresh(g)
    return _response(g)


@router.patch("/{goal_id}", response_model=SavingGoalResponse)
async def update_goal(
    goal_id: int,
    body: SavingGoalUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    g = await db.get(SavingGoal, goal_id)
    if not g or g.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Meta no encontrada")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(g, field, value)
    await db.commit()
    await db.refresh(g)
    return _response(g)


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(
    goal_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    g = await db.get(SavingGoal, goal_id)
    if not g or g.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Meta no encontrada")
    await db.delete(g)
    await db.commit()
