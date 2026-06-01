from __future__ import annotations
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, Boolean, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base

if TYPE_CHECKING:
    from .user import User


class Couple(Base):
    __tablename__ = "parejas"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    nombre: Mapped[str | None] = mapped_column(String(255), nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="CLP", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    members: Mapped[list[CoupleMember]] = relationship(
        back_populates="couple", cascade="all, delete-orphan"
    )
    invitations: Mapped[list[CoupleInvitation]] = relationship(
        back_populates="couple", cascade="all, delete-orphan"
    )


class CoupleMember(Base):
    __tablename__ = "pareja_miembros"
    __table_args__ = (UniqueConstraint("pareja_id", "usuario_id"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    pareja_id: Mapped[int] = mapped_column(
        ForeignKey("parejas.id", ondelete="CASCADE"), nullable=False, index=True
    )
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, index=True
    )
    rol: Mapped[str] = mapped_column(String(20), default="member", nullable=False)
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    couple: Mapped[Couple] = relationship(back_populates="members")
    user: Mapped[User] = relationship(back_populates="couple_memberships")


class CoupleInvitation(Base):
    __tablename__ = "pareja_invitaciones"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    pareja_id: Mapped[int] = mapped_column(
        ForeignKey("parejas.id", ondelete="CASCADE"), nullable=False
    )
    invitado_por: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id"), nullable=False
    )
    email_invitado: Mapped[str] = mapped_column(String(255), nullable=False)
    token: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    estado: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    couple: Mapped[Couple] = relationship(back_populates="invitations")
