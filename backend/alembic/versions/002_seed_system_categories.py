"""seed system categories

Revision ID: 002
Revises: 001
Create Date: 2026-05-31
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import table, column, String, Boolean

revision = "002"
down_revision = "001"
branch_labels = None
depends_on = None

categorias = table(
    "categorias",
    column("nombre", String),
    column("icono", String),
    column("color", String),
    column("tipo", String),
    column("es_sistema", Boolean),
)

SYSTEM_CATEGORIES = [
    # Gastos
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
    # Ingresos
    {"nombre": "Sueldo",            "icono": "💰", "color": "#00B894", "tipo": "ingreso"},
    {"nombre": "Freelance",         "icono": "💼", "color": "#0984E3", "tipo": "ingreso"},
    {"nombre": "Inversiones",       "icono": "📈", "color": "#6C5CE7", "tipo": "ingreso"},
    {"nombre": "Arriendo",          "icono": "🏢", "color": "#E17055", "tipo": "ingreso"},
    {"nombre": "Otros ingresos",    "icono": "💸", "color": "#B2BEC3", "tipo": "ingreso"},
]


def upgrade() -> None:
    op.bulk_insert(
        categorias,
        [{"es_sistema": True, **cat} for cat in SYSTEM_CATEGORIES],
    )


def downgrade() -> None:
    op.execute("DELETE FROM categorias WHERE es_sistema = TRUE")
