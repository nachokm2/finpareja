from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_

from ..dependencies import get_db, get_current_user, assert_couple_member
from ..models.user import User
from ..models.category import Category
from ..schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse

router = APIRouter()


@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Category)
        .where(or_(Category.usuario_id == current_user.id, Category.es_sistema == True))
        .order_by(Category.tipo, Category.nombre)
    )
    return result.scalars().all()


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    body: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await assert_couple_member(db, current_user.id, body.pareja_id)
    cat = Category(
        usuario_id=None if body.pareja_id else current_user.id,
        pareja_id=body.pareja_id,
        nombre=body.nombre,
        icono=body.icono,
        color=body.color,
        tipo=body.tipo,
    )
    db.add(cat)
    await db.commit()
    await db.refresh(cat)
    return cat


@router.patch("/{cat_id}", response_model=CategoryResponse)
async def update_category(
    cat_id: int,
    body: CategoryUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cat = await db.get(Category, cat_id)
    if not cat or cat.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(cat, field, value)
    await db.commit()
    await db.refresh(cat)
    return cat


@router.delete("/{cat_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    cat_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cat = await db.get(Category, cat_id)
    if not cat or cat.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    await db.delete(cat)
    await db.commit()
