"""
Tests del core de pareja: división de gastos compartidos, balance neto
"quién le debe a quién" y liquidaciones. Es el diferenciador del producto
(FIN-01), así que se prueba el cálculo del dinero con cuidado.
"""
import pytest


async def _register_login(client, email):
    await client.post("/auth/register", json={
        "email": email, "password": "Password123", "full_name": email.split("@")[0],
    })
    resp = await client.post("/auth/login", json={"email": email, "password": "Password123"})
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


@pytest.fixture
async def couple(client):
    """Crea una pareja con 2 miembros (A crea, B se une). Devuelve headers + ids."""
    ha = await _register_login(client, "a@pareja.cl")
    created = await client.post("/parejas", headers=ha, json={"nombre": "Test"})
    pareja_id = created.json()["id"]

    invite = await client.post("/parejas/invite", headers=ha, json={"email": "b@pareja.cl"})
    token = invite.json()["token"]

    hb = await _register_login(client, "b@pareja.cl")
    await client.post("/parejas/accept", headers=hb, json={"token": token})

    return {"headers_a": ha, "headers_b": hb, "pareja_id": pareja_id}


async def _shared_expense(client, headers, pareja_id, monto, pct_usuario):
    """Crea un gasto compartido pagado por 'headers' con su porcentaje."""
    return await client.post("/transacciones", headers=headers, json={
        "tipo": "gasto", "monto": monto, "fecha": "2026-06-15",
        "pareja_id": pareja_id, "es_compartido": True,
        "porcentaje_usuario": pct_usuario,
    })


async def test_balance_zero_initially(client, couple):
    resp = await client.get("/parejas/balance", headers=couple["headers_a"])
    assert resp.status_code == 200
    body = resp.json()
    assert float(body["balance"]) == 0
    assert body["tiene_pareja_completa"] is True


async def test_5050_split_creates_balance(client, couple):
    """A paga $10.000 al 50/50 → B le debe $5.000."""
    await _shared_expense(client, couple["headers_a"], couple["pareja_id"], 10000, 50)

    # Desde A: le deben $5.000.
    bal_a = (await client.get("/parejas/balance", headers=couple["headers_a"])).json()
    assert float(bal_a["balance"]) == 5000
    assert float(bal_a["te_deben"]) == 5000
    assert float(bal_a["debes"]) == 0

    # Desde B: debe $5.000 (balance negativo).
    bal_b = (await client.get("/parejas/balance", headers=couple["headers_b"])).json()
    assert float(bal_b["balance"]) == -5000
    assert float(bal_b["debes"]) == 5000


async def test_mutual_expenses_net_out(client, couple):
    """A paga $10.000 (50/50) y B paga $4.000 (50/50). Neto: B debe $3.000."""
    await _shared_expense(client, couple["headers_a"], couple["pareja_id"], 10000, 50)
    await _shared_expense(client, couple["headers_b"], couple["pareja_id"], 4000, 50)

    # A: le deben 5000, debe 2000 → neto +3000.
    bal_a = (await client.get("/parejas/balance", headers=couple["headers_a"])).json()
    assert float(bal_a["balance"]) == 3000


async def test_custom_percentage_split(client, couple):
    """A paga $10.000 pero solo le corresponde 30% → B le debe $7.000."""
    await _shared_expense(client, couple["headers_a"], couple["pareja_id"], 10000, 30)
    bal_a = (await client.get("/parejas/balance", headers=couple["headers_a"])).json()
    assert float(bal_a["balance"]) == 7000


async def test_settlement_reduces_balance(client, couple):
    """A paga $10.000 (50/50) → B debe $5.000. B liquida $5.000 → quedan a mano."""
    await _shared_expense(client, couple["headers_a"], couple["pareja_id"], 10000, 50)

    settle = await client.post("/parejas/liquidar", headers=couple["headers_b"], json={
        "monto": 5000, "fecha": "2026-06-15", "nota": "Pago mi parte",
    })
    assert settle.status_code == 201

    bal_a = (await client.get("/parejas/balance", headers=couple["headers_a"])).json()
    assert float(bal_a["balance"]) == 0


async def test_partial_settlement(client, couple):
    """B debe $5.000, paga $2.000 → sigue debiendo $3.000."""
    await _shared_expense(client, couple["headers_a"], couple["pareja_id"], 10000, 50)
    await client.post("/parejas/liquidar", headers=couple["headers_b"], json={
        "monto": 2000, "fecha": "2026-06-15",
    })
    bal_a = (await client.get("/parejas/balance", headers=couple["headers_a"])).json()
    assert float(bal_a["balance"]) == 3000


async def test_settlements_history(client, couple):
    await _shared_expense(client, couple["headers_a"], couple["pareja_id"], 10000, 50)
    await client.post("/parejas/liquidar", headers=couple["headers_b"], json={
        "monto": 2000, "fecha": "2026-06-15",
    })
    hist = await client.get("/parejas/liquidaciones", headers=couple["headers_a"])
    assert hist.status_code == 200
    assert len(hist.json()) == 1


async def test_personal_expense_does_not_affect_balance(client, couple):
    """Un gasto NO compartido no entra en el balance de pareja."""
    await client.post("/transacciones", headers=couple["headers_a"], json={
        "tipo": "gasto", "monto": 99999, "fecha": "2026-06-15",
    })
    bal_a = (await client.get("/parejas/balance", headers=couple["headers_a"])).json()
    assert float(bal_a["balance"]) == 0


async def test_balance_requires_couple(client):
    """Sin pareja, /balance da 404."""
    headers = await _register_login(client, "solo@test.cl")
    resp = await client.get("/parejas/balance", headers=headers)
    assert resp.status_code == 404
