"""Tests de alertas de presupuesto (/presupuestos/alertas)."""
from datetime import date


async def test_alert_fires_when_threshold_crossed(client, auth_headers):
    today = date.today()
    # Presupuesto de 10.000 con alerta al 80%.
    await client.post("/presupuestos", headers=auth_headers, json={
        "monto_limite": 10000, "alerta_porcentaje": 80,
    })
    # Gasto de 9.000 (90%) en el mes actual → cruza el umbral.
    await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": 9000, "fecha": today.isoformat(),
    })

    resp = await client.get("/presupuestos/alertas", headers=auth_headers)
    assert resp.status_code == 200
    alerts = resp.json()
    assert len(alerts) == 1
    assert alerts[0]["alerta_activa"] is True
    assert float(alerts[0]["porcentaje_usado"]) >= 80


async def test_no_alert_below_threshold(client, auth_headers):
    today = date.today()
    await client.post("/presupuestos", headers=auth_headers, json={
        "monto_limite": 10000, "alerta_porcentaje": 80,
    })
    # Gasto de 1.000 (10%) → no debe alertar.
    await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": 1000, "fecha": today.isoformat(),
    })

    resp = await client.get("/presupuestos/alertas", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []
