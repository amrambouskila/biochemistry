---
name: phase-status
description: Assess the current state of Biochemistry development across the 8-phase roadmap
---

Assess the current state of Biochemistry development across the 8-phase roadmap.

## Before anything else

1. Re-read AGENTS.md — specifically the phase-specific implementation notes and the Definition of Done criteria
2. Read README.md — the full phase definitions and deliverables list
3. Read docs/MASTER_PLAN.md — the task breakdown and gate criteria

## What to check

For each phase (1 through 8), scan the codebase and determine its status:

- **Not started**: No code exists for this phase's deliverables
- **In progress**: Some deliverables exist but the Definition of Done is not met
- **Complete**: All 7 Definition of Done criteria are satisfied

For whichever phase is currently active, go deeper:

1. **Backend simulation**: Which engines/modules exist in `backend/src/simulation/`? Which are missing? Do they define input/output/timestep/spatial resolution per AGENTS.md Architecture Principle #1?
2. **Backend API**: Which routers exist in `backend/src/api/`? Do they use Pydantic v2 models? Are WebSocket endpoints defined?
3. **Frontend renderer**: Does 3D rendering exist? What Three.js patterns are in use (InstancedMesh, LOD, BufferGeometry)?
4. **Frontend UI**: Which React components exist? Do they use Zustand stores correctly?
5. **Tests**: For every module in `backend/src/simulation/`, does a corresponding test exist in `backend/tests/`? Are numerical tests using `np.testing.assert_allclose`?
6. **Data-driven**: Are physical constants in `backend/src/constants.py`? Are element/molecule properties loaded from database/files, not hard-coded?
7. **Validation**: Has any simulation output been compared against published experimental or reference data?

## Output format

Present a table:

| Phase | Status | Backend | Frontend | Tests | Validated |
|-------|--------|---------|----------|-------|-----------|

Then for the active phase, list:
- Next 3 concrete tasks to work on (reference the task ID from docs/MASTER_PLAN.md), ordered by dependency
- Any blockers or architectural decisions that need user input
- Which AGENTS.md sections are most relevant for the next task
