# Versions — Biochemistry

## v0.2.0 — Phase-0 hardening + global-CLAUDE alignment

Closes all audit findings and the broader global-CLAUDE drift found in the re-audit. Minor bump (additive: test infra, CI, dev/prod compose split, constants module, committed R3F protocol, Mermaid seeds).

### Findings closed (from the original audit)

- **Backend Dockerfile**: stripped `--reload` from base CMD; added `HEALTHCHECK` hitting `/health` so compose can gate `depends_on` on `service_healthy`.
- **Backend tests**: added `pytest-cov`; `addopts` enforces `--cov-fail-under=100`; `tests/conftest.py` provides in-process `AsyncClient` via `ASGITransport`; `tests/test_health.py` first green test. All 100% covered.
- **docker-compose**: base file prod-clean (backend healthcheck, frontend `depends_on` long-form with `service_healthy`, no bind-mount); `docker-compose.dev.yml` (new, committed) layers bind-mount + `--reload` for dev.
- **Launchers** (`run_biochemistry.sh` / `.bat`): full §4 contract — `while true` loop, `[r]` restart (non-terminal), `[k]/[q]/[v]` terminal, unrecognized input reprints menu instead of silently tearing down the stack. Both invoke base + dev overlay together.
- **Frontend Vitest**: `vitest`, `@vitest/coverage-v8`, `@testing-library/react`, `@testing-library/jest-dom`, `@testing-library/user-event`, `jsdom` devDeps; `test`/`test:run`/`test:coverage` scripts; `vite.config.ts` `test` block with jsdom + 100% coverage thresholds; `tests/setup.ts` wires `cleanup()` in `afterEach`; `src/App.test.tsx` smoke test.
- **`docs/frontend-protocol.md`** (new): commits R3F disposal/instancing/state-ownership/LOD contract in-tree, since `.claude/` is gitignored. `CLAUDE.md` links to it.

### Global-CLAUDE drift closed in the re-audit

- **CI pipeline** (`.github/workflows/ci.yml`, new): five-stage pipeline (lint → test → coverage gate → build → docker-build) for both backend and frontend; GitHub Actions since origin is on github.com. Coverage gate enforced in-tool.
- **`frontend/eslint.config.js`** (new): flat ESLint config wired for TS + React Hooks + React Refresh + `@typescript-eslint`. `pnpm lint` now passes with "No issues found". DevDeps added: `eslint`, `@eslint/js`, `typescript-eslint`, `eslint-plugin-react-hooks`, `eslint-plugin-react-refresh`, `globals`.
- **`backend/src/constants.py`** (new): CODATA-exact universal constants (Avogadro, Boltzmann, c, e, h, R) with units in docstrings. Mandated by global §3 and project §Data-Driven. `tests/test_constants.py` parametrized validation against CODATA reference values keeps coverage at 100%.
- **Project CLAUDE.md**: mandatory re-read block added at the top per global §3, with workflow pointing at MASTER_PLAN → status → versions → frontend-protocol → source. Charting guidance updated from "recharts or nivo" to Chart.js per global §5.
- **README.md Mermaid seeds**: architecture `graph TD`, phase-flow `flowchart LR`, phase `gantt`, scale-crossing contract `graph LR`.
- **`docs/MASTER_PLAN.md` Mermaid seeds**: system architecture `graph TD`, phase Gantt, module dependency `graph LR` (per global §3's master-plan requirement).
- **`.gitignore`**: added `.pytest_cache/`, `.ruff_cache/`, `.mypy_cache/`, `.coverage`, `htmlcov/`, `coverage.xml`, `frontend/coverage/` — runtime artifacts that were previously drifting into untracked state.

## v0.1.0 — Project Scaffold

- Full project skeleton: backend (Python/FastAPI) + frontend (React/TypeScript/Three.js).
- Docker Compose with PostgreSQL 16, Redis 7, backend, frontend services.
- All services with healthchecks and `depends_on` conditions.
- Launcher scripts (`run_biochemistry.sh`, `run_biochemistry.bat`) with `[k]/[q]/[v]/[r]` loop.
- CLAUDE.md with full multi-scale simulation guidelines.
- README.md with 8-phase roadmap and architecture diagrams.
- `docs/MASTER_PLAN.md` with stage-by-stage build order.
- `.claude/` wiring: hooks, commands, skills.
