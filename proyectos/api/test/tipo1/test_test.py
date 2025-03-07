from httpx import AsyncClient
from fastapi import status



async def test_funciona():
    async with AsyncClient(base_url = "http://localhost:8000") as client:
        response = await client.get("/")
        assert response.status_code == status.HTTP_200_OK

