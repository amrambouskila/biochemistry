---
name: engine-protocol
description: Proactively applied when creating or modifying any simulation engine in src/simulation/
---

# Simulation Engine Protocol

When you are creating or modifying any file under `backend/src/simulation/`, you are working on a simulation engine. Before writing or editing code, verify that the following protocol is satisfied.

## Before writing any engine code

1. Read `docs/MASTER_PLAN.md` — find the task that corresponds to what you're building. Confirm which phase and stage it belongs to. Check that all prerequisite tasks (dependencies) are complete.

2. Read `AGENTS.md` — specifically Architecture Principle #1 (Multi-Scale from the Start) and the Coding Standards for Python.

3. Identify the four required interface properties and write them as a docstring at the top of the engine class or module BEFORE implementing any logic:
   - **Input**: What state does this engine receive?
   - **Output**: What state does this engine produce?
   - **Timestep**: How much simulated time per step? (include units)
   - **Spatial resolution**: Smallest resolvable feature? (include units)

4. Identify the canonical unit system for this scale (see MASTER_PLAN.md Cross-Phase Concerns). Document units on every variable.

## While writing engine code

- All simulation arrays: NumPy ndarrays with explicit dtypes (`np.float64` for positions/forces, `np.int32` for indices)
- Document array shapes in docstrings: `positions: ndarray of shape (N, 3)`
- No Python `for` loops over particles — use vectorized NumPy or `@jit(nopython=True)` from Numba
- No Python lists for numerical data in simulation paths
- Use `scipy.spatial.cKDTree` (not `KDTree`) for spatial searches
- Physical constants must reference `backend/src/constants.py`, never hard-coded
- Element/molecule/tissue properties must come from database or data files, never hard-coded

## After writing engine code

- Create or update the corresponding test file in `backend/tests/simulation/` mirroring the source path
- At least one test must validate against a known analytical solution or published reference value
- Use `np.testing.assert_allclose` with documented tolerances (not `==`)
- Parametrize tests for multiple conditions where applicable
- No mocking of physics calculations