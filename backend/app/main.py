import logging

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler
from sqlalchemy import text

from .config import get_settings
from .core.rate_limit import limiter
from .database import engine
from .routers import (
    auth,
    users,
    couples,
    categories,
    transactions,
    budgets,
    savings,
    debts,
    investments,
    reports,
)

settings = get_settings()
logger = logging.getLogger("finpareja")

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Rate limiting (SEC-04): registra el limiter y el handler de 429.
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Manejo global de errores ─────────────────────────────────────────────────
# En producción nunca devolvemos el stacktrace al cliente; lo registramos
# en logs (visibles en Railway) y respondemos un mensaje genérico.
@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Error no manejado en %s %s", request.method, request.url.path)
    detail = "Error interno del servidor"
    if settings.debug:
        detail = f"{type(exc).__name__}: {exc}"
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": detail},
    )


app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(users.router, prefix="/usuarios", tags=["usuarios"])
app.include_router(couples.router, prefix="/parejas", tags=["parejas"])
app.include_router(categories.router, prefix="/categorias", tags=["categorias"])
app.include_router(transactions.router, prefix="/transacciones", tags=["transacciones"])
app.include_router(budgets.router, prefix="/presupuestos", tags=["presupuestos"])
app.include_router(savings.router, prefix="/metas", tags=["metas"])
app.include_router(debts.router, prefix="/deudas", tags=["deudas"])
app.include_router(investments.router, prefix="/inversiones", tags=["inversiones"])
app.include_router(reports.router, prefix="/reportes", tags=["reportes"])


@app.get("/health", tags=["health"])
async def health():
    """
    Healthcheck para Railway. Verifica conectividad real con PostgreSQL,
    no solo que el proceso esté vivo. Si la DB no responde, devuelve 503
    para que Railway no enrute tráfico a una instancia degradada.
    """
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        logger.exception("Healthcheck: fallo de conexión a la base de datos")
        db_ok = False

    payload = {
        "status": "ok" if db_ok else "degraded",
        "env": settings.app_env,
        "database": "up" if db_ok else "down",
    }
    code = status.HTTP_200_OK if db_ok else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(status_code=code, content=payload)
