from fastapi import FastAPI
from middlewares import cors
from routes.hola import router as hola_router
"""
from asyncio import create_task
from contextlib import asynccontextmanager
Ejecutar cosas durante el arranque
@asynccontextmanager
async def lifespan(app: FastAPI):
        db = session_local()
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
                await load_data_puesto(db)
                await load_data_estado_proyecto(db)
                await load_data_avance(db)
                await load_data_linea_servicio(db)
                await load_data_prioridad(db)
                create_task(ejecutar_periodicamente(CARGA_CLIENTES, load_data_cliente, db))
        yield
app = FastAPI(lifespan = lifespan)
"""

#Crear instancia de fastapi
app = FastAPI()
# Añadimos la configuración de CORS
cors.add(app)

# Incluir las rutas
app.include_router(hola_router)

if __name__ == "__main__":
    from uvicorn import run
    run(app = app, host = "0.0.0.0", port = 8000)
