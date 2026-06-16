"""Tests de registro de tokens de dispositivo para push."""
from sqlalchemy import select

from app.models.device_token import DeviceToken


async def test_register_device_token(client, db_session, auth_headers):
    resp = await client.post("/dispositivos/registrar", headers=auth_headers, json={
        "token": "tok-abc-123", "plataforma": "android",
    })
    assert resp.status_code == 204

    rows = (await db_session.execute(select(DeviceToken))).scalars().all()
    assert len(rows) == 1
    assert rows[0].token == "tok-abc-123"


async def test_register_is_idempotent(client, db_session, auth_headers):
    for _ in range(2):
        await client.post("/dispositivos/registrar", headers=auth_headers, json={
            "token": "same-token", "plataforma": "android",
        })
    rows = (await db_session.execute(select(DeviceToken))).scalars().all()
    assert len(rows) == 1  # no se duplica


async def test_unregister_device_token(client, db_session, auth_headers):
    await client.post("/dispositivos/registrar", headers=auth_headers, json={
        "token": "to-remove",
    })
    resp = await client.post("/dispositivos/eliminar", headers=auth_headers, json={
        "token": "to-remove",
    })
    assert resp.status_code == 204
    rows = (await db_session.execute(select(DeviceToken))).scalars().all()
    assert rows == []


async def test_register_requires_auth(client):
    resp = await client.post("/dispositivos/registrar", json={"token": "x"})
    assert resp.status_code in (401, 403)
