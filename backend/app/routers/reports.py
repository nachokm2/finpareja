from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from ..dependencies import get_db, get_current_user
from ..models.user import User
from ..models.transaction import Transaction
from ..models.category import Category

router = APIRouter()


@router.get("/resumen-mensual")
async def monthly_summary(
    anio: int = Query(...),
    mes: int = Query(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Totales de ingresos, gastos y balance neto del mes."""
    rows = (await db.execute(
        select(Transaction.tipo, func.coalesce(func.sum(Transaction.monto), Decimal("0")).label("total"))
        .where(
            Transaction.usuario_id == current_user.id,
            func.extract("year", Transaction.fecha) == anio,
            func.extract("month", Transaction.fecha) == mes,
        )
        .group_by(Transaction.tipo)
    )).all()

    ingresos = Decimal("0")
    gastos = Decimal("0")
    for tipo, total in rows:
        if tipo == "ingreso":
            ingresos = total
        else:
            gastos = total

    return {
        "anio": anio,
        "mes": mes,
        "ingresos": ingresos,
        "gastos": gastos,
        "balance": ingresos - gastos,
        "tasa_ahorro": round(float((ingresos - gastos) / ingresos * 100), 2) if ingresos > 0 else 0.0,
    }


@router.get("/por-categoria")
async def by_category(
    anio: int = Query(...),
    mes: int = Query(...),
    tipo: str = Query("gasto"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Desglose por categoría para el mes dado."""
    rows = (await db.execute(
        select(
            Category.id,
            Category.nombre,
            Category.icono,
            Category.color,
            func.coalesce(func.sum(Transaction.monto), Decimal("0")).label("total"),
        )
        .join(Transaction, Transaction.categoria_id == Category.id)
        .where(
            Transaction.usuario_id == current_user.id,
            Transaction.tipo == tipo,
            func.extract("year", Transaction.fecha) == anio,
            func.extract("month", Transaction.fecha) == mes,
        )
        .group_by(Category.id, Category.nombre, Category.icono, Category.color)
        .order_by(func.sum(Transaction.monto).desc())
    )).all()

    total_general = sum(r.total for r in rows)
    return {
        "anio": anio,
        "mes": mes,
        "tipo": tipo,
        "categorias": [
            {
                "id": r.id,
                "nombre": r.nombre,
                "icono": r.icono,
                "color": r.color,
                "total": r.total,
                "porcentaje": round(float(r.total / total_general * 100), 2) if total_general > 0 else 0.0,
            }
            for r in rows
        ],
    }


@router.get("/evolucion")
async def evolution(
    meses: int = Query(12, ge=1, le=24),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Serie temporal de ingresos y gastos (últimos N meses)."""
    rows = (await db.execute(
        select(
            func.extract("year", Transaction.fecha).label("anio"),
            func.extract("month", Transaction.fecha).label("mes"),
            Transaction.tipo,
            func.coalesce(func.sum(Transaction.monto), Decimal("0")).label("total"),
        )
        .where(Transaction.usuario_id == current_user.id)
        .group_by(
            func.extract("year", Transaction.fecha),
            func.extract("month", Transaction.fecha),
            Transaction.tipo,
        )
        .order_by(
            func.extract("year", Transaction.fecha).desc(),
            func.extract("month", Transaction.fecha).desc(),
        )
        .limit(meses * 2)
    )).all()

    data: dict = {}
    for anio, mes, tipo, total in rows:
        key = f"{int(anio)}-{int(mes):02d}"
        if key not in data:
            data[key] = {"periodo": key, "anio": int(anio), "mes": int(mes), "ingresos": Decimal("0"), "gastos": Decimal("0")}
        data[key]["ingresos" if tipo == "ingreso" else "gastos"] = total

    return {"meses": sorted(data.values(), key=lambda x: x["periodo"])}


@router.get("/patrimonio")
async def net_worth(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Patrimonio neto acumulado del usuario."""
    rows = (await db.execute(
        select(Transaction.tipo, func.coalesce(func.sum(Transaction.monto), Decimal("0")).label("total"))
        .where(Transaction.usuario_id == current_user.id)
        .group_by(Transaction.tipo)
    )).all()

    ingresos = Decimal("0")
    gastos = Decimal("0")
    for tipo, total in rows:
        if tipo == "ingreso":
            ingresos = total
        else:
            gastos = total

    return {
        "ingresos_acumulados": ingresos,
        "gastos_acumulados": gastos,
        "patrimonio_neto": ingresos - gastos,
    }
