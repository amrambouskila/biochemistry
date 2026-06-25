# Versions — Biochemistry

## v0.2.2 — Frontend test-report (JUnit) fix

Patch bump (bug fix: the CI `frontend / test + coverage gate` stage was failing — `dorny/test-reporter` reported "No test report files were found").

- **Root cause**: the JUnit reporter was activated via CLI flags forwarded through a pnpm script — `pnpm test:coverage -- --reporter=default --reporter=junit --outputFile.junit=junit-frontend.xml`. On POSIX shells, pnpm 9.15.9's `pnpm run <script> -- <args>` forwarding (a) passes a **literal `--`** to vitest and (b) **escapes every `=` to `\=`**, so vitest received `--reporter\=junit` / `--outputFile.junit\=junit-frontend.xml`. cac never parsed those, the junit reporter never activated, and no report file was written — yet the tests still passed, so the step exited 0 and the failure only surfaced at the downstream reporter step. Windows/PowerShell forwards the same args cleanly, which is why local runs masked it. The backend test job was unaffected because `pytest --junitxml=...` is a direct CLI arg with no pnpm indirection. Verified by reproducing the exact CI command in a `node:20` Linux container (junit reporter silently absent → no file).
- **`frontend/vite.config.ts`**: moved both reporters into `test.reporters: ['default', 'junit']` and added `test.outputFile: { junit: 'junit-frontend.xml' }`. Configuring reporters in-config (not via forwarded CLI flags) is deterministic across shells/OSes, keeps the human-readable console output (`default`), and still emits the JUnit XML — satisfying global-CLAUDE §5's "never junit-only" rule.
- **`.github/workflows/ci.yml`**: the frontend test step is now plain `pnpm test:coverage` (no `-- <args>` forwarding). `dorny/test-reporter`'s `path: frontend/junit-frontend.xml` is unchanged and now resolves.
- **`.gitignore`**: added `junit-*.xml` — the report is now written on every local run too, and is a generated artifact (covers both `junit-frontend.xml` and the backend's `junit-backend.xml`).

## v0.2.1 — Frontend Docker build fix (pnpm pin)

Patch bump (bug fix: the CI `frontend / docker-build` stage was failing).

- **Root cause**: `frontend/Dockerfile` ran `corepack enable && pnpm install` with no pinned pnpm, so corepack fetched pnpm-latest (11.5.2). pnpm 11 `require`s the Node 22 builtin `node:sqlite` and aborts with `ERR_UNKNOWN_BUILTIN_MODULE` on the `node:20-alpine` base image. The non-Docker frontend CI jobs were unaffected because they pin `pnpm/action-setup@v4 → version: 9`.
- **`frontend/package.json`**: added `"packageManager": "pnpm@9.15.9"` — the canonical corepack pin and single source of truth for the pnpm version used by the Docker build and local dev. 9.15.9 is the latest pnpm 9, matches what CI's `version: 9` resolves to, and is compatible with the committed `lockfileVersion: '9.0'` lockfile and with Node 20.
- **`frontend/Dockerfile`**: dropped the `2>/dev/null || pnpm install` fallback, which silently defeated `--frozen-lockfile` by regenerating the lockfile on any mismatch. With pnpm now pinned to the lockfile's generator, `--frozen-lockfile` succeeds deterministically and fails loudly on drift — the correct behavior for a build stage.

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
