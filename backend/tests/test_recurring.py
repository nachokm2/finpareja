"""Tests de transacciones recurrentes: CRUD y materialización."""
from datetime import date, timedelta


async def test_create_and_list_recurring(client, auth_headers):
    resp = await client.post("/recurrentes", headers=auth_headers, json={
        "tipo": "gasto", "monto": 30000, "frecuencia": "mensual",
        "proxima_fecha": date.today().isoformat(), "descripcion": "Arriendo",
    })
    assert resp.status_code == 201
    assert resp.json()["frecuencia"] == "mensual"

    lst = await client.get("/recurrentes", headers=auth_headers)
    assert lst.status_code == 200
    assert len(lst.json()) == 1


async def test_process_generates_transaction_and_advances(client, auth_headers):
    today = date.today()
    await client.post("/recurrentes", headers=auth_headers, json={
        "tipo": "gasto", "monto": 30000, "frecuencia": "mensual",
        "proxima_fecha": today.isoformat(), "descripcion": "Arriendo",
    })

    proc = await client.post("/recurrentes/procesar", headers=auth_headers)
    assert proc.status_code == 200
    assert proc.json()["creadas"] == 1

    # Se creó la transacción real con la fecha de hoy.
    txs = await client.get("/transacciones", headers=auth_headers)
    assert txs.json()["total"] == 1
    assert txs.json()["items"][0]["fecha"] == today.isoformat()

    # La proxima_fecha avanzó al futuro → procesar de nuevo no duplica.
    rec = (await client.get("/recurrentes", headers=auth_headers)).json()[0]
    assert date.fromisoformat(rec["proxima_fecha"]) > today

    proc2 = await client.post("/recurrentes/procesar", headers=auth_headers)
    assert proc2.json()["creadas"] == 0
    assert (await client.get("/transacciones", headers=auth_headers)).json()["total"] == 1


async def test_weekly_catches_up_multiple_periods(client, auth_headers):
    today = date.today()
    start = today - timedelta(days=21)  # 3 semanas atrás → 4 ocurrencias (21,14,7,0)
    await client.post("/recurrentes", headers=auth_headers, json={
        "tipo": "ingreso", "monto": 5000, "frecuencia": "semanal",
        "proxima_fecha": start.isoformat(),
    })
    proc = await client.post("/recurrentes/procesar", headers=auth_headers)
    assert proc.json()["creadas"] == 4


async def test_inactive_not_processed(client, auth_headers):
    today = date.today()
    created = await client.post("/recurrentes", headers=auth_headers, json={
        "tipo": "gasto", "monto": 1000, "frecuencia": "mensual",
        "proxima_fecha": today.isoformat(),
    })
    rec_id = created.json()["id"]
    await client.patch(f"/recurrentes/{rec_id}", headers=auth_headers, json={"activo": False})

    proc = await client.post("/recurrentes/procesar", headers=auth_headers)
    assert proc.json()["creadas"] == 0


async def test_rejects_invalid_frequency(client, auth_headers):
    resp = await client.post("/recurrentes", headers=auth_headers, json={
        "tipo": "gasto", "monto": 1000, "frecuencia": "diaria",
        "proxima_fecha": date.today().isoformat(),
    })
    assert resp.status_code == 422
