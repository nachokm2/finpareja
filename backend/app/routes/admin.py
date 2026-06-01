from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.core.config import ADMIN_EMAIL, ADMIN_PASSWORD
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserAdminOut

router = APIRouter(prefix="/admin", tags=["admin"])
security = HTTPBasic()


def verify_admin(credentials: HTTPBasicCredentials = Depends(security)):
    is_valid = credentials.username == ADMIN_EMAIL and credentials.password == ADMIN_PASSWORD
    if not is_valid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid admin credentials")


@router.get("/users", response_model=List[UserAdminOut])
def list_users(_: None = Depends(verify_admin), db: Session = Depends(get_db)):
    return db.query(User).order_by(User.id).all()


@router.get("/panel", response_class=HTMLResponse)
def admin_panel(_: None = Depends(verify_admin), db: Session = Depends(get_db)):
    users = db.query(User).order_by(User.id).all()
    rows = "".join(
        """
        <tr>
            <td>{id}</td>
            <td>{email}</td>
            <td>{full_name}</td>
            <td>{phone}</td>
            <td>{avatar_cell}</td>
            <td>{hashed}</td>
            <td>{active}</td>
        </tr>
        """.format(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            phone=u.phone_number,
            avatar_cell=(
                f'<img src="{u.avatar_url}" alt="avatar" width="40" height="40" style="border-radius:50%" />'
                if u.avatar_url
                else "-"
            ),
            hashed=u.hashed_password,
            active="Sí" if u.is_active else "No",
        )
        for u in users
    )
    html = f"""
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8' />
        <title>Admin Panel</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 2rem; }}
            table {{ border-collapse: collapse; width: 100%; }}
            th, td {{ border: 1px solid #ccc; padding: 0.5rem; text-align: left; }}
            th {{ background: #f4f4f4; }}
        </style>
    </head>
    <body>
        <h1>Usuarios registrados</h1>
        <p>Total: {len(users)}</p>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Email</th>
                    <th>Nombre</th>
                    <th>Teléfono</th>
                    <th>Avatar</th>
                    <th>Hashed Password</th>
                    <th>Activo</th>
                </tr>
            </thead>
            <tbody>
                {rows if rows else '<tr><td colspan="4">Sin usuarios registrados</td></tr>'}
            </tbody>
        </table>
        <p style='margin-top:1rem;'>Actualiza la página para refrescar la tabla o usa <code>/admin/users</code> para JSON.</p>
    </body>
    </html>
    """
    return HTMLResponse(content=html)