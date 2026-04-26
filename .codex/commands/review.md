---
name: review
description: Review changed code against AGENTS.md standards — read, inspect, report without fixing
---

Review changed code against AGENTS.md standards. This is a verification workflow — read, inspect, report. Do not fix anything automatically.

## Before anything else

1. Re-read AGENTS.md — specifically the Coding Standards section and the Architecture Principles
2. Run `git diff` (or `git diff --cached` if there are staged changes) to identify all changed files
3. Read every changed file in full — do not skim

## Inspection checklist

For each changed file, verify ALL of the following:

### Python files (backend/)
- [ ] `from __future__ import annotations` is present
- [ ] All function signatures have full type annotations
- [ ] Max line length is 120 characters
- [ ] Domain-standard variable names are used (r/positions, v/velocities, f/forces, dt, T, P, C, Q, K_p)
- [ ] NumPy arrays have explicit dtypes (`np.float64` for positions/forces, `np.int32` for indices)
- [ ] No Python `for` loops over atoms/particles in simulation code — must be vectorized NumPy or Numba
- [ ] No Python lists used for numerical data in simulation paths
- [ ] Array shapes documented in docstrings: `positions: ndarray of shape (N, 3)`
- [ ] Uses `scipy.spatial.cKDTree` not `KDTree` for spatial searches
- [ ] Pydantic v2 models for all API schemas
- [ ] No hard-coded physical constants — should reference `backend/src/constants.py`
- [ ] No hard-coded element/molecule properties — should come from database or data files

### TypeScript files (frontend/)
- [ ] Strict TypeScript patterns — no `any`, no implicit types
- [ ] `const` by default, `let` only when reassignment is necessary, never `var`
- [ ] React Three Fiber: declarative R3F components, `useFrame` not `requestAnimationFrame`
- [ ] `useMemo` and `useRef` for Three.js objects — no re-creation on every render
- [ ] Geometries/materials/textures disposed in cleanup functions
- [ ] Custom shaders in `frontend/src/shaders/` as separate files, not inline strings
- [ ] Simulation state in Zustand stores, UI-only state in React component state
- [ ] No Three.js objects stored in React state or Zustand stores

### Architecture
- [ ] Simulation and visualization are separated — backend computes, frontend renders
- [ ] Multi-scale interface is defined if this is a simulation engine (input/output/timestep/spatial resolution)
- [ ] Data flows via REST for setup/queries, WebSocket for real-time streaming
- [ ] Binary serialization (MessagePack/typed arrays) for position/velocity/concentration data, not JSON

### Security
- [ ] No secrets, credentials, API keys, or tokens in the diff
- [ ] No `.env` files modified without user awareness

### Scalability
- [ ] Will this code still work at the next phase's scale? (e.g., 10,000 atoms for Phase 3, 100,000 cells for Phase 5)
- [ ] Is progressive fidelity considered? (full detail → reduced detail → statistical summary → frozen)

## Output format

For any FAIL, list:
- Exact file path and line number
- What the violation is
- What it should be instead
- Severity: **critical** (breaks correctness or security) / **should fix** (violates standards) / **minor** (style or preference)

Also note any **positive patterns** observed — things done well that should be continued.