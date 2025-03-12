'''schemas para entidad'''
from pydantic import BaseModel, ConfigDict


class ENTIDADBase(BaseModel):
    """
    representa un entidad con sus atributos
    :param id: identificador unico.
    :type id: int
    """
    id: int

class ENTIDADCreate(ENTIDADBase):
    pass
class ENTIDADUpdate(ENTIDADBase):
    pass
class ENTIDAD(ENTIDADBase):
    id: int

