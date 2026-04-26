---
name: new-engine
description: Guide the creation of a new simulation engine module with proper interface and validation
---

Guide the creation of a new simulation engine module. This is Biochemistry's core pattern — every phase adds engines at a new scale.

## Before anything else

1. Re-read AGENTS.md — specifically Architecture Principle #1 (Multi-Scale from the Start) and the phase-specific notes for the relevant phase
2. Read docs/MASTER_PLAN.md — find the exact task for this engine and check its dependencies
3. Ask the user: **Which engine are you building?** (e.g., "force field", "reaction-diffusion", "coarse-grained MD", "compartmental cell model", "agent-based tissue model", "organ ODE system", "PBPK model")
4. Identify which phase this engine belongs to and read the corresponding phase notes in AGENTS.md

## Engine specification — answer these before writing any code

Every simulation engine MUST define these four things (per AGENTS.md Architecture Principle #1):

1. **Input**: What state does this engine receive? From the scale below or initial conditions?
2. **Output**: What state does this engine produce? For the scale above or visualization?
3. **Timestep**: How much simulated time per computation step? (document units)
4. **Spatial resolution**: What is the smallest resolvable feature? (document units)

Write these down explicitly before proceeding. If any are unclear, ask the user.

## Files to create

For an engine named `{engine_name}` in phase `{phase}`:

1. **Engine module**: `backend/src/simulation/{scale}/{engine_name}.py`
   - `from __future__ import annotations`
   - Full type annotations on all signatures
   - Class with `step(dt, state) -> state` pattern
   - Array shapes documented in docstrings
   - Uses NumPy arrays with explicit dtypes
   - Hot loops decorated with `@jit(nopython=True)` from Numba

2. **Data models**: `backend/src/models/{scale}/{engine_name}.py`
   - Pydantic v2 BaseModel classes for input/output state
   - Document units in field descriptions

3. **Constants**: Add any new physical constants to `backend/src/constants.py`
   - Named, not magic numbers
   - Units documented

4. **Tests**: `backend/tests/simulation/{scale}/test_{engine_name}.py`
   - Test against known analytical solutions or published reference values
   - Use `np.testing.assert_allclose` with documented tolerances
   - Parametrize for multiple conditions where applicable
   - NO mocking of physics calculations

5. **API endpoint** (if this engine needs real-time streaming): `backend/src/api/{engine_name}.py`
   - FastAPI router with Pydantic request/response models
   - WebSocket endpoint using the standard `WSMessage` format
   - Binary serialization for position/velocity arrays

## Verification before finishing

- [ ] Engine defines input/output/timestep/spatial resolution
- [ ] All arrays have explicit dtypes and documented shapes
- [ ] No Python for-loops over particles — all vectorized or Numba-compiled
- [ ] No hard-coded physical constants — all reference `backend/src/constants.py`
- [ ] Test file exists with at least one validation against known results
- [ ] Units are documented on every variable and function
- [ ] The engine can be imported and used standalone (no god-class dependencies)