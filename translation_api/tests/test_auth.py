"""
Unit tests for authentication endpoints.
Run with: pytest
"""
import pytest
from httpx import AsyncClient
from main import app


@pytest.mark.asyncio
async def test_register_success():
    """Test successful user registration."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/auth/register",
            json={
                "email": "newuser@test.com",
                "password": "testpass123",
                "display_name": "New User"
            }
        )
        assert response.status_code == 201
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_success():
    """Test successful login."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # First register
        await client.post(
            "/auth/register",
            json={
                "email": "logintest@test.com",
                "password": "testpass123",
            }
        )
        
        # Then login
        response = await client.post(
            "/auth/login",
            json={
                "email": "logintest@test.com",
                "password": "testpass123",
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data


@pytest.mark.asyncio
async def test_login_invalid_credentials():
    """Test login with invalid credentials."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/auth/login",
            json={
                "email": "nonexistent@test.com",
                "password": "wrongpass",
            }
        )
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_current_user():
    """Test getting current user info."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register and get token
        reg_response = await client.post(
            "/auth/register",
            json={
                "email": "currentuser@test.com",
                "password": "testpass123",
                "display_name": "Current User"
            }
        )
        token = reg_response.json()["access_token"]
        
        # Get current user
        response = await client.get(
            "/auth/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "currentuser@test.com"
        assert data["display_name"] == "Current User"

