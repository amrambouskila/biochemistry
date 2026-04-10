# CLAUDE.md — AI Assistant Guidelines for Biochemistry

## Project Identity

**Biochemistry** (Multi-scale Molecular & Anatomical Chemistry Simulator) is a multi-phase project to build a 3D biological simulation platform spanning atoms to organisms. The README.md contains the full roadmap with 8 phases. This file provides guidelines for any AI assistant (Claude or otherwise) helping build this project.

---

## Critical Context

This project simulates reality at multiple scales. Every decision — data model, algorithm, rendering approach — must be evaluated through the lens of **"will this still work when we scale up to the next phase?"** A molecule renderer that can't handle 10,000 atoms is useless by Phase 3. A cell model that requires 10 minutes per simulated second is useless by Phase 5. Performance and scalability are not afterthoughts — they are core requirements from day one.

---

## Technology Stack (Non-Negotiable)

### Frontend
- **React.js 18+** with **TypeScript** (strict mode)
- **Three.js** via **@react-three/fiber** and **@react-three/drei**
- **WebGL 2.0** (with WebGPU as an upgrade path for compute shaders)
- **Zustand** for state management
- **Socket.IO** (client) for real-time simulation data streaming
- **pnpm** as the package manager

### Backend
- **Python 3.11+**
- **FastAPI** (async, with WebSocket support)
- **NumPy** for all numerical computation
- **Numba** (`@jit(nopython=True)`) for hot loops in simulation code
- **SciPy** for ODE/PDE solvers, spatial algorithms
- **RDKit** for cheminformatics (SMILES parsing, conformer generation, molecular properties)
- **Pydantic v2** for all data models and API schemas
- **uv** as the Python package manager
- **pytest** for testing

### Infrastructure
- **PostgreSQL** for persistent data (elements, molecules, substances, organisms)
- **Redis** for caching and real-time pub/sub
- **Docker** and **docker-compose** for all services

**Do not introduce alternative technologies without explicit approval.** No Flask, no Django, no Vue, no Angular, no Babylon.js, no Pandas for computation (Pandas is OK for data loading only, never for simulation math).

---

## Architecture Principles

### 1. Multi-Scale from the Start
Every simulation engine must define:
- What is its **input** (state from the scale below or initial conditions)?
- What is its **output** (state to the scale above or visualization data)?
- What is its **timestep** (how much simulated time per computation step)?
- What is its **spatial resolution** (smallest resolvable feature)?

Engines at different scales communicate through well-defined interfaces. A cellular engine doesn't need to know how the molecular engine works internally — it just receives concentrations and reaction rates.

### 2. Separation of Simulation and Visualization
The backend computes. The frontend renders. The backend should be fully functional without any frontend (testable via API calls and scripts). The frontend should be able to render pre-computed data without a live backend connection (for demos, testing, and offline use).

Data flows from backend to frontend via:
- **REST API** for setup, configuration, and queries (one-time requests)
- **WebSocket** for real-time simulation state streaming (continuous updates)

Simulation state is serialized as binary (MessagePack or Protocol Buffers), not JSON. JSON is only used for metadata, configuration, and small payloads. Position arrays, velocity arrays, and concentration grids must be transmitted as typed arrays.

### 3. Progressive Fidelity
Not everything needs to be simulated at maximum detail all the time. The system should support multiple fidelity levels for each component:

- **Full detail**: All physics, all atoms, all reactions. Used for the region of interest.
- **Reduced detail**: Simplified physics, coarse-grained representation. Used for context around the region of interest.
- **Statistical summary**: Just the average concentrations and rates. Used for distant regions.
- **Frozen/cached**: Pre-computed state, no active simulation. Used for inactive regions.

The user's camera position and zoom level determine which regions get which fidelity level. The backend must support dynamically upgrading and downgrading fidelity for regions.

### 4. Data-Driven, Not Hard-Coded
Physical constants, element properties, force field parameters, enzyme kinetics, organ physiological parameters — all of these come from data files or databases, never from hard-coded values in simulation code.

- Element data: loaded from database (seeded from `mendeleev` + custom extensions)
- Force field parameters: loaded from parameter files (UFF, MARTINI, AMBER formats)
- Metabolic pathways: loaded from SBML files (importable from BioModels database)
- Organ physiology: loaded from organism definition files (YAML)
- Substance properties: loaded from substance database (seeded from PubChem, DrugBank, CompTox)

