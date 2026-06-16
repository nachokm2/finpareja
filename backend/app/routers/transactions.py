import csv
import io

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from ..core.audit import record_audit
from ..dependencies import get_db, get_current_user, assert_couple_member
from ..models.user import User
from ..models.transaction import Transaction
from ..schemas.transaction import (
    TransactionCreate,
    TransactionUpdate,
    TransactionResponse,
    TransactionListResponse,
)

router = APIRouter()


@router.get("", response_model=TransactionListResponse)
async def list_transactions(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    tipo: str | None = Query(None),
    mes: int | None = Query(None),
    anio: int | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conditions = [Transaction.usuario_id == current_user.id]
    if tipo:
        conditions.append(Transaction.tipo == tipo)
    if mes:
        conditions.append(func.extract("month", Transaction.fecha) == mes)
    if anio:
        conditions.append(func.extract("year", Transaction.fecha) == anio)

    total = (await db.execute(
        select(func.count()).select_from(Transaction).where(and_(*conditions))
    )).scalar_one()

    items = (await db.execute(
        select(Transaction)
        .where(and_(*conditions))
        .order_by(Transaction.fecha.desc(), Transaction.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )).scalars().all()

    return TransactionListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get("/export")
async def export_transactions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Exporta todas las transacciones del usuario en CSV (UTF-8 con BOM para que
    Excel respete los acentos). Cumple el derecho de portabilidad de datos
    (Ley 19.628). Declarado antes de /{tx_id} para que el ruteo no lo confunda.
    """
    rows = (await db.execute(
        select(Transaction)
        .where(Transaction.usuario_id == current_user.id)
        .order_by(Transaction.fecha.asc(), Transaction.id.asc())
    )).scalars().all()

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow([
        "fecha", "tipo", "categoria", "monto", "moneda",
        "descripcion", "compartido", "porcentaje_usuario",
    ])
    for t in rows:
        writer.writerow([
            t.fecha.isoformat(),
            t.tipo,
            t.category.nombre if t.category else "",
            f"{t.monto}",
            t.moneda,
            t.descripcion or "",
            "si" if t.es_compartido else "no",
            f"{t.porcentaje_usuario}",
        ])

    content = "﻿" + buffer.getvalue()
    return Response(
        content=content,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="finpareja_transacciones.csv"'},
    )


@router.post("", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def create_transaction(
    body: TransactionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await assert_couple_member(db, current_user.id, body.pareja_id)
    tx = Transaction(
        usuario_id=current_user.id,
        **body.model_dump(),
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx


@router.get("/{tx_id}", response_model=TransactionResponse)
async def get_transaction(
    tx_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    tx = await db.get(Transaction, tx_id)
    if not tx or tx.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    return tx


@router.patch("/{tx_id}", response_model=TransactionResponse)
async def update_transaction(
    tx_id: int,
    body: TransactionUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    tx = await db.get(Transaction, tx_id)
    if not tx or tx.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(tx, field, value)
    await db.commit()
    await db.refresh(tx)
    return tx


@router.delete("/{tx_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_transaction(
    tx_id: int,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    tx = await db.get(Transaction, tx_id)
    if not tx or tx.usuario_id != current_user.id:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    await record_audit(
        db, accion="transaction.delete", usuario_id=current_user.id,
        entidad="transaccion", entidad_id=tx.id,
        detalle=f"tipo={tx.tipo} monto={tx.monto}", request=request,
    )
    await db.delete(tx)
    await db.commit()
