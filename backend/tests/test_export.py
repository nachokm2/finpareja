"""Test de exportación CSV de transacciones."""


async def test_export_returns_csv(client, auth_headers):
    await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": 12345, "fecha": "2026-06-10",
        "descripcion": "Café",
    })
    resp = await client.get("/transacciones/export", headers=auth_headers)
    assert resp.status_code == 200
    assert "text/csv" in resp.headers["content-type"]
    body = resp.text
    assert "fecha,tipo,categoria,monto" in body
    assert "12345" in body
    assert "Café" in body


async def test_export_requires_auth(client):
    resp = await client.get("/transacciones/export")
    assert resp.status_code in (401, 403)
