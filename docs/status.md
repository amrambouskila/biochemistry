# Status — Biochemistry

## Current Phase: Pre-Phase 1 (Infrastructure)

The project skeleton is fully scaffolded — backend and frontend directories, Docker setup, CI/CD, launcher scripts, CLAUDE.md, and the master build plan are all in place.

## What Exists

- **Backend**: `pyproject.toml` configured with uv, FastAPI, NumPy, SciPy, Numba, RDKit, Pydantic v2, SQLAlchemy async, asyncpg, Redis, msgpack. Source structure under `backend/src/` with `api/`, `models/`, `simulation/`, `data/` directories.
- **Frontend**: React 18 + TypeScript strict + Three.js via R3F + Zustand + Socket.IO. Vite build, pnpm package manager. Source under `frontend/src/`.
- **Infrastructure**: Docker Compose with backend, frontend, PostgreSQL 16, Redis 7. Healthchecks on all services. Launcher scripts (`run_biochemistry.sh`, `run_biochemistry.bat`).
- **CI/CD**: `.gitlab-ci.yml` present.
- **Documentation**: CLAUDE.md (275 lines), README.md (1536 lines with full 8-phase roadmap), `docs/MASTER_PLAN.md` (detailed build order).

## What's Next

- Begin Phase 1, Stage 0.1: Initialize the Python backend (`pyproject.toml` deps install, database seed script for elements from `mendeleev`).
- Implement the element database seeder and the atomic orbital voxel grid computation.
- Get the basic Three.js scene rendering a single sphere before attempting the Bohr model.