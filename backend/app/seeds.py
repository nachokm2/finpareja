"""
Seed de categorías del sistema.

Se ejecuta automáticamente en cada deploy desde start.sh.
Es idempotente: si las categorías ya existen no hace nada.
"""
import asyncio
from sqlalchemy import select
from .database import AsyncSessionLocal
from .models.category import Category

# Categorías predefinidas en español para el mercado chileno.
# icono = emoji mostrado en la app móvil.
# color = hex para el chip/icono en la UI.
SYSTEM_CATEGORIES: list[dict] = [
    # ── Gastos ────────────────────────────────────────────────────────────────
    {"nombre": "Alimentación",      "icono": "🛒", "color": "#FF6B6B", "tipo": "gasto"},
    {"nombre": "Restaurantes",      "icono": "🍽️", "color": "#FDCB6E", "tipo": "gasto"},
    {"nombre": "Transporte",        "icono": "🚗", "color": "#4ECDC4", "tipo": "gasto"},
    {"nombre": "Vivienda",          "icono": "🏠", "color": "#45B7D1", "tipo": "gasto"},
    {"nombre": "Servicios básicos", "icono": "💡", "color": "#A29BFE", "tipo": "gasto"},
    {"nombre": "Salud",             "icono": "💊", "color": "#96CEB4", "tipo": "gasto"},
    {"nombre": "Educación",         "icono": "🎓", "color": "#FFEAA7", "tipo": "gasto"},
    {"nombre": "Entretenimiento",   "icono": "🎭", "color": "#DDA0DD", "tipo": "gasto"},
    {"nombre": "Ropa y calzado",    "icono": "👗", "color": "#F0E68C", "tipo": "gasto"},
    {"nombre": "Tecnología",        "icono": "📱", "color": "#87CEEB", "tipo": "gasto"},
    {"nombre": "Viajes",            "icono": "✈️", "color": "#FFB347", "tipo": "gasto"},
    {"nombre": "Deudas y créditos", "icono": "💳", "color": "#FF6B9D", "tipo": "gasto"},
    {"nombre": "Mascotas",          "icono": "🐾", "color": "#C3A6FF", "tipo": "gasto"},
    {"nombre": "Regalos",           "icono": "🎁", "color": "#FF9F43", "tipo": "gasto"},
    {"nombre": "Cuidado personal",  "icono": "💈", "color": "#FD79A8", "tipo": "gasto"},
    {"nombre": "Deporte",           "icono": "🏋️", "color": "#00B894", "tipo": "gasto"},
    {"nombre": "Seguros",           "icono": "🛡️", "color": "#636E72", "tipo": "gasto"},
    {"nombre": "Otros gastos",      "icono": "📦", "color": "#B2BEC3", "tipo": "gasto"},
    # ── Ingresos ─────────────────────────────────────────────────────────────
    {"nombre": "Sueldo",            "icono": "💰", "color": "#00B894", "tipo": "ingreso"},
    {"nombre": "Freelance",         "icono": "💼", "color": "#0984E3", "tipo": "ingreso"},
    {"nombre": "Inversiones",       "icono": "📈", "color": "#6C5CE7", "tipo": "ingreso"},
    {"nombre": "Arriendo",          "icono": "🏢", "color": "#E17055", "tipo": "ingreso"},
    {"nombre": "Otros ingresos",    "icono": "💸", "color": "#B2BEC3", "tipo": "ingreso"},
]


async def seed_categories() -> None:
    async with AsyncSessionLocal() as db:
        existing = (await db.execute(
            select(Category).where(Category.es_sistema == True).limit(1)
        )).scalar_one_or_none()

        if existing is not None:
            print("  ✓ Categorías del sistema ya existen — sin cambios.")
            return

        for data in SYSTEM_CATEGORIES:
            db.add(Category(es_sistema=True, **data))

        await db.commit()
        print(f"  ✓ {len(SYSTEM_CATEGORIES)} categorías del sistema insertadas.")


def run() -> None:
    asyncio.run(seed_categories())


if __name__ == "__main__":
    run()
