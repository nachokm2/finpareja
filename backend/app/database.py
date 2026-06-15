from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

from .config import get_settings

settings = get_settings()

# El pooling con pool_size/max_overflow solo aplica a Postgres. SQLite
# (usado en tests) usa StaticPool y rechaza esos argumentos.
_url = settings.async_database_url
_engine_kwargs: dict = {"echo": settings.debug}
if not _url.startswith("sqlite"):
    _engine_kwargs.update(pool_size=10, max_overflow=20, pool_pre_ping=True)

engine = create_async_engine(_url, **_engine_kwargs)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass
