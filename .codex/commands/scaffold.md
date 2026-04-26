---
name: scaffold
description: Guide the scaffolding of project infrastructure or a new phase's directory structure
---

Guide the scaffolding of project infrastructure or a new phase's directory structure. This is about setting up the skeleton, not implementing logic.

## Before anything else

1. Re-read AGENTS.md — specifically the Technology Stack, Architecture Principles, and the relevant phase's implementation notes
2. Read docs/MASTER_PLAN.md — find the scaffold tasks (Stage 0.1 for infrastructure, or the relevant phase's first stage)
3. Ask the user: **What are you scaffolding?** Options:
   - `backend` — Full Python backend structure
   - `frontend` — Full React/TypeScript frontend structure
   - `phase N` — Both backend and frontend for a specific phase
   - A specific module path (e.g., `simulation/molecular`, `api/elements`)

## Backend scaffold pattern

When scaffolding Python backend structure, follow this layout:

```
backend/
  pyproject.toml
  src/
    __init__.py
    constants.py              — Universal physical constants (c, k_B, N_A, etc.)
    api/
      __init__.py
      {resource}.py            — One FastAPI router per resource
    models/
      __init__.py
      {scale}/
        __init__.py
        {entity}.py            — Pydantic v2 BaseModel classes
    simulation/
      __init__.py
      {scale}/
        __init__.py
        {engine}.py            — Simulation engine modules
    data/
      __init__.py
      database.py              — SQLAlchemy connection setup
      models/                  — SQLAlchemy ORM models
  data/
    elements/                  — Element property data files
    force_fields/              — Force field parameter files
    pathways/                  — Metabolic pathway SBML files
  tests/
    __init__.py
    simulation/
      {scale}/
        test_{engine}.py       — Mirror of src/simulation/ structure
    api/
      test_{resource}.py
```

Every Python file must include:
- `from __future__ import annotations`
- Full type annotations on all function signatures
- Module-level docstring explaining what it contains

## Frontend scaffold pattern

When scaffolding TypeScript frontend structure:

```
frontend/
  package.json
  tsconfig.json
  src/
    components/
      ui/                      — Reusable UI components (panels, controls)
      three/                   — Three.js/R3F components (renderers, scenes)
    hooks/
      use{Feature}.ts          — Custom hooks
    stores/
      {feature}Store.ts        — Zustand stores
    shaders/
      {name}.vert              — Vertex shaders (separate files, not inline)
      {name}.frag              — Fragment shaders
    types/
      {entity}.ts              — TypeScript interfaces
    workers/
      {name}Worker.ts          — Web Workers (MessagePack decoding, etc.)
    App.tsx
    main.tsx
```

## What NOT to do

- Do not implement simulation logic — just signatures and docstrings
- Do not create documentation files unless the user asks
- Do not install packages — just note what's needed in a comment
- Do not create Docker/CI files unless specifically asked
- Do not scaffold phases the user hasn't asked for

## Verification

After scaffolding, confirm:
- [ ] Every directory has an `__init__.py` (Python) or `index.ts` (TypeScript) where appropriate
- [ ] File naming follows AGENTS.md conventions (snake_case.py, PascalCase.tsx, useCamelCase.ts)
- [ ] No placeholder logic — just proper signatures, type annotations, and docstrings
- [ ] The scaffold is consistent with existing code if any already exists