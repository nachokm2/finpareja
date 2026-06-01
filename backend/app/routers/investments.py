from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..dependencies import get_db, get_current_user
from ..models.user import User
from ..models.investment import Investment
from ..schemas.investment import InvestmentCreate, InvestmentUpdate, InvestmentResponse

router = APIRouter()


def _response(inv: Investment) -> InvestmentResponse:
    valor_actual = None
    ganancia = None
    if inv.cantidad and inv.precio_actual:
        valor_actual = inv.cantidad * inv.precio_actual
        if inv.precio_compra:
            ganancia = valor_actual - (inv.cantidad * inv.precio_compra)
    return InvestmentResponse(
        id=inv.id, usuario_id=inv.usuario_id,
        nombre=inv.nombre, tipo=inv.tipo, simbolo=inv.simbolo,
        cantidad=inv.cantidad, precio_compra=inv.precio_compra,
        precio_actual=inv.precio_actual, moneda=inv.moneda,
        fecha_compra=inv.fecha_compra, notas=inv.notas,
        valor_actual=valor_actual, ganancia_perdida=ganancia,
        created_at=inv.created_at,
    )


@router.get("", response_model=list[InvestmentResponse])
async def list_investments(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    items = (await db.execute(
        select(Investment).where(Investment.usuario_id == current_user.id)
    )).scalars().all()
    return [_response(i) for i in items]


@router.post("", response_model=InvestmentResponse, status_code=status.HTTP_201_CREATED)
async def create_investment(
    body: InvestmentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    inv = Investment(usuario_id=current_user.id, **body.model_dump())
    db.add(inv)
    await db.commit()
    await db.refresh(inv)
    return _response(inv)


@router.patch("/{inv_id}", response_model=InvestmentResponse)
async def update_investment(
    inv_id: int,
    body: InvestmentUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    inv = await db.get(Investment, inv_id)
    if not inv or inv.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Inversión no encontrada")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(inv, field, value)
    await db.commit()
    await db.refresh(inv)
    return _response(inv)


@router.delete("/{inv_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_investment(
    inv_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    inv = await db.get(Investment, inv_id)
    if not inv or inv.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Inversión no encontrada")
    await db.delete(inv)
    await db.commit()
