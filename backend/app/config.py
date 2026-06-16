import json
import warnings
from functools import lru_cache

from pydantic import field_validator, model_validator
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

    # Email (SMTP). Si smtp_host está vacío, los códigos se registran en el log
    # en vez de enviarse (modo dev / sin proveedor configurado todavía).
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = "FinPareja <no-reply@finpareja.cl>"

    # Observabilidad. SENTRY_DSN vacío = Sentry desactivado (dev). LOG_JSON
    # controla el formato: JSON en producción (Railway lo indexa), legible en dev.
    sentry_dsn: str = ""
    log_level: str = "INFO"
    log_json: bool = True

    # Notificaciones push (Firebase Cloud Messaging). Si está vacío, los envíos
    # se registran en el log en vez de enviarse (modo dev / sin credenciales).
    # Se espera el JSON COMPLETO de la cuenta de servicio de Firebase como string.
    firebase_credentials: str = ""

    # CORS — se declara como STRING crudo (no list[str]) a propósito.
    # pydantic-settings intenta json.loads() sobre campos de tipo lista ANTES
    # de cualquier validador, y "*" o CSV no son JSON válido → crashea el arranque.
    # Guardamos el string tal cual y lo parseamos en allowed_origins_list.
    allowed_origins: str = "*"

    _DEFAULT_SECRET = "dev_secret_change_in_production"

    @model_validator(mode="after")
    def _validate_production_security(self) -> "Settings":
        """
        Endurecimiento de seguridad para producción (SEC-03, SEC-07).

        En producción ABORTA el arranque si:
          - SECRET_KEY sigue siendo el valor por defecto o es muy corto.
          - ALLOWED_ORIGINS es "*" (CORS abierto).

        En desarrollo solo emite warnings para no entorpecer el trabajo local.
        """
        is_prod = self.app_env == "production"

        # ── SECRET_KEY ─────────────────────────────────────────────────────
        weak_secret = (
            self.secret_key == self._DEFAULT_SECRET or len(self.secret_key) < 32
        )
        if weak_secret:
            if is_prod:
                raise ValueError(
                    "SECRET_KEY inseguro en producción: configura una clave "
                    "aleatoria de al menos 32 caracteres "
                    '(python -c "import secrets; print(secrets.token_hex(64))").'
                )
            warnings.warn(
                "SECRET_KEY débil o por defecto. Configura uno seguro antes de producción.",
                stacklevel=2,
            )

        # ── CORS ───────────────────────────────────────────────────────────
        if is_prod and "*" in self.allowed_origins_list:
            raise ValueError(
                "ALLOWED_ORIGINS no puede ser '*' en producción: especifica "
                "los dominios permitidos (CSV o JSON)."
            )

        return self

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
