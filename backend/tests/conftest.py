"""Shared pytest fixtures for backend tests."""
from __future__ import annotations

from collections.abc import AsyncIterator

import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from src.main import app


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    """In-process async HTTP client wired to the FastAPI app via ASGITransport.

    No live server; no network. Requests go directly through the ASGI app,
    which is the canonical FastAPI async-test pattern.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
