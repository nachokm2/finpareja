"""Tests de tarjetas de crédito: compras (contado/cuotas), pagos y saldo."""


async def _crear_tarjeta(client, auth_headers, nombre="Visa") -> int:
    resp = await client.post("/tarjetas", headers=auth_headers, json={
        "nombre": nombre, "ultimos_digitos": "1234", "cupo": 1000000,
    })
    assert resp.status_code == 201
    return resp.json()["id"]


async def test_create_and_list_card(client, auth_headers):
    await _crear_tarjeta(client, auth_headers)
    resp = await client.get("/tarjetas", headers=auth_headers)
    assert resp.status_code == 200
    cards = resp.json()
    assert len(cards) == 1
    assert float(cards[0]["saldo_pendiente"]) == 0.0


async def test_contado_purchase_increases_balance(client, auth_headers):
    cid = await _crear_tarjeta(client, auth_headers)
    await client.post(f"/tarjetas/{cid}/compras", headers=auth_headers, json={
        "monto": 50000, "fecha": "2026-06-16", "descripcion": "Zapatos", "cuotas": 1,
    })
    card = (await client.get(f"/tarjetas/{cid}", headers=auth_headers)).json()
    assert float(card["saldo_pendiente"]) == 50000.0
    assert float(card["total_compras"]) == 50000.0


async def test_cuotas_purchase_includes_interest(client, auth_headers):
    cid = await _crear_tarjeta(client, auth_headers)
    # 3 cuotas de 20.000 = 60.000 deuda; compra (principal) 50.000 → interés 10.000.
    resp = await client.post(f"/tarjetas/{cid}/compras", headers=auth_headers, json={
        "monto": 50000, "fecha": "2026-06-16", "cuotas": 3, "valor_cuota": 20000,
    })
    compra = resp.json()
    assert float(compra["deuda"]) == 60000.0
    assert float(compra["interes"]) == 10000.0

    card = (await client.get(f"/tarjetas/{cid}", headers=auth_headers)).json()
    assert float(card["saldo_pendiente"]) == 60000.0


async def test_payment_reduces_balance(client, auth_headers):
    cid = await _crear_tarjeta(client, auth_headers)
    await client.post(f"/tarjetas/{cid}/compras", headers=auth_headers, json={
        "monto": 100000, "fecha": "2026-06-16", "cuotas": 1,
    })
    await client.post(f"/tarjetas/{cid}/pagos", headers=auth_headers, json={
        "monto": 30000, "fecha": "2026-06-16",
    })
    card = (await client.get(f"/tarjetas/{cid}", headers=auth_headers)).json()
    assert float(card["saldo_pendiente"]) == 70000.0
    assert float(card["total_pagado"]) == 30000.0
    assert float(card["cupo_disponible"]) == 930000.0


async def test_gasto_con_tarjeta_crea_compra(client, auth_headers):
    cid = await _crear_tarjeta(client, auth_headers)
    # Un gasto pagado con la tarjeta debe aparecer en su deuda.
    resp = await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": 12000, "fecha": "2026-06-16", "tarjeta_id": cid,
    })
    assert resp.status_code == 201
    assert resp.json()["tarjeta_id"] == cid

    card = (await client.get(f"/tarjetas/{cid}", headers=auth_headers)).json()
    assert float(card["saldo_pendiente"]) == 12000.0
    compras = (await client.get(f"/tarjetas/{cid}/compras", headers=auth_headers)).json()
    assert len(compras) == 1


async def test_card_isolation_between_users(client):
    # Usuario A crea una tarjeta; B no debe poder verla ni operarla.
    await client.post("/auth/register", json={
        "email": "ca@test.cl", "password": "Password123", "full_name": "CA",
    })
    la = await client.post("/auth/login", json={"email": "ca@test.cl", "password": "Password123"})
    ha = {"Authorization": f"Bearer {la.json()['access_token']}"}
    cid = await _crear_tarjeta(client, ha)

    await client.post("/auth/register", json={
        "email": "cb@test.cl", "password": "Password123", "full_name": "CB",
    })
    lb = await client.post("/auth/login", json={"email": "cb@test.cl", "password": "Password123"})
    hb = {"Authorization": f"Bearer {lb.json()['access_token']}"}

    assert (await client.get("/tarjetas", headers=hb)).json() == []
    assert (await client.get(f"/tarjetas/{cid}", headers=hb)).status_code == 404
