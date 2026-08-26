# Versions — Biochemistry

## v0.2.2 — Frontend test-report (JUnit) fix

### Base-image security patch for the alpine runtime stage (2026-08-26)

- **`RUN apk upgrade --no-cache` added to `frontend/Dockerfile`.** The `nginx:alpine` base currently ships
  `libcrypto3`/`libssl3` 3.5.7-r0, which Trivy flags HIGH (`CVE-2026-14456`, an OpenSSL QUIC-server
  DoS, fixed in 3.5.8-r0). The packages come from the base layer, so nothing in the Dockerfile
  installs them and nothing below can remediate them -- the upgrade has to happen at build time.
  Measured directly against the base image: **2 HIGH before the layer, 0 after**.
- **Why this needed a change at all.** `nginx:alpine` measured clean during the 2026-08-24
  base-image sweep. The advisory landed afterwards. A base image being clean is a point-in-time
  observation, not a property, which is precisely why the patch layer belongs in the Dockerfile
  rather than being skipped on the strength of a past scan. This is the alpine counterpart to the
  `apt-get upgrade` layer the Debian bases already carry.
- **Not gated by CI here.** This repo's pipeline has no `trivy image` step, so the layer is
  preventive hardening rather than a fix for a failing stage. The base-image measurement
  above is what supports it; no image scan is claimed for this repo.

**Semver reasoning:** Patch. A build-time base-image security patch. No application code,
dependency, host port, API or data contract, and no test changed.


### CI hardening + dependency remediation (2026-08-24)

- **Semgrep invocation corrected.** The job used `semgrep ci` with `--severity` and `--error`, which that subcommand does not accept — it exits 2 with a usage error before scanning. Switched to `semgrep scan`, which supports both.
- **Release workflow hardened against script injection.** `${{ inputs.bump }}` and `${{ steps.bump.outputs.new_version }}` were interpolated directly into `run:` blocks, where the value becomes shell code. Both now pass through `env:` and are read as quoted shell variables. The input is `type: choice`, so this was not exploitable today — it is the pattern that breaks the moment the input type changes.
- **Base-image security patches in the Dockerfile.** The Debian slim bases ship a `util-linux` that Trivy flags HIGH (CVE-2026-53612..53615, fixed upstream in 2.41.5). Measured directly: `python:3.13-slim` carries 38 fixable HIGH/CRITICAL, `3.12-slim` 36, `3.11-slim` 38, while `nginx:alpine` is clean. These come from the base layer, so an `apt-get upgrade` step is required even where nothing else installs them.
- **`.trivyignore` added** for two findings with no in-image remediation: `CVE-2025-47273` (setuptools 70.3.0) and `GHSA-6v7p-g79w-8964` (msgpack 1.1.2). Both come from pip's vendored manifest in the base image, not from project dependencies — and setuptools 70.3.0 is not even installed (`find` finds nothing; the image ships 84.x). Upgrading pip does not rewrite that manifest. Each entry carries its justification inline.
- **Security headers now actually delivered.** nginx inherits `add_header` from an enclosing level only when the current level declares none of its own, and the cache-control `location` blocks declared their own — silently dropping CSP, `nosniff`, `X-Frame-Options` and `Referrer-Policy` there. Because the SPA resolves through `try_files ... /index.html`, the document itself was served with **zero** security headers. Verified by serving the config in `nginx:alpine` and curling `/`: 0 headers before, 4 after. They are now repeated in each affected block, with a comment explaining why the duplication must stay.
- **Dependency remediation.** 23 bounded overrides in `frontend/package.json`; `pnpm audit --audit-level=high` clean, build and tests pass.
- **vitest pair realigned.** `vitest` and `@vitest/coverage-v8` moved together `^1.6.0 -> ^3.2.6` and the now-redundant `vitest@<3.2.6` override dropped. Overriding only `vitest` leaves the coverage plugin on the old major: pnpm installs that combination and the build still passes, but the runner cannot start.

**On the override bounding.** `pnpm audit --fix` emits one override per advisory with an open-ended target, which lets the resolver jump majors — `>=3.2.6` pulled vitest 4.1.11 and broke its `@vitest/coverage-v8` peer. Each target is therefore capped at its own compatibility line (next major, or next minor for 0.x where semver treats the minor as breaking). The advisory-derived keys are kept verbatim rather than merged: esbuild had two disjoint ranges (`<=0.24.2` and `0.27.3-0.28.0`), and collapsing them to the highest target forced 0.28.2, which cannot lower destructuring to the configured browser targets.


Patch bump (bug fix: the CI `frontend / test + coverage gate` stage was failing — `dorny/test-reporter` reported "No test report files were found").

