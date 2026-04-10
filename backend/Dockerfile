FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for RDKit and scientific packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency file and install
COPY pyproject.toml .
RUN uv sync --no-dev --no-install-project 2>/dev/null || echo "No dependencies to install yet"

# Copy application source
COPY src/ ./src/

# Expose FastAPI port
EXPOSE 8000

# Run FastAPI with uvicorn
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
