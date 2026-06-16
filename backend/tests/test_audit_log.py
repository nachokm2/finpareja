"""Tests del audit log: las acciones sensibles quedan registradas."""
from sqlalchemy import select

from app.models.audit_log import AuditLog


async def test_login_is_audited(client, db_session, auth_headers):
    # auth_headers ya hizo register + login del usuario de prueba.
    rows = (await db_session.execute(
        select(AuditLog).where(AuditLog.accion == "login")
    )).scalars().all()
    assert len(rows) == 1
    assert rows[0].usuario_id is not None


async def test_transaction_delete_is_audited(client, db_session, auth_headers):
    created = await client.post("/transacciones", headers=auth_headers, json={
        "tipo": "gasto", "monto": 1234, "fecha": "2026-06-15",
    })
    tx_id = created.json()["id"]
    resp = await client.delete(f"/transacciones/{tx_id}", headers=auth_headers)
    assert resp.status_code == 204

    rows = (await db_session.execute(
        select(AuditLog).where(AuditLog.accion == "transaction.delete")
    )).scalars().all()
    assert len(rows) == 1
    assert rows[0].entidad == "transaccion"
    assert rows[0].entidad_id == tx_id