- **Root cause**: the JUnit reporter was activated via CLI flags forwarded through a pnpm script — `pnpm test:coverage -- --reporter=default --reporter=junit --outputFile.junit=junit-frontend.xml`. On POSIX shells, pnpm 9.15.9's `pnpm run <script> -- <args>` forwarding (a) passes a **literal `--`** to vitest and (b) **escapes every `=` to `\=`**, so vitest received `--reporter\=junit` / `--outputFile.junit\=junit-frontend.xml`. cac never parsed those, the junit reporter never activated, and no report file was written — yet the tests still passed, so the step exited 0 and the failure only surfaced at the downstream reporter step. Windows/PowerShell forwards the same args cleanly, which is why local runs masked it. The backend test job was unaffected because `pytest --junitxml=...` is a direct CLI arg with no pnpm indirection. Verified by reproducing the exact CI command in a `node:20` Linux container (junit reporter silently absent → no file).
- **`frontend/vite.config.ts`**: moved both reporters into `test.reporters: ['default', 'junit']` and added `test.outputFile: { junit: 'junit-frontend.xml' }`. Configuring reporters in-config (not via forwarded CLI flags) is deterministic across shells/OSes, keeps the human-readable console output (`default`), and still emits the JUnit XML — satisfying global-CLAUDE §5's "never junit-only" rule.
- **`.github/workflows/ci.yml`**: the frontend test step is now plain `pnpm test:coverage` (no `-- <args>` forwarding). `dorny/test-reporter`'s `path: frontend/junit-frontend.xml` is unchanged and now resolves.
- **`.gitignore`**: added `junit-*.xml` — the report is now written on every local run too, and is a generated artifact (covers both `junit-frontend.xml` and the backend's `junit-backend.xml`).

### Security documentation (docs-only addition under v0.2.2)

- **`CLAUDE.md` / `AGENTS.md` `<security>` section** (new): applies global-CLAUDE §19 to this repo — mandatory `sast` CI stage between `lint` and `test` (Semgrep + SARIF upload, CodeQL, `pip-audit` / `pnpm audit --audit-level=high`, gitleaks, Trivy `HIGH,CRITICAL` inside `docker-build`; no `continue-on-error`), ruff `S` rules and `eslint-plugin-security` / `eslint-plugin-no-unsanitized` as lint-stage requirements, local-parity commands, an input-boundary inventory (live: `GET /health`, env vars, nginx proxy; planned: REST/WS endpoints, file uploads, parameter loaders, orbital cache, ETL pulls, frontend rendering, Web Worker decoder) with injection classes and required defenses per boundary, and project-specific rules (native-code parse caps/timeouts, no `eval` for expression input, no LLM calls). Self-audit gains a **Security check**; Definition of Done gains criterion #9 (input boundaries injection-safe and documented).
- **`docs/MASTER_PLAN.md`**: Task 0.1.5 now specifies the `lint → sast → test → build → docker-build` pipeline; every phase gate (0.1 through 8) carries two new lines — "SAST stage green — zero HIGH/CRITICAL findings; MEDIUM findings triaged with written justification" and "New input boundaries in this phase are injection-safe and documented in `CLAUDE.md` `<security>`" (with the phase's concrete boundaries named); new Security section with the CI-stage Mermaid diagram.
- **`.codex/commands/pre-commit.md`**: new Check 3 (SAST / security) — local Semgrep + `pip-audit` + `pnpm audit` + gitleaks parity, boundary-inventory check — and a matching `SAST` verdict-table row (now 7 checks).
- **`docs/status.md`**: Security section, rewritten below into Wired / Pending once the wiring landed.
- Documentation-only at the time; the wiring followed in the same unreleased version — see the next subsection.

### Security wiring (under v0.2.2)

- **`.github/workflows/ci.yml`**: new `backend-sast` job (`needs: [backend-lint]`, `permissions: security-events: write`) running CodeQL `python`, `pipx run semgrep scan --config auto --config p/owasp-top-ten --config p/python --config p/docker --severity ERROR --error --include backend` with SARIF upload, `gitleaks/gitleaks-action@v2` on a full-depth checkout, and `uv run --with pip-audit pip-audit`; new `frontend-sast` job (`needs: [frontend-lint]`) running CodeQL `javascript-typescript`, Semgrep with `--include frontend` + SARIF upload, and `pnpm audit --audit-level=high`. `backend-test` and `frontend-test` now carry `needs:` on their respective sast job. Both `docker-build` jobs build with `load: true` and run `aquasecurity/trivy-action@0.28.0` (`HIGH,CRITICAL`, `exit-code: 1`, `ignore-unfixed: true`).
- **`backend/pyproject.toml`**: ruff lint select gains `"S"` (flake8-bandit) with `[tool.ruff.lint.per-file-ignores] "tests/**" = ["S101"]`. `uv run ruff check .` passes with no suppressions.
- **`frontend/eslint.config.js`**: added `eslint-plugin-security` + `eslint-plugin-no-unsanitized` (recommended configs); `pnpm lint` is clean.
- **`frontend/nginx.conf`**: added `Content-Security-Policy` (`default-src 'self'`; `script-src 'self'`; `connect-src 'self' ws: wss:`; `worker-src 'self' blob:`; `object-src 'none'`; `frame-ancestors 'none'`; `style-src 'self' 'unsafe-inline'` for R3F/Chart.js inline style attributes), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, and `client_max_body_size 25m`.
  - **Correction (same version): the headers above were not actually being delivered.** nginx inherits `add_header` from an enclosing level only when the current level declares none of its own, and `/assets/` and `= /index.html` declare their own `add_header Cache-Control`, which silently dropped all four security headers there. Because `location /` resolves the SPA through `try_files ... /index.html`, **the document itself was served with zero security headers** — verified by serving the config in `nginx:alpine` and curling `/`: 0 security headers before, 4 after. The four headers are now repeated inside each affected location block (with a comment explaining why the duplication must stay). `nginx -t` passes on the repaired config.
- **`frontend/package.json`**: added a `sast` script for local parity.
- Patch scope holds: CI, lint configuration, and static-serving headers — no application runtime behavior change. Pending: `.semgrep/` rules.

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
