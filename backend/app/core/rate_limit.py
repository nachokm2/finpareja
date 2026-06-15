"""
Rate limiting con slowapi (SEC-04).

Protege endpoints sensibles (login/registro) contra fuerza bruta y
credential stuffing. La clave por defecto es la IP del cliente.

En Railway, el cliente real viene en el header X-Forwarded-For, así que
usamos un key_func que lo respeta cuando está presente.
"""
from slowapi import Limiter
from slowapi.util import get_remote_address
from starlette.requests import Request


def _client_key(request: Request) -> str:
    # Railway/Proxies: primer IP de X-Forwarded-For; fallback a la IP directa.
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return get_remote_address(request)


limiter = Limiter(key_func=_client_key)
