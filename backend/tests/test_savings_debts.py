"""
Tests de metas y deudas, con foco en la acumulación correcta de montos
(aportes/pagos). El lock pesimista with_for_update() se ignora en SQLite,
pero estos tests garantizan la corrección funcional del read-modify-write.
"""
import pytest


# ── Metas de ahorro ──────────────────────────────────────────────────────────

async def test_create_goal(client, auth_headers):
    resp = await client.post("/metas", headers=auth_headers, json={
        "nombre": "Vacaciones", "monto_objetivo": 100000,
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["nombre"] == "Vacaciones"
    assert float(body["monto_actual"]) == 0


async def test_contributions_accumulate(client, auth_headers):
    """Varios aportes secuenciales deben sumar correctamente."""
    goal = await client.post("/metas", headers=auth_headers, json={
        "nombre": "Fondo", "monto_objetivo": 100000,
    })
    goal_id = goal.json()["id"]

    for monto in (10000, 25000, 15000):
        r = await client.post(f"/metas/{goal_id}/aportes", headers=auth_headers, json={
            "monto": monto, "fecha": "2026-06-14",
        })
        assert r.status_code == 201

    # 10000 + 25000 + 15000 = 50000
    final = r.json()
    assert float(final["monto_actual"]) == 50000


async def test_goal_completes_when_target_reached(client, auth_headers):
    goal = await client.post("/metas", headers=auth_headers, json={
        "nombre": "Meta corta", "monto_objetivo": 1000,
    })
    goal_id = goal.json()["id"]
    r = await client.post(f"/metas/{goal_id}/aportes", headers=auth_headers, json={
        "monto": 1000, "fecha": "2026-06-14",
    })
    assert r.json()["estado"] == "completada"


async def test_contribution_on_foreign_goal_fails(client):
    """Un usuario no puede aportar a la meta de otro."""
    await client.post("/auth/register", json={
        "email": "g1@test.cl", "password": "Password123", "full_name": "G1",
    })
    login = await client.post("/auth/login", json={"email": "g1@test.cl", "password": "Password123"})
    h1 = {"Authorization": f"Bearer {login.json()['access_token']}"}
    goal = await client.post("/metas", headers=h1, json={"nombre": "X", "monto_objetivo": 1000})
    goal_id = goal.json()["id"]

    await client.post("/auth/register", json={
        "email": "g2@test.cl", "password": "Password123", "full_name": "G2",
    })
    login2 = await client.post("/auth/login", json={"email": "g2@test.cl", "password": "Password123"})
    h2 = {"Authorization": f"Bearer {login2.json()['access_token']}"}

    r = await client.post(f"/metas/{goal_id}/aportes", headers=h2, json={
        "monto": 500, "fecha": "2026-06-14",
    })
    assert r.status_code == 404


# ── Deudas ───────────────────────────────────────────────────────────────────

async def test_create_debt_sets_pending_equal_to_original(client, auth_headers):
    resp = await client.post("/deudas", headers=auth_headers, json={
        "acreedor": "Banco", "monto_original": 50000,
    })
    assert resp.status_code == 201
    body = resp.json()
    assert float(body["monto_original"]) == 50000
    assert float(body["monto_pendiente"]) == 50000


async def test_payments_reduce_pending(client, auth_headers):
    """Pagos sucesivos reducen el pendiente correctamente."""
    debt = await client.post("/deudas", headers=auth_headers, json={
        "acreedor": "Banco", "monto_original": 50000,
    })
    debt_id = debt.json()["id"]

    for monto in (10000, 15000):
        r = await client.post(f"/deudas/{debt_id}/pagos", headers=auth_headers, json={
            "monto": monto, "fecha": "2026-06-14",
        })
        assert r.status_code == 201

    # 50000 - 10000 - 15000 = 25000
    assert float(r.json()["monto_pendiente"]) == 25000


async def test_debt_marked_paid_when_fully_paid(client, auth_headers):
    debt = await client.post("/deudas", headers=auth_headers, json={
        "acreedor": "Banco", "monto_original": 10000,
    })
    debt_id = debt.json()["id"]
    r = await client.post(f"/deudas/{debt_id}/pagos", headers=auth_headers, json={
        "monto": 10000, "fecha": "2026-06-14",
    })
    assert r.json()["estado"] == "pagada"
    assert float(r.json()["monto_pendiente"]) == 0