The only hard-coded numbers should be universal physical constants (speed of light, Boltzmann constant, Avogadro's number, etc.), and even these should be in a `constants.py` module, not scattered through the code.

---

## Coding Standards

### Python (Backend)

**Style:**
- Follow PEP 8. Use `ruff` for linting and formatting.
- Maximum line length: 120 characters.
- Use type hints everywhere. All function signatures must have full type annotations.
- Use `from __future__ import annotations` in every module.

**Naming:**
- Modules: `snake_case.py`
- Classes: `PascalCase`
- Functions and methods: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Private attributes/methods: `_leading_underscore`
- Simulation variables should use domain-standard names where possible:
  - `r` or `positions` for particle positions (not `coords` or `xyz`)
  - `v` or `velocities` for particle velocities
  - `f` or `forces` for forces
  - `dt` for timestep
  - `T` for temperature
  - `P` for pressure
  - `C` or `concentration` for concentration (not `conc` or `amount`)
  - `Q` for volumetric flow rate
  - `K_p` for partition coefficient

**Numerical Code:**
- All simulation arrays must be NumPy ndarrays with explicit dtypes (prefer `np.float64` for positions/forces, `np.int32` for atom types/indices).
- Never use Python lists for numerical data in simulation loops. Convert to NumPy arrays at the boundary.
- Never use Python `for` loops over atoms/particles in simulation code. Use vectorized NumPy operations or Numba-compiled functions.
- When a function operates on arrays, document the expected shapes in the docstring: `positions: ndarray of shape (N, 3)`.
- Use `scipy.spatial.cKDTree` (not `KDTree`) for spatial neighbor searches — it's the C-accelerated version.

**FastAPI:**
- All API routes go in `src/api/` with one router per resource (e.g., `elements.py`, `molecules.py`, `simulation.py`).
- Use Pydantic models for all request/response bodies.
- Use dependency injection for database sessions and simulation engine instances.
- WebSocket endpoints use a consistent message format:
  ```python
  class WSMessage(BaseModel):
      type: str          # "frame", "event", "error", "config"
      timestamp: float   # simulation time
      payload: bytes     # MessagePack-encoded data
  ```

**Testing:**
- Every module in `src/simulation/` must have a corresponding test module in `tests/`.
- Numerical tests should use `np.testing.assert_allclose` with appropriate tolerances (not `==`).
- Parametrize tests for multiple elements/molecules/conditions where applicable.
- Integration tests for each API endpoint.
- No mocking of physics calculations — test against known analytical solutions or published reference values.

### TypeScript (Frontend)

**Style:**
- Use strict TypeScript (`"strict": true` in tsconfig).
- Use ESLint with the recommended Three.js/React configurations.
- Use `const` by default, `let` only when reassignment is necessary, never `var`.

**Naming:**
- Components: `PascalCase.tsx`
- Hooks: `useCamelCase.ts`
- Stores: `camelCaseStore.ts`
- Shaders: `camelCase.vert`, `camelCase.frag` (or `.glsl`)
- Types/interfaces: `PascalCase` (prefer `interface` over `type` for object shapes)

**Three.js / React Three Fiber:**
- Prefer declarative R3F components over imperative Three.js code.
- Use `useFrame` for per-frame updates, not `requestAnimationFrame`.
- Use `useMemo` and `useRef` to avoid re-creating Three.js objects on every render.
- Dispose of geometries, materials, and textures in cleanup functions. Memory leaks in Three.js are the #1 cause of frontend performance degradation.
- All custom shaders go in `src/shaders/` as separate files, not inline strings.
- Use `THREE.InstancedMesh` for rendering more than ~100 identical objects (atoms, cells).
- Use `THREE.BufferGeometry` with `THREE.BufferAttribute` for custom geometry — never use the old `Geometry` class.
- LOD (Level of Detail) must be implemented for any scene with more than 10,000 visible objects.

**State Management:**
- Use Zustand stores for simulation state (atom positions, concentrations, vital signs).
- Keep React component state minimal — UI-only state (panel open/closed, selected tab).
- Never store Three.js objects (meshes, geometries, materials) in React state or Zustand stores. Use refs.

**WebSocket Communication:**
- Use Socket.IO client for WebSocket connections.
- Decode binary payloads (MessagePack) in a Web Worker to avoid blocking the main thread.
- Implement a frame buffer: accumulate incoming simulation frames and interpolate between them for smooth rendering even if the backend sends frames at irregular intervals.

---

## Phase-Specific Implementation Notes

### Phase 1: Atomic Simulator
- Start the backend by seeding the element database. Write a migration script that pulls from `mendeleev` and inserts into PostgreSQL.
- The orbital voxel grid computation is the most CPU-intensive part. Precompute all orbitals for all elements up to n=4 and cache in Redis or as .npy files.
- For the frontend, get a basic Three.js scene rendering a single sphere before attempting the Bohr model or electron cloud. Confirm the React ↔ Three.js integration works before adding complexity.
- The interactive periodic table is a standard React component — no Three.js needed. Build it as a separate component that communicates with the 3D viewport via Zustand store.

### Phase 2: Molecular Simulator
- Use RDKit for all molecular structure work. Do not reimplement SMILES parsing, conformer generation, or property calculation — RDKit is battle-tested and handles edge cases.
- The force field engine is the most important backend code in the entire project. If it's wrong, everything built on top of it will be wrong. Validate obsessively:
  - Bond lengths for simple molecules (H₂: 0.74Å, O₂: 1.21Å, N₂: 1.10Å)
  - Bond angles for water (104.5°), methane (109.5°)
  - Energy conservation during MD simulation (total energy should fluctuate < 0.1% over 10,000 steps in NVE ensemble)
- WebSocket frame streaming: send position arrays as Float32Arrays, not JSON arrays of numbers. A 10,000-atom molecule at 30fps generates 10,000 × 3 × 4 bytes × 30 = 3.6 MB/s. With JSON, this would be ~10x larger and much slower to parse.

### Phase 3: Organelle Simulator
- This is the hardest phase architecturally because it introduces multi-scale coupling. Spend time designing the interfaces between scales before writing simulation code.
- The coarse-grained engine is essentially the same code as the all-atom engine (Phase 2) with different parameters. Refactor the MD engine to be parameter-agnostic — it takes arrays of positions, masses, and force field parameters, and it doesn't care if they represent atoms or CG beads.
- For the reaction-diffusion engine, start with the particle-based model (it's more intuitive and easier to visualize) and add the PDE solver later for high-concentration species.
- Organelle geometry: use signed distance functions (SDFs) for procedural shapes. A mitochondrion is approximately a capped cylinder (outer membrane) with an internal surface that folds inward (cristae). An SDF for this can be composed from primitive shapes.

### Phase 4: Cellular Simulator
- Do not attempt to simulate 42 million protein molecules individually. Use a compartmental model where each compartment (cytoplasm, nucleus, mitochondria, ER, etc.) has concentrations of key molecules, and transport between compartments is modeled by rate equations.
- The Gillespie algorithm for gene expression can be slow for large gene regulatory networks. Use the tau-leaping approximation for efficiency (takes larger timesteps by firing multiple reactions simultaneously when copy numbers are high enough).
- The cell dashboard is a React UI challenge, not a simulation challenge. Use a charting library (recharts or nivo) for the graphs.

### Phase 5: Tissue Simulator
- Agent-based modeling (ABM) is inherently serial (each agent's behavior depends on its neighbors), which makes it hard to vectorize. Use NumPy structured arrays and operate on all agents of the same type simultaneously where possible. For example, all fibroblasts secrete collagen at the same rate, so compute all their secretion contributions in one vectorized operation.
- Blood vessel networks: start with manually defined vessel trees for specific tissue types (e.g., a liver lobule has a known vascular architecture). Procedural vessel generation (L-systems or constrained optimization) can come later.
- Cell rendering at this scale: use `THREE.Points` with custom shaders (point sprites) for cells, not individual meshes. Each point is a circle with a color (by cell type) and size (by cell volume). This handles 100,000+ cells at 60fps.

### Phase 6: Organ Simulator
- Anatomical meshes are large (1-10MB per organ as GLTF). Lazy-load them — don't load all organs at startup.
- Organ physiology models should be implemented as standalone ODE systems that can be tested independently of the rest of the simulator. Each organ module has a `step(dt, inputs) -> outputs` method where inputs/outputs are blood concentrations and neural/hormonal signals.
- For the lungs, the branching airway tree can be generated procedurally using an L-system with parameters from Weibel's lung morphometry model (23 generations, specific branching angles and diameter ratios at each generation).

### Phase 7: Whole Body Simulator
- The PBPK model is computationally trivial compared to earlier phases — it's ~20 coupled ODEs. The difficulty is parameterization (getting all the tissue volumes, blood flows, partition coefficients, and clearances correct).
- Use the Open Systems Pharmacology (OSP) platform's published human PBPK parameters as a starting point. They've done the hard work of compiling physiological reference values for humans of different ages, sexes, and body compositions.
- The seamless zoom is the biggest frontend challenge. Implement it as a series of scene transitions triggered by camera distance thresholds. When the camera crosses a threshold, fade in the next level of detail and fade out the current one. Pre-load the next level's data before the threshold is reached.
- The cigarette simulation timeline described in the README should be implementable as a scripted scenario: a sequence of substance introductions at specific times with predefined camera movements and narration text.

### Phase 8: Universal Organism Simulator
- Start with allometric scaling — it gives you 80% of the answer for free. Heart rate ∝ M^(-0.25), metabolic rate ∝ M^(0.75), blood volume ∝ M^(1.0), etc. Given a body mass, predict all major physiological parameters.
- The organism definition YAML schema should be designed carefully — it's the core data model of Phase 8. Use JSON Schema for validation.
- For the substance database, prioritize depth over breadth. It's better to have 100 well-parameterized substances (complete ADME + pharmacodynamics) than 10,000 with only molecular weight and LogP.

---

## Common Pitfalls to Avoid

1. **Premature optimization**: Don't write CUDA code in Phase 1. Don't use WebGPU compute shaders for 10 atoms. Optimize when profiling reveals a bottleneck, not before. NumPy + Numba will carry you through Phases 1-4 at minimum.

2. **Reinventing wheels**: Don't write a molecular mechanics force field from scratch when OpenMM exists. Don't write a SMILES parser when RDKit exists. Don't write a 3D rendering engine when Three.js exists. Use existing tools and focus your effort on the multi-scale integration, which is what makes this project unique.

3. **Skipping validation**: Every simulation module must be validated against known results before building the next phase on top of it. An unvalidated force field will produce garbage molecular dynamics, which will produce garbage cellular behavior, which will produce garbage tissue dynamics. Errors compound across scales.

4. **Over-modeling biology**: You don't need to simulate every known metabolic pathway. Start with the major pathways (glycolysis, TCA, OxPhos, basic amino acid and nucleotide synthesis) and add more only when a specific simulation requires them. The human metabolic network has 13,000+ reactions — you will never model all of them.

5. **Under-estimating frontend complexity**: 3D web rendering is harder than it looks. Memory management (disposing Three.js objects), performance (draw call batching, instancing), and shader writing are all specialized skills. Budget significant time for the frontend.

6. **Ignoring units**: Biophysics uses a chaotic mix of units (Ångströms, nanometers, micrometers, millimeters, meters; femtoseconds, milliseconds, seconds, minutes; daltons, kilograms; kJ/mol, kcal/mol, eV). Define a canonical unit system for each scale and convert at boundaries. Document units in every variable and function.

7. **Monolithic architecture**: Each phase's backend should be an independent module that can be imported and used standalone. Don't create a god class that does everything. The PBPK engine should work without the MD engine, and vice versa.

---

## Definition of Done (Per Phase)

A phase is complete when:

1. All backend deliverables have passing unit and integration tests.
2. All frontend deliverables render correctly and are interactive.
3. The backend API is documented (FastAPI auto-generates OpenAPI docs).
4. A demo scenario can be run end-to-end (e.g., Phase 2: load caffeine from SMILES, run 1000 steps of MD, view in ball-and-stick mode).
5. Performance benchmarks are recorded (simulation speed, rendering FPS).
6. The zoom transition from this phase to the previous phase's detail level works seamlessly.
7. At least one validation test compares simulation output against published experimental or reference data.

---

## How to Ask Claude (or Any AI) for Help on This Project

When working on a specific task, provide:

1. **Which phase** you're working on.
2. **Which component** (backend simulation, backend API, frontend renderer, frontend UI).
3. **What you've already built** (list existing modules/files).
4. **What specific thing** you're trying to build or fix.
5. **What you've tried** that didn't work (if applicable).

Example good prompt:
> "I'm working on Phase 2, backend force field engine. I have the bond stretching and angle bending terms working (in `src/simulation/molecular/force_field.py`). I need to implement the Lennard-Jones non-bonded interaction term. My molecule has 500 atoms and I need it to run at > 1000 steps/second on CPU. How should I implement the neighbor list for efficient pairwise distance calculation?"

Example bad prompt:
> "Help me build the molecular simulator."

The more context you provide, the more useful the assistance will be.
