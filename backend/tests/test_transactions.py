"""Tests de transacciones: CRUD, validación y aislamiento entre usuarios."""
import pytest


async def test_create_transaction(client, auth_headers):
    resp = await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": 28500, "fecha": "2026-06-14",
        "descripcion": "Supermercado",
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["tipo"] == "gasto"
    # Pydantic serializa Decimal como string; el cliente Flutter ya lo maneja.
    assert float(body["monto"]) == 28500.0


async def test_create_requires_auth(client):
    resp = await client.post("/transacciones", json={
        "tipo": "gasto", "monto": 100, "fecha": "2026-06-14",
    })
    assert resp.status_code in (401, 403)


async def test_create_rejects_negative_amount(client, auth_headers):
    resp = await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": -500, "fecha": "2026-06-14",
    })
    assert resp.status_code == 422  # validación Pydantic


async def test_create_rejects_invalid_tipo(client, auth_headers):
    resp = await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "transferencia", "monto": 100, "fecha": "2026-06-14",
    })
    assert resp.status_code == 422


async def test_list_returns_own_transactions(client, auth_headers):
    for i in range(3):
        await client.post("/transacciones", headers=auth_headers, json={
            "tipo": "gasto", "monto": 100 + i, "fecha": "2026-06-14",
        })
    resp = await client.get("/transacciones", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 3
    assert len(body["items"]) == 3


async def test_delete_transaction(client, auth_headers):
    created = await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "ingreso", "monto": 5000, "fecha": "2026-06-14",
    })
    tx_id = created.json()["id"]
    resp = await client.delete(f"/transacciones/{tx_id}", headers=auth_headers)
    assert resp.status_code == 204

    # Ya no aparece en la lista.
    lst = await client.get("/transacciones", headers=auth_headers)
    assert lst.json()["total"] == 0


async def test_user_cannot_see_others_transactions(client):
    """Aislamiento: un usuario no ve ni borra transacciones de otro."""
    # Usuario A crea una transacción.
    await client.post("/auth/register", json={
        "email": "a@test.cl", "password": "Password123", "full_name": "A",
    })
    login_a = await client.post("/auth/login", json={
        "email": "a@test.cl", "password": "Password123",
    })
    headers_a = {"Authorization": f"Bearer {login_a.json()['access_token']}"}
    created = await client.post("/transacciones", headers=headers_a, json={
        "tipo": "gasto", "monto": 9999, "fecha": "2026-06-14",
    })
    tx_id = created.json()["id"]

    # Usuario B no debe verla ni borrarla.
    await client.post("/auth/register", json={
        "email": "b@test.cl", "password": "Password123", "full_name": "B",
    })
    login_b = await client.post("/auth/login", json={
        "email": "b@test.cl", "password": "Password123",
    })
    headers_b = {"Authorization": f"Bearer {login_b.json()['access_token']}"}

    lst_b = await client.get("/transacciones", headers=headers_b)
    assert lst_b.json()["total"] == 0

    del_b = await client.delete(f"/transacciones/{tx_id}", headers=headers_b)
    assert del_b.status_code == 404  # no es suya → no la encuentra
