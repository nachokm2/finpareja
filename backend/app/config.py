import json
import warnings
from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    app_name: str = "FinPareja API"
    debug: bool = False
    app_env: str = "development"

    # Railway inyecta DATABASE_URL como "postgresql://..." o "postgres://..."
    # SQLAlchemy async necesita "postgresql+asyncpg://..."
    # El default usa el formato asyncpg directamente para desarrollo local.
    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/finpareja"

    # JWT
    secret_key: str = "dev_secret_change_in_production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 30

    # CORS — se declara como STRING crudo (no list[str]) a propósito.
    # pydantic-settings intenta json.loads() sobre campos de tipo lista ANTES
    # de cualquier validador, y "*" o CSV no son JSON válido → crashea el arranque.
    # Guardamos el string tal cual y lo parseamos en allowed_origins_list.
    allowed_origins: str = "*"

    @field_validator("secret_key")
    @classmethod
    def _warn_default_secret(cls, value: str) -> str:
        # No bloquea el arranque (para no romper dev), pero deja constancia.
        if value == "dev_secret_change_in_production":
            warnings.warn(
                "SECRET_KEY usa el valor por defecto. Configura uno seguro en producción.",
                stacklevel=2,
            )
        return value

    @property
    def allowed_origins_list(self) -> list[str]:
        """
        Parsea allowed_origins (string) a lista. Acepta:
          - "*"                              → ["*"]
          - "https://a.com,https://b.com"    → CSV
          - '["https://a.com"]'              → JSON
        """
        raw = self.allowed_origins.strip()
        if not raw:
            return ["*"]
        if raw.startswith("["):
            try:
                return [str(o) for o in json.loads(raw)]
            except (ValueError, TypeError):
                pass
        return [o.strip() for o in raw.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def async_database_url(self) -> str:
        """
        Normaliza la URL de base de datos para SQLAlchemy async.

        Railway provee: postgres:// o postgresql://
        SQLAlchemy necesita: postgresql+asyncpg://
        """
        url = self.database_url
        replacements = [
            ("postgres://", "postgresql+asyncpg://"),
            ("postgresql://", "postgresql+asyncpg://"),
        ]
        for old, new in replacements:
            if url.startswith(old):
                return new + url[len(old):]
        return url  # ya tiene el prefijo correcto


@lru_cache
def get_settings() -> Settings:
    return Settings()
