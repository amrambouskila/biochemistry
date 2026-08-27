# Status — Biochemistry

## Current Phase: Phase 0 complete — ready for Phase 1, Stage 0.1

v0.2.0 closes all Phase-0 audit findings plus the broader global-CLAUDE.md drift identified in the re-audit. The scaffold is now production-safe, CI-gated, and fully aligned with docs — the next review pass should read as high-fidelity. v0.2.1 unblocks the CI `frontend / docker-build` stage by pinning pnpm to 9.15.9 (see Versions). v0.2.2 fixes the remaining red stage, `frontend / test + coverage gate`: the JUnit reporter was being activated via CLI flags forwarded through `pnpm run … -- …`, which pnpm 9 mangles on POSIX shells (literal `--`, `=`→`\=`), so no report file was produced and `dorny/test-reporter` failed. Reporters now live in `vite.config.ts` and CI runs plain `pnpm test:coverage`; verified in a Linux container. Run `33009850858` then went red on two further stages, both since fixed (see Versions, 2026-08-27): `backend / sast` (`pip-audit` — 11 advisories from a 2.5-month-stale `uv.lock`) and `frontend / docker-build` (`aquasecurity/trivy-action@0.28.0` is a deleted tag from the `CVE-2026-33634` supply-chain response, so the job died at "Set up job"). Every stage those two were blocking has now been reproduced locally against the exact CI commands and passes, including the two Trivy image scans, which had never once executed in CI.

## What Exists

- **Backend**: `pyproject.toml` with uv, FastAPI, NumPy, SciPy, Numba, RDKit, Pydantic v2, SQLAlchemy async, asyncpg, Redis, msgpack, mendeleev. Dev-deps: pytest, pytest-asyncio, pytest-cov, ruff, httpx. Source under `backend/src/` (`api/`, `models/`, `simulation/`, `data/`). `src/constants.py` ships the CODATA-exact universal constants (the ONLY place for numerical literals with physical meaning). Tests: `test_health.py` (FastAPI smoke via `ASGITransport`), `test_constants.py` (CODATA reference validation). Coverage gate wired: `--cov-fail-under=100`, currently 100%.
- **Backend Dockerfile**: prod-mode CMD (no `--reload`); container-level `HEALTHCHECK` hitting `/health`.
- **Frontend**: React 18 + TypeScript strict + Three.js via R3F + Zustand + Socket.IO. Vitest + RTL + jsdom + `@vitest/coverage-v8` at 100% thresholds. `tests/setup.ts` wires `cleanup` in `afterEach` (Vitest does not auto-clean). First smoke test (`src/App.test.tsx`). ESLint flat config (`eslint.config.js`) wired for TS + React Hooks + React Refresh.
- **Infrastructure**: `docker-compose.yml` is prod-clean (backend healthcheck, frontend `depends_on: { backend: { condition: service_healthy } }`). `docker-compose.dev.yml` is the committed dev overlay (bind-mount + `--reload`). Launchers invoke both.
- **Launchers (`run_biochemistry.sh` / `.bat`)**: full global-CLAUDE §4 contract — `while true` loop, `[r]` restart, `[k]/[q]/[v]` terminal, unrecognized input reprints menu without tearing down containers.
- **CI/CD**: `.github/workflows/ci.yml` implements global-CLAUDE §5 five-stage pipeline (lint → test → coverage gate → build → docker-build) for both backend (uv + ruff + pytest + uv build + docker) and frontend (pnpm + eslint + vitest --coverage + vite build + docker). Coverage gate is enforced in-tool (`--cov-fail-under=100` / Vitest 100% thresholds) so a passing test job implies a passing gate. The frontend Docker build pins pnpm via `frontend/package.json`'s `packageManager: pnpm@9.15.9` field (corepack), keeping the image's pnpm in lockstep with the pnpm 9 the non-Docker frontend jobs and the `lockfileVersion: '9.0'` lockfile use.
- **Docs**:
  - `docs/frontend-protocol.md` — canonical R3F disposal/instancing/LOD contract in-tree.
  - `README.md` — Mermaid architecture graph, phase-flow flowchart, phase Gantt, scale-crossing contract diagram (seeded per global §3).
  - `docs/MASTER_PLAN.md` — Mermaid system architecture, phase Gantt, module dependency graph.
  - `CLAUDE.md` (project) — mandatory re-read block at top, workflow pointing at MASTER_PLAN / status / versions / frontend-protocol. Charting guidance aligned with global §5 (Chart.js, not recharts/nivo).

## Security

### Verified state (2026-08-27)

- **Backend dependency set is clean.** `uv.lock` refreshed; `pip-audit` reports no known
  vulnerabilities (was: 11 across `click`, `idna`, `msgpack`, `starlette`). Backend `ruff`,
  `pytest` (100%), `uv build` and Semgrep (145 rules, 0 findings) all re-verified on the new set,
  and the built container reports `healthy` with `/health` → 200.
- **Both Trivy image scans pass — the first time either has been proven.** Measured with Trivy
  **v0.70.0** (the version `trivy-action` v0.36.0 ships) and CI's exact flags
  (`--severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed`, default scanners so secret scanning
  is included): `biochemistry-backend:ci` and `biochemistry-frontend:ci` both **exit 0**.
- **The backend image needed a real fix to get there**, not a suppression: 2 HIGH from
  `setuptools/_vendor/` in the `python:3.11-slim` base (`jaraco.context` 5.3.0 `CVE-2026-23949`,
  `wheel` 0.45.1 `CVE-2026-24049`), cleared by upgrading setuptools to 84.0.0 in the Dockerfile.
