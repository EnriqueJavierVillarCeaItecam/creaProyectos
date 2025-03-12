'''Modelo de bbdd para entidad'''
from sqlalchemy import Column, Integer
from bbdd.database import Base

class ENTIDAD(Base):
    """
    Modelo de bbdd para entidad
    """
    __tablename__ = 'entidad'
    id = Column(Integer, primary_key = True, index = True)
