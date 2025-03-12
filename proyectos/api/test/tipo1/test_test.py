from httpx import AsyncClient
from fastapi import status
from test.conftest import BASE_URL



async def test_funciona_entidad():
    async with AsyncClient(base_url = BASE_URL) as client:
        response = await client.get("/entidad")
        assert response.status_code == status.HTTP_200_OK