- **`.trivyignore` re-validated.** Its two entries are still load-bearing and still correctly
  justified: scanning the backend image without the file reports exactly `CVE-2025-47273`
  (setuptools 70.3.0) and `GHSA-6v7p-g79w-8964` (msgpack 1.1.2), both from pip's vendored manifest
  in the base layer, neither remediable in the Dockerfile.
- **The backend image now installs from `uv.lock`** (`--frozen`), so the dependency set Trivy scans
  is the one `pip-audit` gates. It previously resolved from `pyproject.toml` alone and discarded
  install errors, which could have shipped an empty environment on a green build.
- Frontend re-verified end to end: `pnpm install --frozen-lockfile`, `lint`, `test:coverage`
  (100%, JUnit written), `build`, `pnpm audit --audit-level=high`, Semgrep (94 rules, 0 findings).

### Verified state (2026-08-26)

- **Alpine base-image CVEs patched at build time.** `CVE-2026-14456` (`libcrypto3`/`libssl3`
  3.5.7-r0, HIGH, fixed 3.5.8-r0) is cleared by an `apk upgrade` layer in the runtime stage --
  measured on the base image as 2 HIGH before, 0 after. The base scanned clean two days earlier,
  so the layer exists to stop a future advisory from becoming a pipeline failure.
- **No image scan runs in this repo's CI**, so nothing here was gating; the change is
  preventive and no per-image scan result is claimed.

### Verified state (2026-08-24)

- **Semgrep: clean.** Verified locally by running this repo's own CI command against the working tree (0 findings). The invocation itself was broken before today — `semgrep ci` rejects `--severity`/`--error` and exited 2 without scanning.
- **Dependency audit: clean.** Verified with the repo's own audit command and threshold, after the override/upgrade remediation; install and build re-verified in the CI image.
- **Container scan: base-image CVEs patched** via an `apt-get upgrade` layer, with the two unremediable pip-vendored findings carried in `.trivyignore` with justification.
- **Security headers verified delivered** — confirmed by serving the config in `nginx:alpine` and inspecting the response for `/` (0 headers before the fix, 4 after).

- Not run locally: gitleaks and Trivy are not part of any project toolchain here; both were exercised through their official images during verification, and CI runs them on every pipeline.

Requirements are documented **and wired**. `CLAUDE.md` `<security>` (mirrored in `AGENTS.md`) specifies the mandatory `sast` CI stage, the input-boundary inventory (live today: `GET /health`, `DATABASE_URL`/`REDIS_URL` env vars, nginx `/api/` + `/ws/` proxy), and the per-boundary injection defenses; `docs/MASTER_PLAN.md` carries the SAST + input-boundary gate lines on every phase gate and a Security section with the pipeline diagram; `.codex/commands/pre-commit.md` has a SAST check and verdict row.

Wired (MASTER_PLAN Task 0.1.5):

- `.github/workflows/ci.yml` has `backend-sast` (`needs: [backend-lint]`) and `frontend-sast` (`needs: [frontend-lint]`): CodeQL (`python` / `javascript-typescript`), `pipx run semgrep scan` with per-side `--include` and SARIF upload, `gitleaks/gitleaks-action@v2` (backend job, full-depth checkout), `uv run --with pip-audit pip-audit`, `pnpm audit --audit-level=high`. `backend-test` and `frontend-test` carry `needs:` on their sast job.
- Both `docker-build` jobs build with `load: true` and run `aquasecurity/trivy-action@ed142fd0673e97e23eac54620cfb913e5ce36c25` (`# v0.36.0`, SHA-pinned because of `CVE-2026-33634`; `HIGH,CRITICAL`, `exit-code: 1`, `ignore-unfixed: true`) against `biochemistry-backend:ci` / `biochemistry-frontend:ci`. Both images verified locally at exit 0 with Trivy v0.70.0 and CI's exact flags.
- `backend/pyproject.toml` lint select is `["E", "F", "I", "N", "UP", "ANN", "S"]` with `"tests/**" = ["S101"]`; ruff is clean with no suppressions.
- `frontend/eslint.config.js` extends `security.configs.recommended` + `noUnsanitized.configs.recommended`; lint is clean.
- `frontend/nginx.conf` sends CSP (`connect-src 'self' ws: wss:` for the proxied API/WebSocket; `style-src 'unsafe-inline'` for R3F/Chart.js inline styles), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `client_max_body_size 25m` (sized for PDB uploads).
- `frontend/package.json` has a `sast` script for local parity.

Still pending:

- `.semgrep/` project-rules directory.
- Pydantic `BaseSettings` class for env vars (currently read ad hoc).

## Known Gaps (not in v0.2.0 scope)

- `backend/src/` subdirectories (`api/`, `models/`, `simulation/`, `data/`) are intentionally empty — Phase 1 fills them.
- Project CLAUDE.md is still closer to 300 lines than the "mature 800–2000" target from global §3. That growth is expected as phases ship (each phase adds its own domain rules, pitfalls, and contracts).

## What's Next

**Phase 1, Stage 0.1**: seed the element database from `mendeleev` into PostgreSQL. Create `backend/src/data/database.py` (async SQLAlchemy engine + session factory), `backend/src/models/element.py` (SQLAlchemy ORM + Pydantic schema), `backend/src/data/seed_elements.py` (one-shot migration), and `backend/src/api/elements.py` (REST router). Matching tests under `backend/tests/`. Stage 0.2: atomic orbital voxel-grid precomputation cached to Redis/`.npy`.
