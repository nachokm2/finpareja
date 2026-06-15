"""
Tests de regresión para SEC-01 (IDOR en pareja_id).

Verifican que un usuario NO pueda crear registros asociados a una pareja
de la que no es miembro. Sin el helper assert_couple_member, estos tests
fallarían (el atacante contaminaría datos ajenos).
"""
import pytest


async def _register_login(client, email):
    await client.post("/auth/register", json={
        "email": email, "password": "Password123", "full_name": email.split("@")[0],
    })
    resp = await client.post("/auth/login", json={"email": email, "password": "Password123"})
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


async def test_cannot_create_transaction_in_foreign_couple(client):
    # Usuario A crea su pareja (queda como pareja_id=1).
    headers_a = await _register_login(client, "owner@test.cl")
    couple = await client.post("/parejas", headers=headers_a, json={"nombre": "Pareja A"})
    assert couple.status_code == 201
    pareja_id = couple.json()["id"]

    # Usuario B (ajeno) intenta inyectar una transacción en la pareja de A.
    headers_b = await _register_login(client, "attacker@test.cl")
    resp = await client.post("/transacciones", headers=headers_b, json={
        "tipo": "gasto", "monto": 1000, "fecha": "2026-06-14",
        "pareja_id": pareja_id,
    })
    assert resp.status_code == 403  # bloqueado por assert_couple_member


async def test_cannot_create_budget_in_foreign_couple(client):
    headers_a = await _register_login(client, "owner2@test.cl")
    couple = await client.post("/parejas", headers=headers_a, json={"nombre": "Pareja A2"})
    pareja_id = couple.json()["id"]

    headers_b = await _register_login(client, "attacker2@test.cl")
    resp = await client.post("/presupuestos", headers=headers_b, json={
        "monto_limite": 50000, "pareja_id": pareja_id,
    })
    assert resp.status_code == 403


async def test_cannot_create_goal_in_foreign_couple(client):
    headers_a = await _register_login(client, "owner3@test.cl")
    couple = await client.post("/parejas", headers=headers_a, json={"nombre": "Pareja A3"})
    pareja_id = couple.json()["id"]

    headers_b = await _register_login(client, "attacker3@test.cl")
    resp = await client.post("/metas", headers=headers_b, json={
        "nombre": "Robo", "monto_objetivo": 100000, "pareja_id": pareja_id,
    })
    assert resp.status_code == 403


async def test_member_can_create_in_own_couple(client):
    """Control positivo: el dueño SÍ puede crear en su propia pareja."""
    headers_a = await _register_login(client, "legit@test.cl")
    couple = await client.post("/parejas", headers=headers_a, json={"nombre": "Mía"})
    pareja_id = couple.json()["id"]

    resp = await client.post("/transacciones", headers=headers_a, json={
        "tipo": "gasto", "monto": 1000, "fecha": "2026-06-14",
        "pareja_id": pareja_id,
    })
    assert resp.status_code == 201


async def test_personal_transaction_without_couple_works(client, auth_headers):
    """Control: transacción personal (pareja_id None) no requiere membresía."""
    resp = await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": 1000, "fecha": "2026-06-14",
    })
    assert resp.status_code == 201
