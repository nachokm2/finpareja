"""
Configuración compartida de tests.

Estrategia:
- Base de datos SQLite en memoria (rápida, sin dependencias externas en CI).
- Las tablas se crean desde Base.metadata (no desde migraciones Alembic, que
  usan tipos específicos de Postgres). Esto prueba la lógica de la app, no el
  dialecto de la DB.
- Se hace override de get_db para usar la sesión de test.
- El rate limiter se desactiva para no interferir con los tests de auth.
"""
import os

# Variables de entorno ANTES de importar la app (config.py las lee al cargar).
os.environ.setdefault("SECRET_KEY", "test_secret_key_minimo_32_caracteres_ok_1234567890")
os.environ.setdefault("APP_ENV", "development")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.database import Base
from app.dependencies import get_db
from app.main import app
from app.core.rate_limit import limiter

# Importar todos los modelos para que Base.metadata los conozca.
from app.models import (  # noqa: F401
    user,
    auth_token,
    couple,
    settlement,
    category,
    transaction,
    budget,
    saving_goal,
    debt,
    investment,
)


@pytest_asyncio.fixture
async def db_session():
    """Engine SQLite en memoria nuevo por test (aislamiento total)."""
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_maker = async_sessionmaker(engine, expire_on_commit=False)
    async with session_maker() as session:
        yield session

    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session):
    """
    AsyncClient con get_db apuntando a la sesión de test y el rate limiter
    desactivado. Cada test recibe una DB limpia.
    """
    async def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    limiter.enabled = False

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()
    limiter.enabled = True


@pytest_asyncio.fixture
async def auth_headers(client):
    """Registra e inicia sesión un usuario de prueba; devuelve headers con el token."""
    await client.post("/auth/register", json={
        "email": "user@test.cl",
        "password": "Password123",
        "full_name": "Usuario Prueba",
    })
    resp = await client.post("/auth/login", json={
        "email": "user@test.cl",
        "password": "Password123",
    })
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
