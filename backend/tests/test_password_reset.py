"""
Tests del flujo de recuperación de contraseña y verificación de email.

El OTP se captura interceptando send_otp_email (que en tests no envía nada
real). Así el test conoce el código en claro para completar el flujo.
"""
import pytest

from app.routers import auth as auth_router


@pytest.fixture
def captured_otps(monkeypatch):
    """Intercepta los OTP enviados; devuelve dict {(email, purpose): code}."""
    store: dict[tuple[str, str], str] = {}

    def _fake_send(to: str, code: str, purpose: str) -> None:
        store[(to, purpose)] = code

    monkeypatch.setattr(auth_router, "send_otp_email", _fake_send)
    return store


async def _register(client, email="reset@test.cl"):
    await client.post("/auth/register", json={
        "email": email, "password": "Password123", "full_name": "Reset",
    })


# ── Recuperación de contraseña ───────────────────────────────────────────────

async def test_forgot_password_returns_generic_ok(client, captured_otps):
    await _register(client)
    resp = await client.post("/auth/forgot-password", json={"email": "reset@test.cl"})
    assert resp.status_code == 200
    # Se generó un OTP de reset.
    assert ("reset@test.cl", "password_reset") in captured_otps


async def test_forgot_password_unknown_email_still_ok(client, captured_otps):
    """No revela si el correo existe (anti-enumeration)."""
    resp = await client.post("/auth/forgot-password", json={"email": "nadie@test.cl"})
    assert resp.status_code == 200
    assert ("nadie@test.cl", "password_reset") not in captured_otps


async def test_full_password_reset_flow(client, captured_otps):
    await _register(client)
    await client.post("/auth/forgot-password", json={"email": "reset@test.cl"})
    code = captured_otps[("reset@test.cl", "password_reset")]

    # Resetear con el código correcto.
    resp = await client.post("/auth/reset-password", json={
        "email": "reset@test.cl", "code": code, "new_password": "NuevaPass456",
    })
    assert resp.status_code == 200

    # La contraseña vieja ya no sirve.
    old = await client.post("/auth/login", json={
        "email": "reset@test.cl", "password": "Password123",
    })
    assert old.status_code == 401

    # La nueva sí.
    new = await client.post("/auth/login", json={
        "email": "reset@test.cl", "password": "NuevaPass456",
    })
    assert new.status_code == 200


async def test_reset_with_wrong_code_fails(client, captured_otps):
    await _register(client)
    await client.post("/auth/forgot-password", json={"email": "reset@test.cl"})
    resp = await client.post("/auth/reset-password", json={
        "email": "reset@test.cl", "code": "000000", "new_password": "X123456789",
    })
    assert resp.status_code == 400


async def test_otp_single_use(client, captured_otps):
    await _register(client)
    await client.post("/auth/forgot-password", json={"email": "reset@test.cl"})
    code = captured_otps[("reset@test.cl", "password_reset")]

    first = await client.post("/auth/reset-password", json={
        "email": "reset@test.cl", "code": code, "new_password": "NuevaPass456",
    })
    assert first.status_code == 200

    # El mismo código no se puede reutilizar.
    second = await client.post("/auth/reset-password", json={
        "email": "reset@test.cl", "code": code, "new_password": "OtraMas789",
    })
    assert second.status_code == 400


# ── Verificación de email ────────────────────────────────────────────────────

async def test_register_sends_verification_otp(client, captured_otps):
    await _register(client, email="verif@test.cl")
    assert ("verif@test.cl", "email_verification") in captured_otps


async def test_verify_email_flow(client, captured_otps):
    await _register(client, email="verif@test.cl")
    code = captured_otps[("verif@test.cl", "email_verification")]

    resp = await client.post("/auth/verify-email", json={
        "email": "verif@test.cl", "code": code,
    })
    assert resp.status_code == 200

    # Confirmar que is_verified pasó a true vía /me.
    login = await client.post("/auth/login", json={
        "email": "verif@test.cl", "password": "Password123",
    })
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    me = await client.get("/auth/me", headers=headers)
    assert me.status_code == 200
