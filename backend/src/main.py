"""Biochemistry backend — FastAPI application entry point."""
from __future__ import annotations

from fastapi import FastAPI

app = FastAPI(
    title="Biochemistry API",
    description="Multi-Scale Molecular & Anatomical Chemistry Simulator",
    version="0.1.0",
)


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}
