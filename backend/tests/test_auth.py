"""Tests del flujo de autenticación (el más crítico)."""
import pytest


async def test_register_success(client):
    resp = await client.post("/auth/register", json={
        "email": "nuevo@test.cl",
        "password": "Password123",
        "full_name": "Nuevo Usuario",
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["id"] > 0
    assert "exitosamente" in body["message"].lower()


async def test_register_duplicate_email(client):
    payload = {"email": "dup@test.cl", "password": "Password123", "full_name": "Dup"}
    await client.post("/auth/register", json=payload)
    resp = await client.post("/auth/register", json=payload)
    assert resp.status_code == 409


async def test_register_normalizes_email_lowercase(client):
    await client.post("/auth/register", json={
        "email": "MAYUS@test.cl", "password": "Password123", "full_name": "X",
    })
    # Debe poder loguear con minúsculas aunque registró en mayúsculas.
    resp = await client.post("/auth/login", json={
        "email": "mayus@test.cl", "password": "Password123",
    })
    assert resp.status_code == 200


async def test_login_success_returns_tokens(client):
    await client.post("/auth/register", json={
        "email": "login@test.cl", "password": "Password123", "full_name": "Login",
    })
    resp = await client.post("/auth/login", json={
        "email": "login@test.cl", "password": "Password123",
    })
    assert resp.status_code == 200
    body = resp.json()
    assert body["access_token"]
    assert body["refresh_token"]
    assert body["token_type"] == "bearer"


async def test_login_wrong_password(client):
    await client.post("/auth/register", json={
        "email": "wp@test.cl", "password": "Password123", "full_name": "WP",
    })
    resp = await client.post("/auth/login", json={
        "email": "wp@test.cl", "password": "incorrecta",
    })
    assert resp.status_code == 401


async def test_login_nonexistent_user(client):
    resp = await client.post("/auth/login", json={
        "email": "nadie@test.cl", "password": "Password123",
    })
    assert resp.status_code == 401


async def test_me_requires_auth(client):
    resp = await client.get("/auth/me")
    assert resp.status_code in (401, 403)  # sin token


async def test_me_returns_profile_with_null_fields(client, auth_headers):
    """Regresión: /me crasheaba cuando phone_number/avatar_url eran null."""
    resp = await client.get("/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["email"] == "user@test.cl"
    assert body["full_name"] == "Usuario Prueba"
    assert body["phone_number"] is None  # no se registró → null, no debe romper
    assert body["roles"] == ["user"]


async def test_refresh_rotates_token(client):
    await client.post("/auth/register", json={
        "email": "rot@test.cl", "password": "Password123", "full_name": "Rot",
    })
    login = await client.post("/auth/login", json={
        "email": "rot@test.cl", "password": "Password123",
    })
    old_refresh = login.json()["refresh_token"]

    # Usar el refresh token → debe emitir uno nuevo.
    r1 = await client.post("/auth/refresh", json={"refresh_token": old_refresh})
    assert r1.status_code == 200
    new_refresh = r1.json()["refresh_token"]
    assert new_refresh != old_refresh

    # El refresh token viejo ya fue revocado (rotación) → debe fallar.
    r2 = await client.post("/auth/refresh", json={"refresh_token": old_refresh})
    assert r2.status_code == 401


async def test_refresh_invalid_token(client):
    resp = await client.post("/auth/refresh", json={"refresh_token": "no-existe"})
    assert resp.status_code == 401


async def test_logout_revokes_refresh(client):
    await client.post("/auth/register", json={
        "email": "out@test.cl", "password": "Password123", "full_name": "Out",
    })
    login = await client.post("/auth/login", json={
        "email": "out@test.cl", "password": "Password123",
    })
    refresh = login.json()["refresh_token"]

    out = await client.post("/auth/logout", json={"refresh_token": refresh})
    assert out.status_code == 204

    # Tras logout, el refresh ya no sirve.
    resp = await client.post("/auth/refresh", json={"refresh_token": refresh})
    assert resp.status_code == 401
