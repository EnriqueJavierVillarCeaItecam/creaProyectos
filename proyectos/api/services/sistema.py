'''servicios para entidad'''
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from fastapi import Depends, status
from bbdd.database import get_db
from entidades.modelos.entidad import ENTIDAD

"""
Aqui van las dependencias con otras tablas
"""
dependencias = []

async def get_all(db : AsyncSession = Depends(get_db)):
    entidads = await db.execute(select(ENTIDAD).options(*dependencias))
    return entidads.scalars()

