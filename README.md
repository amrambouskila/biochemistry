# Biochemistry — Multi-Scale Molecular & Anatomical Chemistry Simulator

## Vision

Biochemistry is an ambitious, multi-scale biological simulation platform that models reality from individual atoms all the way up to complete living organisms. The ultimate goal is to allow a user to introduce any substance — food, drink, medication, toxin, carcinogen, or environmental factor — into a virtual organism and watch, in real-time 3D, how that substance propagates through the body and affects biological systems at every level of organization: atomic, molecular, organelle, cellular, tissue, organ, organ system, and whole organism.

**The defining use case:** A user selects "cigarette smoke" and watches as carbon monoxide molecules travel through the virtual lungs, cross alveolar membranes, bind to hemoglobin in red blood cells displacing oxygen, while simultaneously benzene molecules are absorbed into the bloodstream, transported to the liver, metabolized by cytochrome P450 enzymes into reactive intermediates that form DNA adducts in hepatocytes — all visualized from the macro scale of lungs and blood vessels down to the nano scale of individual molecular interactions.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Browser)                          │
│                                                                     │
│  React.js Application                                               │
│  ├── Three.js / WebGL Rendering Engine                              │
│  │   ├── Atomic-scale renderer (ball-and-stick, space-filling)      │
│  │   ├── Molecular-scale renderer (ribbon diagrams, surfaces)       │
│  │   ├── Cellular-scale renderer (organelle meshes, membranes)      │
│  │   ├── Tissue-scale renderer (instanced cell clusters)            │
│  │   ├── Organ-scale renderer (anatomical meshes, cutaways)         │
│  │   └── Organism-scale renderer (full body with LOD system)        │
│  ├── UI Controls (substance selector, simulation controls, HUD)     │
│  ├── Camera System (seamless zoom from macro to nano)               │
│  └── WebSocket client for real-time simulation data                 │
│                                                                     │
├─────────────────────────── WebSocket / REST ────────────────────────┤
│                                                                     │
│                        BACKEND (Python)                             │
│                                                                     │
│  FastAPI Server                                                     │
│  ├── Simulation Engine                                              │
│  │   ├── Atomic Simulator (NumPy / Numba / GPU-accelerated)         │
│  │   ├── Molecular Dynamics Engine                                  │
│  │   ├── Reaction-Diffusion Solver                                  │
│  │   ├── Cellular Automata Engine                                   │
│  │   ├── Continuum Mechanics Solver (tissue/organ)                  │
│  │   ├── Pharmacokinetic (PBPK) Model Engine                        │
│  │   └── Multi-Scale Coupler (bridges between scales)               │
│  ├── Data Layer                                                     │
│  │   ├── Periodic Table Database                                    │
│  │   ├── Molecular Structure Database (PDB, SDF, SMILES)            │
│  │   ├── Protein Structure Database                                 │
│  │   ├── Metabolic Pathway Database                                 │
│  │   ├── Cell Type Registry                                         │
│  │   ├── Tissue Composition Database                                │
│  │   ├── Organ Anatomy Database                                     │
│  │   └── Substance Effects Database                                 │
│  └── API Layer                                                      │
│      ├── REST endpoints for setup, configuration, queries           │
│      └── WebSocket endpoints for real-time simulation streaming     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Frontend
| Technology | Purpose |
|---|---|
| **React.js 18+** | UI framework, component architecture, state management |
| **Three.js** | 3D rendering engine built on WebGL |
| **@react-three/fiber** | React renderer for Three.js (declarative 3D scenes) |
| **@react-three/drei** | Helper components (cameras, controls, shaders, LOD) |
| **WebGL 2.0 / WebGPU** | GPU-accelerated rendering (WebGPU for compute shaders in later phases) |
| **GLSL / WGSL Shaders** | Custom shaders for molecular surfaces, membranes, volumetric effects |
| **Zustand** | Lightweight state management for simulation state |
| **Socket.IO client** | Real-time bidirectional communication with backend |
| **Web Workers** | Offload front-end computation (spatial indexing, LOD decisions) |
| **TypeScript** | Type safety across the entire frontend |

### Backend
| Technology | Purpose |
|---|---|
| **Python 3.11+** | Primary backend language |
| **FastAPI** | Async HTTP + WebSocket server |
| **NumPy** | Core numerical computation (vectorized math, linear algebra) |
| **Numba** | JIT compilation of hot simulation loops to machine code |
| **CuPy** (optional) | GPU-accelerated NumPy for CUDA-capable systems |
| **SciPy** | ODE/PDE solvers, spatial algorithms (KD-trees, Voronoi) |
| **RDKit** | Cheminformatics (molecular parsing, conformer generation, fingerprints) |
| **OpenMM** (optional) | GPU-accelerated molecular dynamics for Phase 2+ |
| **Pydantic** | Data validation and serialization for API models |
| **Redis** | Caching simulation state, pub/sub for multi-client sync |
| **PostgreSQL** | Persistent storage for substance databases, user sessions |
| **Celery** | Background task queue for long-running simulations |
| **Docker** | Containerized deployment of all services |

---

## Phase Roadmap

This project is divided into 8 major phases. Each phase builds on the previous one. Every phase is independently useful and demonstrable — you do not need to complete all phases to have a working product.

---

## Phase 1: Atomic Simulator

### Goal
Build a fully interactive 3D atomic simulator where users can explore individual atoms from the periodic table, visualize their electron configurations, manipulate isotopes, and observe fundamental atomic properties. This is the bedrock upon which every subsequent phase is built.

### What Gets Built

#### Backend — Atomic Data Engine

**1.1 Periodic Table Data Model**

Create a comprehensive data model for every element in the periodic table. This is not just a lookup table — it's a physics-accurate representation of each atom that will be used for all downstream calculations.

```
Data per atom:
- Atomic number (Z)
- Symbol, name, group, period, block (s/p/d/f)
- Atomic mass (standard and per-isotope)
- Electron configuration (full and abbreviated)
- Electronegativity (Pauling, Allen, and Mulliken scales)
- Ionization energies (1st through nth)
- Electron affinity
- Atomic radius (empirical, calculated, van der Waals, covalent)
- Oxidation states (common and exhaustive)
- Melting point, boiling point, density, phase at STP
- Crystal structure
- Magnetic ordering
- Thermal conductivity, specific heat capacity
- Isotope data (mass number, natural abundance, half-life, decay mode)
- Spectral emission lines (wavelengths for visualization)
- Nuclear binding energy per nucleon
```

**Implementation approach:**
- Use the `mendeleev` Python package as a starting data source, but build your own Pydantic models on top of it so you own the schema and can extend it.
- Store all data in a PostgreSQL database with a well-indexed schema so queries like "give me all elements with electronegativity > 3.0" are fast.
- Expose via FastAPI REST endpoints: `GET /api/v1/elements`, `GET /api/v1/elements/{symbol}`, `GET /api/v1/elements/{symbol}/isotopes`, etc.

**1.2 Atomic Physics Calculations**

Build a calculation engine that can compute derived atomic properties on the fly:

- **Electron shell populations**: Given an element, compute exactly which shells and subshells contain electrons, how many, and their quantum numbers (n, l, ml, ms).
- **Orbital shapes**: Compute the probability density functions for hydrogen-like orbitals (1s, 2s, 2p, 3s, 3p, 3d, etc.) using the spherical harmonics and radial wave functions. These are the actual quantum mechanical wave functions — the shapes will be rendered in 3D on the frontend.
- **Ionization cascades**: Given an atom and a number of electrons to remove, compute the resulting ion, its new electron configuration, and the total energy required.
- **Isotope stability**: Given an isotope, compute its binding energy per nucleon, predict stability, and if unstable, its decay chain.
- **Spectral lines**: Compute emission/absorption wavelengths from energy level transitions using the Rydberg formula and quantum defect corrections.

**Implementation approach:**
- All heavy math in NumPy. The wave function calculations involve spherical harmonics (`scipy.special.sph_harm`) and associated Laguerre polynomials (`scipy.special.assoc_laguerre`).
- Precompute orbital probability density grids (e.g., 64x64x64 voxel grids) and cache them. These grids get sent to the frontend for volume rendering.
- FastAPI endpoints: `POST /api/v1/atoms/orbitals` (returns voxel grid), `POST /api/v1/atoms/ionize`, `POST /api/v1/atoms/spectrum`.

**1.3 Atom State Machine**

Each atom instance in a simulation needs to track mutable state:

```
AtomState:
- element: Element (immutable reference)
- isotope: Isotope (which isotope this specific atom is)
- charge: int (ionization state, 0 = neutral)
- position: Vector3 (x, y, z in whatever coordinate system the current scale uses)
- velocity: Vector3 (for dynamics)
- spin: float (for magnetic simulations, future use)
- bonds: List[BondReference] (connections to other atoms)
- excitation_state: int (which energy level the outermost electron is in)
```

This state machine is the object that persists throughout the simulation. When we move to Phase 2 (molecules), atoms don't disappear — they become constituents of molecules, retaining their identity.

#### Frontend — Atomic Visualizer

**1.4 3D Atom Renderer**

Build a Three.js scene that can render a single atom in multiple visualization modes:

- **Bohr model**: Concentric rings representing electron shells, with small spheres (electrons) orbiting on them. Animated orbital motion. The nucleus is a cluster of protons (red) and neutrons (blue). This is scientifically inaccurate but pedagogically useful and visually striking.
- **Electron cloud model**: Render the actual quantum mechanical orbital shapes as semi-transparent isosurfaces or volumetric fog. Use the probability density grids computed by the backend. A 1s orbital appears as a sphere, 2p orbitals appear as dumbbells, 3d orbitals appear as clover shapes, etc. Color-code by phase (positive/negative wave function values).
- **Space-filling model**: A single sphere representing the van der Waals radius. Color-coded by CPK convention. This is the mode used when zoomed out to see many atoms.

**Implementation approach:**
- Use `@react-three/fiber` for the React-Three.js integration.
- For the Bohr model: `THREE.RingGeometry` for shells, `THREE.SphereGeometry` for particles, animate electron positions along circular paths using `useFrame`.
- For electron clouds: Use `THREE.DataTexture3D` to upload the voxel grid from the backend, then render with a custom ray-marching fragment shader. The shader steps through the 3D texture and accumulates opacity based on probability density. This is the most technically challenging rendering in Phase 1.
- For space-filling: Simple `THREE.SphereGeometry` with instanced rendering (for when many atoms are on screen).

**1.5 Interactive Periodic Table**

Build a full interactive periodic table as a React component:

- Standard 18-column layout with lanthanides/actinides separated below.
- Each element cell is clickable and shows: symbol, atomic number, atomic mass, and a color-coded background by category (alkali metal, halogen, noble gas, etc.).
- Hovering over an element shows a tooltip with key properties.
- Clicking an element loads it into the 3D viewport as a full atom visualization.
- Filter controls: filter by phase at STP, by electronegativity range, by block, by metallic character.
- A search bar that matches by name, symbol, or atomic number.

**1.6 Atom Inspector Panel**

A sidebar panel that shows all properties of the currently selected atom:

- Electron configuration with visual shell diagram
- All radii (atomic, covalent, van der Waals, ionic) as concentric circles
- Ionization energy graph (1st, 2nd, 3rd, etc.)
- Spectral emission lines as a visual spectrum bar (colored lines on a dark background)
- Isotope table with abundance chart
- Toggle between visualization modes (Bohr, cloud, space-filling)

### Deliverables for Phase 1
- [ ] Backend: Periodic table data model and database, seeded with all 118 elements
- [ ] Backend: Atomic physics calculation engine (orbitals, ionization, spectra)
- [ ] Backend: REST API endpoints for all atomic data and computations
- [ ] Frontend: Three.js atomic renderer with 3 visualization modes
- [ ] Frontend: Interactive periodic table component
- [ ] Frontend: Atom inspector panel
- [ ] Integration: Frontend fetches data from backend, renders atoms in real-time
- [ ] Testing: Unit tests for all calculation functions, integration tests for API

### Key Technical Challenges
1. **Volume rendering of orbitals** — Ray-marching shaders in WebGL are non-trivial. Start with a simple implementation (marching cubes to extract isosurfaces as meshes) and upgrade to full volume rendering later.
2. **Performance of orbital computation** — Computing a 64^3 voxel grid for each orbital is CPU-intensive. Use NumPy vectorization (compute the entire grid at once, not voxel-by-voxel) and cache aggressively.
3. **Accurate electron configurations** — Elements like Chromium (Cr) and Copper (Cu) have irregular configurations. Don't compute these from first principles — use the known empirical configurations from the `mendeleev` database.

---

## Phase 2: Molecular Simulator

### Goal
Combine atoms into molecules. Build a molecular dynamics engine that simulates how atoms bond, vibrate, rotate, and interact. Visualize molecules in 3D with accurate geometry, bond angles, and real-time dynamics. Support arbitrary molecules specified by SMILES strings, molecular formulas, or PDB files.

### What Gets Built

#### Backend — Molecular Engine

**2.1 Chemical Bonding System**

Implement a full bonding model that handles:

- **Covalent bonds**: Single, double, triple. Bond length determined by the sum of covalent radii, modulated by bond order. Bond energy from empirical tables (C-C: 346 kJ/mol, C=C: 614 kJ/mol, C≡C: 839 kJ/mol, etc.).
- **Ionic bonds**: Formed when electronegativity difference > ~1.7. Model as coulombic attraction between ions. Track electron transfer.
- **Metallic bonds**: Delocalized electron sea model (needed later for metallic nanoparticles, not critical in early phases).
- **Hydrogen bonds**: Weak intermolecular bonds between a hydrogen bonded to an electronegative atom (N, O, F) and another electronegative atom. Critical for water, DNA, protein folding.
- **Van der Waals forces**: London dispersion forces modeled via Lennard-Jones potential. These are always present between all atom pairs.
- **Coordinate (dative) bonds**: One atom donates both electrons. Important for transition metal complexes.

```python
# Core bond data model
class Bond:
    atom1: AtomState
    atom2: AtomState
    order: float  # 1.0, 1.5 (aromatic), 2.0, 3.0
    bond_type: BondType  # COVALENT, IONIC, HYDROGEN, VDW, COORDINATE
    length: float  # equilibrium length in angstroms
    energy: float  # bond dissociation energy in kJ/mol
    force_constant: float  # for harmonic oscillator model (vibration)
```

**2.2 Molecular Structure Generation**

Given a molecule specification (SMILES, InChI, molecular formula, or PDB file), generate a complete 3D structure:

- **SMILES parsing**: Use RDKit to convert SMILES to a molecular graph. `Chem.MolFromSmiles('CCO')` gives you ethanol.
- **3D conformer generation**: Use RDKit's `AllChem.EmbedMolecule()` with the ETKDG method to generate a 3D conformer. This uses distance geometry to find coordinates that satisfy all bond length and angle constraints.
- **Hydrogen addition**: Always add explicit hydrogens (`Chem.AddHs()`) so the 3D structure is complete.
- **Energy minimization**: Use RDKit's MMFF94 or UFF force field to minimize the energy of the generated conformer. This relaxes the structure to a local energy minimum so bond angles and lengths are realistic.
- **PDB file parsing**: For proteins and other large biomolecules, parse PDB files directly. Extract atom coordinates, bond connectivity, and residue information.
- **Molecular formula parsing**: For simple molecules, parse formulas like "H2O" or "C6H12O6" and use heuristics + RDKit to determine the most likely structure (water, glucose, etc.).

**Implementation approach:**
- RDKit handles all the heavy lifting for small molecules. Wrap it in a clean Python service class.
- For large biomolecules (proteins, DNA), use BioPython's PDB parser or MDAnalysis.
- Store generated structures in SDF format (which includes 3D coordinates) in the database for caching.
- FastAPI endpoints: `POST /api/v1/molecules/from-smiles`, `POST /api/v1/molecules/from-pdb`, `GET /api/v1/molecules/{id}/structure`.

**2.3 Force Field Engine**

Implement a classical molecular mechanics force field. This is the physics engine that governs how atoms in a molecule move. The total potential energy of a molecular system is:

```
E_total = E_bonds + E_angles + E_dihedrals + E_electrostatic + E_vdw

Where:
- E_bonds = Σ k_b(r - r_eq)²                    (harmonic bond stretching)
- E_angles = Σ k_θ(θ - θ_eq)²                   (harmonic angle bending)
- E_dihedrals = Σ k_φ[1 + cos(nφ - δ)]          (torsional rotation)
- E_electrostatic = Σ (q_i * q_j) / (4πε₀ * r)  (Coulomb's law)
- E_vdw = Σ 4ε[(σ/r)¹² - (σ/r)⁶]               (Lennard-Jones potential)
```

**Implementation approach:**
- Implement the force field entirely in NumPy. All atom positions are stored as an (N, 3) array. All forces are computed as vectorized operations over this array.
- Use Numba `@jit(nopython=True)` to accelerate the innermost loops (especially the O(N²) pairwise non-bonded interactions).
- For the force field parameters (k_b, r_eq, k_θ, θ_eq, ε, σ, partial charges), use published parameter sets. Start with the Universal Force Field (UFF) which covers the entire periodic table, then later support AMBER/CHARMM for biomolecules.
- Implement Verlet integration (velocity Verlet) for time-stepping:
  ```
  v(t + dt/2) = v(t) + (dt/2) * F(t)/m
  x(t + dt) = x(t) + dt * v(t + dt/2)
  Compute F(t + dt) from new positions
  v(t + dt) = v(t + dt/2) + (dt/2) * F(t + dt)/m
  ```
- Implement a Berendsen thermostat to maintain constant temperature (rescale velocities each step).
- Use neighbor lists (Verlet lists or cell lists) to reduce non-bonded interaction calculation from O(N²) to approximately O(N). Rebuild neighbor lists every 10-20 steps.

**2.4 Molecular Properties Calculator**

Compute properties of molecules from their structure:

- **Molecular mass**: Sum of atomic masses.
- **Dipole moment**: From partial charges and positions.
- **Molecular surface area**: Solvent-accessible surface area (SASA) using the Shrake-Rupley algorithm.
- **Molecular volume**: Van der Waals volume.
- **LogP (lipophilicity)**: Predicted using RDKit's Crippen method. Critical for later phases (determines how substances cross cell membranes).
- **pKa**: Acid dissociation constant. Determines protonation state at physiological pH.
- **Rotatable bonds**: Count of freely rotating bonds (affects molecular flexibility).
- **HOMO/LUMO energies**: Approximate frontier orbital energies (semi-empirical methods or lookup tables).
- **Hydrogen bond donors/acceptors**: Count of HBD and HBA groups.
- **Polar surface area (PSA)**: Topological polar surface area, important for membrane permeability.

#### Frontend — Molecular Visualizer

**2.5 3D Molecule Renderer**

Extend the Three.js scene to render molecules in multiple modes:

- **Ball-and-stick**: Atoms as spheres (scaled by covalent radius), bonds as cylinders connecting them. Color by element (CPK convention: C=gray, O=red, N=blue, S=yellow, H=white). Double/triple bonds shown as parallel cylinders.
- **Space-filling (CPK)**: Atoms as spheres scaled by van der Waals radius. No bonds shown. Atoms overlap where they're close. Uses `THREE.InstancedMesh` for performance.
- **Wireframe**: Bonds as lines, atoms as small points. Fastest rendering, used for large molecules.
- **Ribbon diagram**: For proteins only. Trace the backbone (Cα atoms) and render as a smooth ribbon. α-helices shown as wide ribbons or coils, β-sheets as arrows, loops as thin tubes. Uses `THREE.TubeGeometry` along a spline through backbone atoms.
- **Surface**: Molecular surface (Connolly surface or SAS) rendered as a mesh. Can be colored by electrostatic potential (red = negative, blue = positive), by hydrophobicity, or by atom type.

**Implementation approach:**
- Use `THREE.InstancedMesh` for ball-and-stick and space-filling modes. Upload all atom positions and radii as instance attributes. This handles thousands of atoms at 60fps.
- For bonds, use `THREE.CylinderGeometry` oriented between atom pairs. For double bonds, offset two thinner cylinders by ±0.1Å perpendicular to the bond axis.
- For ribbon diagrams, use Catmull-Rom splines (`THREE.CatmullRomCurve3`) through Cα positions, then extrude a cross-section along the curve. Vary the cross-section shape by secondary structure type.
- For surfaces, compute the mesh on the backend (using a marching cubes algorithm on a grid of distance values from atom positions) and send it to the frontend as a mesh.

**2.6 Molecular Dynamics Viewport**

A real-time simulation viewport where users can:

- **Watch molecules vibrate**: Bonds stretch and compress, angles bend. Even at rest (0K), quantum zero-point energy causes vibration — but for visualization, show thermal motion at 300K.
- **Heat and cool**: A temperature slider that adjusts the thermostat. Watch molecules vibrate faster at higher temperatures. At very high temperatures, watch bonds break.
- **Rotate, zoom, pan**: Standard orbit controls. Scroll to zoom in from molecular scale to atomic scale (seamless transition to Phase 1 atom renderers).
- **Click atoms for info**: Clicking an atom highlights it and shows its properties in the inspector panel. Clicking a bond shows bond length, order, and energy.
- **Build molecules**: A simple molecule builder where users can click to place atoms and drag to form bonds. The system auto-fills hydrogens and energy-minimizes.

**2.7 Molecular Search & Library**

- A search interface where users can find molecules by name, SMILES, molecular formula, or CAS number.
- Pre-built library of common molecules: water, glucose, ATP, amino acids, ethanol, caffeine, aspirin, nicotine, benzene, carbon monoxide, etc.
- Each molecule in the library has a card with 2D structure, key properties, and a "Load in 3D" button.
- Integration with PubChem API for searching any molecule by name.

### Deliverables for Phase 2
- [ ] Backend: Chemical bonding system with all bond types
- [ ] Backend: Molecular structure generation from SMILES, PDB, formula
- [ ] Backend: Force field engine (UFF) with Verlet integration and thermostat
- [ ] Backend: Molecular properties calculator
- [ ] Backend: WebSocket endpoint for streaming MD simulation frames
- [ ] Frontend: Molecule renderer with 5 visualization modes
- [ ] Frontend: Real-time MD simulation viewport with temperature control
- [ ] Frontend: Molecule builder tool
- [ ] Frontend: Molecular search and library UI
- [ ] Integration: Real-time MD simulation streaming from backend to frontend
- [ ] Testing: Force field validation against published values, API integration tests

### Key Technical Challenges
1. **MD performance in Python** — Pure Python MD is too slow. NumPy vectorization + Numba JIT is the minimum. For molecules > 1000 atoms, consider offloading to OpenMM (which runs on GPU). The backend should abstract the engine so you can swap implementations.
2. **Non-bonded cutoffs** — Lennard-Jones and electrostatic interactions technically extend to infinity. Use a cutoff distance (typically 10-12Å) with a switching function to smoothly bring forces to zero. This is critical for performance.
3. **WebSocket frame rate** — Sending every MD step to the frontend is wasteful. The backend should run MD at ~1fs timesteps but only send frames to the frontend every 100-1000 steps (every 0.1-1ps). Use binary encoding (MessagePack or raw Float32Arrays) not JSON.
4. **Instanced rendering performance** — For molecules with > 10,000 atoms, even instanced rendering needs LOD. Distant atoms should be simplified to points, then sprites, then culled entirely.

---

## Phase 3: Organelle Simulator

### Goal
Model the major organelles found inside a eukaryotic cell. Each organelle is a complex structure composed of thousands to millions of molecules. At this scale, we can no longer simulate every atom — we transition to coarse-grained molecular models and reaction-diffusion systems, while retaining the ability to "zoom in" to full atomic detail on specific regions of interest.

### The Multi-Scale Challenge

This is where Biochemistry diverges from a simple molecular visualizer into something much more ambitious. The key insight:

**You cannot simulate a mitochondrion atom-by-atom.** A single mitochondrion contains roughly 10 billion atoms. Even with GPU-accelerated MD, simulating that many atoms for biologically relevant timescales (milliseconds to seconds) is computationally impossible on consumer hardware. Instead, we use a hierarchy of models:

- **Full atomic detail**: Used only for the specific "region of interest" where chemistry is happening (e.g., a drug binding to a protein active site). Typically < 100,000 atoms.
- **Coarse-grained molecular dynamics**: Groups of 4-10 atoms are represented by a single "bead." A protein that would be 50,000 atoms becomes ~5,000 beads. Physics is approximate but captures large-scale motions (protein folding, membrane dynamics). Uses MARTINI or similar coarse-grained force fields.
- **Particle-based reaction-diffusion**: Individual molecules are tracked as single particles (no internal structure) that diffuse through space and react when they collide. Used for metabolic pathways, signaling cascades.
- **Concentration fields**: At the largest sub-cellular scale, track molecule concentrations as continuous fields on a 3D grid. Governed by reaction-diffusion PDEs. Used for gradients (e.g., calcium waves, proton gradients).

### What Gets Built

#### Backend — Organelle Engine

**3.1 Coarse-Grained Molecular Dynamics**

Implement a coarse-grained (CG) MD engine alongside the all-atom engine from Phase 2:

- **MARTINI-like coarse graining**: Map all-atom structures to CG beads. Each bead represents ~4 heavy atoms. Bead types are categorized by polarity: polar (P), nonpolar (N), apolar (C), charged (Q).
- **CG force field**: Similar functional form to all-atom (bonds, angles, dihedrals, LJ, electrostatics) but with different parameters. Bonded interactions maintain the shape of molecules. Non-bonded interactions are calibrated to reproduce the correct partitioning behavior (how molecules distribute between water and oil).
- **Lipid bilayer simulation**: This is the primary use case for CG-MD in this phase. A lipid bilayer (cell membrane) is composed of phospholipids, each with a hydrophilic head and two hydrophobic tails. In CG, each lipid is ~12 beads. A membrane patch of 1000 lipids (enough to see curvature and dynamics) is ~12,000 beads — very tractable.
- **Membrane proteins**: Embed CG protein models into the lipid bilayer. These are the transporters, channels, and receptors that will be critical in later phases.

**Implementation approach:**
- Extend the existing MD engine to support CG beads (they're just atoms with different parameters).
- Use the same Verlet integrator and thermostat/barostat.
- Implement a mapping tool that converts all-atom PDB structures to CG representations (use published MARTINI mapping schemes for common residues and lipids).
- New endpoints: `POST /api/v1/coarse-grain/from-pdb`, `POST /api/v1/membrane/generate` (generates a solvated lipid bilayer patch).

**3.2 Reaction-Diffusion Engine**

For modeling biochemical pathways at the organelle scale:

- **Particle-based model (Smoldyn-like)**: Track individual molecules as point particles in 3D space. Each particle has a type (ATP, ADP, glucose, pyruvate, etc.) and a position. Particles undergo:
  - **Diffusion**: Brownian motion. Each timestep, add a random displacement drawn from a Gaussian with standard deviation `sqrt(2 * D * dt)` where D is the diffusion coefficient.
  - **Reactions**: When two reactive particles come within a reaction radius, they may react with a probability determined by the reaction rate constant. Reactions can create/destroy/transform particles.
  - **Surface interactions**: Particles can bind to membranes (treated as triangulated surfaces), be transported through channels, or be reflected.

- **Concentration-based model (PDE solver)**: For when particle counts are very large (> 100,000 of a given species), switch to a continuum description:
  ```
  ∂C/∂t = D∇²C + R(C)
  ```
  Where C is concentration, D is diffusion coefficient, and R(C) is the reaction term (from mass-action kinetics). Solve on a 3D grid using finite differences or finite elements.

**Implementation approach:**
- Particle-based: NumPy arrays for positions, types. Numba-accelerated diffusion step. KD-tree (scipy.spatial.cKDTree) for finding nearby particles for reactions.
- PDE solver: scipy.integrate.solve_ivp for the time integration, with the spatial Laplacian computed via finite differences on a regular 3D grid. Use sparse matrices for the Laplacian operator.
- Allow switching between particle and concentration models for different species based on copy number.

**3.3 Organelle Models**

Build structural and functional models for each major organelle:

**Mitochondrion:**
- Double membrane structure (outer membrane, inner membrane with cristae folds).
- Electron transport chain (ETC) complexes (I, II, III, IV) embedded in inner membrane.
- ATP synthase complexes embedded in inner membrane.
- Matrix contains: TCA cycle enzymes, mitochondrial DNA, ribosomes.
- Functional model: Simulates the TCA cycle (citric acid cycle), electron transport chain, oxidative phosphorylation, and ATP production.
- Key reactions: NADH → Complex I → ubiquinone → Complex III → cytochrome c → Complex IV → O₂ → H₂O. Proton gradient drives ATP synthase.
- **Connection to cigarette smoke use case**: Carbon monoxide (CO) from cigarette smoke binds to Complex IV (cytochrome c oxidase) with 200x higher affinity than O₂, inhibiting cellular respiration. This is directly simulatable at this level.

**Endoplasmic Reticulum (ER):**
- Continuous membrane network extending from the nuclear envelope.
- Rough ER: studded with ribosomes (for protein synthesis).
- Smooth ER: involved in lipid synthesis and calcium storage.
- Functional model: Protein folding (simplified), lipid synthesis, calcium sequestration/release.

**Golgi Apparatus:**
- Stack of flattened membrane cisternae (cis, medial, trans).
- Vesicle trafficking between cisternae.
- Functional model: Protein sorting, glycosylation (adding sugar chains to proteins), vesicle budding and fusion.

**Nucleus:**
- Double membrane (nuclear envelope) with nuclear pores.
- Contains: chromosomes (DNA wrapped around histones), nucleolus, nuclear lamina.
- Functional model: DNA transcription (DNA → mRNA), mRNA processing, nuclear import/export through pores.
- **Connection to cigarette smoke use case**: Benzene metabolites (benzene oxide, muconaldehyde) can form DNA adducts, causing mutations. Simulatable as reactive particles that diffuse into the nucleus and react with DNA.

**Lysosomes:**
- Single membrane vesicles containing digestive enzymes.
- Acidic interior (pH ~4.5-5.0).
- Functional model: Degradation of molecules that enter via endocytosis.

**Ribosomes:**
- Not membrane-bound, but critical.
- Composed of rRNA and proteins.
- Functional model: Translation (mRNA → protein). Input: mRNA sequence. Output: amino acid chain.

**Cytoskeleton:**
- Microtubules, actin filaments, intermediate filaments.
- Not an organelle per se, but critical for structural integrity and transport.
- Functional model: Motor protein transport (kinesin/dynein walking along microtubules carrying cargo vesicles).

**Peroxisomes:**
- Single membrane vesicles containing oxidative enzymes.
- Functional model: Fatty acid oxidation, hydrogen peroxide detoxification.

#### Frontend — Organelle Visualizer

**3.4 Multi-Scale Renderer**

This is the most significant rendering upgrade. The renderer must now handle objects spanning 4 orders of magnitude in size:

- Individual atoms: ~1-3 Å (10⁻¹⁰ m)
- Proteins: ~20-200 Å (10⁻⁹ to 10⁻⁸ m)
- Organelles: ~0.1-10 μm (10⁻⁷ to 10⁻⁵ m)

**Level of Detail (LOD) system:**
- When the camera is far from an organelle (showing the whole organelle), render it as a stylized mesh (a mitochondrion as a elongated capsule with internal folds, a nucleus as a sphere with pores).
- When the camera zooms in to a region of the membrane, transition to showing individual lipids (as CG beads or simplified molecular shapes).
- When the camera zooms in further to a specific protein in the membrane, transition to full atomic detail (ball-and-stick or ribbon diagram from Phase 2).
- This transition should be **seamless** — no loading screens, no pop-in. Use Three.js `LOD` objects and shader-based morphing between detail levels.

**Implementation approach:**
- Use `THREE.LOD` for each organelle. Define 3-4 detail levels per organelle.
- Level 0 (far): Pre-made mesh (can be hand-modeled or procedurally generated). Low poly count (~1000-10,000 triangles).
- Level 1 (medium): Show the membrane surface with embedded protein blobs. Medium poly (~10,000-100,000 triangles).
- Level 2 (close): Show individual CG beads for the membrane and proteins. Use instanced rendering.
- Level 3 (very close): Show all-atom detail for the region nearest the camera. Only render atoms within a sphere of interest (~50Å radius from camera focus).
- Use `THREE.InstancedMesh` heavily. A coarse-grained membrane with 100,000 beads is easily renderable with instancing.

**3.5 Organelle Cutaway Views**

Users should be able to "cut open" an organelle to see its interior:

- Clipping planes that slice through the organelle mesh, revealing internal structures.
- A "peel" tool that removes layers (outer membrane → inner membrane → matrix contents).
- Transparent mode where the membrane becomes semi-transparent.

**Implementation approach:**
- Use `THREE.Plane` with `renderer.clippingPlanes` for hardware-accelerated clipping.
- Material `clippingPlanes` property on each mesh.
- Cross-section faces rendered by detecting the clip plane intersection and filling with a colored surface.

**3.6 Biochemical Pathway Overlay**

A 2D overlay (rendered in React, on top of the 3D scene) that shows the active biochemical pathway as a flow diagram:

- Nodes represent metabolites (glucose, pyruvate, ATP, NADH, etc.).
- Edges represent enzymatic reactions.
- Node size/color indicates current concentration.
- Edge thickness indicates reaction flux.
- Clicking a node in the overlay highlights the corresponding molecules in the 3D scene.
- Clicking a node in the 3D scene highlights it in the overlay.

### Deliverables for Phase 3
- [ ] Backend: Coarse-grained MD engine with MARTINI-like force field
- [ ] Backend: Lipid bilayer and membrane protein generation tools
- [ ] Backend: Reaction-diffusion engine (particle-based and PDE-based)
- [ ] Backend: Organelle structural models (mitochondria, ER, Golgi, nucleus, lysosomes, ribosomes, cytoskeleton, peroxisomes)
- [ ] Backend: Organelle functional models (metabolic pathways, transport, signaling)
- [ ] Backend: Multi-scale coupler (all-atom ↔ CG ↔ particle ↔ concentration)
- [ ] Frontend: Multi-scale LOD renderer
- [ ] Frontend: Organelle cutaway and transparency tools
- [ ] Frontend: Biochemical pathway overlay
- [ ] Integration: Seamless zoom from organelle to molecule to atom
- [ ] Testing: Validate CG membrane properties (thickness, area per lipid), validate pathway fluxes against published values

### Key Technical Challenges
1. **Multi-scale coupling** — The hard problem. When a user zooms into a region, the backend must spin up an all-atom simulation for that region while the surrounding context runs in CG or reaction-diffusion mode. Boundary conditions between the scales must be handled carefully (e.g., atoms at the edge of the all-atom region interact with CG beads at the boundary).
2. **Organelle geometry** — Real organelles have complex shapes (ER is a network of tubules, mitochondrial cristae are folded). Generating realistic procedural geometry is an art. Consider using signed distance functions (SDFs) for the basic shapes and using marching cubes to extract meshes.
3. **Reaction network complexity** — The TCA cycle alone has 10 reactions with 20+ metabolites. The full metabolic network of a cell has thousands of reactions. Use SBML (Systems Biology Markup Language) format to store and exchange pathway models. Import published models from BioModels database.
4. **Memory management** — A full organelle model with CG beads, reaction particles, and concentration grids can consume gigabytes of memory. Use streaming — only load the detail that's near the camera.

---

## Phase 4: Cellular Simulator

### Goal
Assemble organelles, cytoplasm, and the cell membrane into a complete, functioning eukaryotic cell. The cell should exhibit emergent behaviors: metabolism, protein synthesis, signaling, division (mitosis), and response to external stimuli. This is the scale where we can first meaningfully simulate "what happens when substance X enters a cell."

### What Gets Built

#### Backend — Cell Engine

**4.1 Cell Architecture Model**

Define the spatial layout and composition of a complete cell:

```
Cell:
- Cell membrane: Lipid bilayer (~5nm thick) with embedded proteins
  - Receptors: signal-receiving proteins on the outer surface
  - Channels: ion channels (Na+, K+, Ca2+, Cl-), aquaporins (water)
  - Transporters: active transport (Na+/K+ ATPase), facilitated diffusion (GLUT1 for glucose)
  - Adhesion molecules: cadherins, integrins (for cell-cell and cell-matrix contact)
- Cytoplasm: Aqueous solution containing:
  - Ions: Na+, K+, Ca2+, Mg2+, Cl-, HCO3-, HPO4²- (at physiological concentrations)
  - Small molecules: glucose, amino acids, nucleotides, ATP/ADP/AMP, NAD+/NADH, etc.
  - Proteins: ~42 million protein molecules of ~10,000 different types
  - mRNA: ~100,000-300,000 molecules
- Organelles: All organelles from Phase 3, positioned realistically
  - 1 nucleus (typically ~6μm diameter, ~10% of cell volume)
  - 1000-2000 mitochondria (each ~1-10μm long)
  - 1 ER network (continuous with nuclear envelope, ~50% of total membrane)
  - 1 Golgi apparatus (~6-8 cisternae)
  - ~300 lysosomes
  - ~400 peroxisomes
  - ~10 million ribosomes (some free, some on rough ER)
  - Cytoskeleton network
- Extracellular space: Surrounding medium with defined composition
```

**Implementation approach:**
- The cell is too large to simulate all ~100 trillion atoms. Use the multi-scale approach from Phase 3 everywhere.
- Represent the cell as a compartmental model: each compartment (cytoplasm, nucleus, mitochondrial matrix, ER lumen, etc.) has its own set of concentrations and reaction networks.
- Use a 3D grid over the cell (e.g., 100x100x100 voxels) for spatial concentration fields. Each voxel is ~100nm on a side — large enough to contain thousands of molecules, small enough to capture spatial gradients.
- Organelles occupy specific voxels. Transport between compartments is governed by the transporter/channel models.

**4.2 Cell Membrane Transport System**

Model how substances cross the cell membrane:

- **Simple diffusion**: Small nonpolar molecules (O₂, CO₂, N₂, benzene) pass directly through the lipid bilayer. Rate depends on the molecule's LogP (lipophilicity) and molecular weight. Fick's law: `J = -P * (C_out - C_in)` where P is permeability coefficient.
- **Facilitated diffusion**: Molecules bind to a transporter protein that changes conformation to move them across the membrane. Rate follows Michaelis-Menten kinetics: `J = J_max * [S] / (K_m + [S])`. Examples: GLUT1 (glucose), aquaporins (water).
- **Active transport**: Uses ATP energy to move molecules against their concentration gradient. Na⁺/K⁺-ATPase pumps 3 Na⁺ out and 2 K⁺ in per ATP hydrolyzed. Model includes ATP consumption.
- **Ion channels**: Gated pores. Voltage-gated (Na⁺, K⁺, Ca²⁺ channels), ligand-gated (acetylcholine receptor), and mechanosensitive. Model using Hodgkin-Huxley-type equations for voltage-gated channels.
- **Endocytosis/Exocytosis**: Membrane invagination to engulf particles (endocytosis) or vesicle fusion to release contents (exocytosis). Model as discrete events triggered by receptor binding.
- **Receptor-mediated signaling**: Ligand binds to receptor → receptor activates intracellular signaling cascade (e.g., G-protein coupled receptor pathway, receptor tyrosine kinase pathway). Model as a series of enzymatic reactions.

**4.3 Cell Metabolism Model**

Integrate all metabolic pathways into a coherent whole-cell metabolism:

- **Glycolysis**: Glucose → 2 pyruvate + 2 ATP + 2 NADH (10 enzymatic steps in cytoplasm)
- **TCA Cycle**: Pyruvate → CO₂ + ATP + NADH + FADH₂ (in mitochondrial matrix)
- **Oxidative Phosphorylation**: NADH/FADH₂ → ATP via electron transport chain (in inner mitochondrial membrane)
- **Pentose Phosphate Pathway**: Glucose-6-P → ribose-5-P + NADPH (for nucleotide synthesis and antioxidant defense)
- **Fatty acid synthesis and β-oxidation**
- **Amino acid metabolism**: Transamination, deamination, urea cycle connections
- **Nucleotide metabolism**: De novo synthesis and salvage pathways

**Implementation approach:**
- Use ordinary differential equations (ODEs) for each metabolic pathway. Each metabolite concentration is a variable. Each enzyme is a rate equation (Michaelis-Menten or more complex).
- Use published kinetic models from the BioModels database (SBML format). The Recon3D human metabolic reconstruction contains 13,543 reactions and 4,140 metabolites.
- You don't need to simulate all 13,000 reactions at full detail. Start with the core pathways listed above (~100-200 reactions) and add more as needed.
- Solve the ODE system using `scipy.integrate.solve_ivp` with the LSODA method (which automatically switches between stiff and non-stiff solvers).

**4.4 Gene Expression Model**

Simplified model of gene expression:

- **Transcription**: DNA → mRNA. Rate depends on transcription factor binding, promoter strength, and RNA polymerase availability. Stochastic — gene expression is inherently noisy.
- **Translation**: mRNA → protein. Rate depends on ribosome availability, mRNA stability, and codon usage.
- **Protein degradation**: Proteins are tagged with ubiquitin and degraded by the proteasome. Half-lives range from minutes to days.
- **Regulation**: Transcription factors can activate or repress genes. Signal transduction pathways connect membrane receptors to transcription factors.

**Implementation approach:**
- Use the Gillespie algorithm (stochastic simulation algorithm, SSA) for gene expression. This is more appropriate than ODEs because copy numbers are low (a gene might produce only 1-10 mRNA molecules at a time, and stochastic fluctuations dominate).
- Define a simplified "genome" of ~100-1000 key genes (the full human genome has ~20,000 protein-coding genes, but most can be ignored for initial simulations).
- Each gene has: a promoter (with transcription factor binding sites), a coding sequence (determines protein product), and regulatory connections.

**4.5 Cell Cycle and Division**

Model the phases of the cell cycle:

- **G1**: Cell growth, organelle duplication, checkpoint (is the cell large enough? is DNA undamaged?).
- **S**: DNA replication (all chromosomes duplicated).
- **G2**: Preparation for mitosis, checkpoint (is DNA fully replicated? any damage?).
- **M (Mitosis)**: Chromosome condensation → alignment → separation → cytokinesis (cell splits in two).
- **G0**: Quiescent state (cell exits the cycle, stops dividing).

**Implementation approach:**
- Model as a state machine with transitions governed by cyclin/CDK concentrations.
- Checkpoints are boolean conditions: DNA damage detected? → arrest in G1 or G2 and activate repair pathways.
- **Connection to cigarette smoke use case**: DNA damage from carcinogens can trigger checkpoint arrest. If the damage is not repaired, the cell may undergo apoptosis (programmed cell death) or, if checkpoints fail, continue dividing with mutations — the first step toward cancer.

**4.6 Substance Entry and Effect Modeling**

The core feature of the whole project at the cellular level. When a substance (molecule, ion, or drug) is introduced to the extracellular environment:

1. **Determine membrane permeability**: Based on the substance's LogP, molecular weight, charge, and specific transporter availability. Small lipophilic molecules (benzene, LogP=2.1) cross easily. Large polar molecules (glucose) need transporters. Ions need channels.
2. **Track intracellular distribution**: Once inside, the substance partitions between aqueous cytoplasm, lipid membranes, and specific binding partners. Use partition coefficients and binding affinities.
3. **Identify molecular targets**: What does this substance bind to? Use a database of known drug/toxin targets. CO binds to hemoglobin and cytochrome c oxidase. Benzene is metabolized by CYP2E1. Formaldehyde crosslinks proteins and DNA.
4. **Simulate the effect**: Modify the kinetic parameters of the affected pathways. CO binding to Complex IV reduces its activity → less ATP production → cell energy crisis. DNA adducts activate the DNA damage response → cell cycle arrest → apoptosis or mutation.
5. **Propagate consequences**: Changed metabolism affects all downstream pathways. Reduced ATP production affects all ATP-consuming processes. DNA damage affects gene expression.

#### Frontend — Cell Visualizer

**4.7 Whole-Cell 3D View**

A 3D rendering of a complete eukaryotic cell:

- Cell membrane as a translucent sphere/ellipsoid with embedded protein blobs.
- Organelles visible inside, each rendered at the appropriate LOD based on camera distance.
- Cytoskeletal filaments as thin lines crisscrossing the cytoplasm.
- Particle effects for small molecules diffusing through the cytoplasm (e.g., glowing dots representing ATP molecules).
- Substances entering the cell shown as colored particles approaching and crossing the membrane.

**Implementation approach:**
- The cell is ~10-30μm in diameter. At this scale, individual atoms are invisible — the smallest visible objects are proteins and small organelles.
- Use a "galaxy" rendering approach: the cytoplasm is filled with thousands of particles (proteins, mRNA, metabolites) rendered as points with size attenuation. This gives a sense of the crowded interior without rendering each molecule in detail.
- When the user zooms in on a region, transition from point particles to actual molecular structures (Phase 2 renderer).
- Membrane proteins should be clickable — clicking opens an info panel showing the protein's name, function, and current activity.

**4.8 Cell Dashboard**

A comprehensive HUD showing the cell's vital signs:

- **ATP level**: Bar chart showing ATP/ADP/AMP ratio. Green = healthy, red = energy crisis.
- **Membrane potential**: Voltage across the cell membrane (typically -70mV at rest).
- **Intracellular pH**: Normally ~7.2.
- **Calcium concentration**: Normally ~100nM in cytoplasm, ~1mM in ER.
- **Cell cycle phase**: Current phase (G1, S, G2, M, G0) with progress bar.
- **DNA damage level**: Count of unrepaired DNA lesions.
- **Gene expression heatmap**: Top active genes with their expression levels.
- **Metabolic flux diagram**: Simplified version of the pathway overlay from Phase 3, showing major metabolic fluxes.

**4.9 Substance Injection Interface**

A UI panel where users can:

- Search for a substance (molecule name, SMILES, or category like "cigarette smoke components").
- Set the extracellular concentration.
- Click "Introduce" and watch the substance enter the cell.
- See a timeline of effects: "0s: benzene crosses membrane... 2s: benzene reaches ER... 5s: CYP2E1 oxidizes benzene to benzene oxide... 10s: benzene oxide reacts with glutathione..."
- Pause/rewind/fast-forward the simulation.

### Deliverables for Phase 4
- [ ] Backend: Complete cell architecture model with all compartments
- [ ] Backend: Membrane transport system (diffusion, channels, transporters, endocytosis)
- [ ] Backend: Integrated cell metabolism (glycolysis, TCA, OxPhos, PPP, lipid, amino acid, nucleotide)
- [ ] Backend: Gene expression model (Gillespie algorithm)
- [ ] Backend: Cell cycle state machine with checkpoints
- [ ] Backend: Substance entry and effect modeling system
- [ ] Frontend: Whole-cell 3D renderer with organelle LODs
- [ ] Frontend: Cell dashboard (vital signs HUD)
- [ ] Frontend: Substance injection interface
- [ ] Frontend: Effect timeline visualization
- [ ] Integration: Real-time cell simulation with substance effects
- [ ] Testing: Validate ATP production rates, validate substance permeability against published data

### Key Technical Challenges
1. **Computational cost** — A cell-scale simulation with hundreds of metabolic reactions, thousands of gene expression events, and spatial diffusion on a 3D grid is expensive. Budget the computation: run metabolism ODEs every 1ms of simulated time, gene expression every 1s, cell cycle every 1min. Different subsystems advance at different rates.
2. **Parameterization** — Every rate constant, diffusion coefficient, and concentration needs a value. Use published databases: BRENDA (enzyme kinetics), BioNumbers (cellular concentrations), PDB (protein structures). Missing parameters will need to be estimated.
3. **Emergence vs. scripting** — The goal is that cell behaviors (e.g., apoptosis in response to DNA damage) _emerge_ from the simulation, not be hard-coded as "if DNA damage > threshold, trigger apoptosis." This requires carefully modeling the underlying pathways (p53, caspases, Bcl-2 family).
4. **Visual clarity** — A real cell is incredibly crowded (~30% of cytoplasmic volume is protein). Showing this accurately makes it hard to see anything. Provide visualization controls: show/hide specific molecule types, reduce crowding for clarity, highlight specific pathways.

---

## Phase 5: Tissue Simulator

### Goal
Combine many cells into tissues. Model cell-cell communication, extracellular matrix, blood vessel networks, and tissue-level phenomena like inflammation, wound healing, and tumor growth. This is the first phase where we see emergent multicellular behavior.

### What Gets Built

#### Backend — Tissue Engine

**5.1 Cell Population Manager**

Scale from a single cell to thousands of cells:

- **Cell instances**: Each cell is a running instance of the Phase 4 cell simulator, but at reduced fidelity (not every cell runs full metabolism — most run a simplified "average" model, only cells of interest run the full model).
- **Cell types**: Define different cell types with different properties:
  - Epithelial cells: form sheets, have polarity (apical/basal), tight junctions between them.
  - Fibroblasts: produce extracellular matrix (collagen, elastin).
  - Endothelial cells: line blood vessels.
  - Immune cells: macrophages, neutrophils, T-cells, B-cells. Mobile, can migrate.
  - Muscle cells: contract in response to signals.
  - Nerve cells (neurons): transmit electrical signals.
  - Stem cells: can divide and differentiate into other types.
- **Cell placement**: Cells are positioned in 3D space. Different tissues have different arrangements: epithelium is a flat sheet, liver tissue is organized in lobules, bone marrow is a spongy mesh, etc.

**Implementation approach:**
- Use an agent-based model (ABM) framework. Each cell is an "agent" with:
  - Position and shape (typically modeled as a sphere or ellipsoid with a defined radius)
  - Cell type (determines behavior rules)
  - Internal state (simplified metabolism state, cell cycle phase, gene expression state)
  - Behavioral rules (when to divide, when to die, when to secrete signals, when to migrate)
- For computational feasibility, most cells run a highly simplified internal model (a few ODEs for key metabolites + a state machine for cell cycle). Only "selected" cells run the full Phase 4 simulator.
- Store cell states in a NumPy structured array for vectorized updates.

**5.2 Cell-Cell Communication**

Cells communicate through multiple mechanisms:

- **Paracrine signaling**: Cell secretes a signaling molecule (cytokine, growth factor) that diffuses through the extracellular space and is received by nearby cells. Model with reaction-diffusion equations on a 3D grid.
  - Examples: TNF-α (inflammation), VEGF (angiogenesis), EGF (growth), Wnt (development).
- **Juxtacrine signaling**: Direct contact between neighboring cells. Notch-Delta signaling, gap junctions (direct cytoplasmic connections allowing ions and small molecules to pass between cells).
- **Endocrine signaling**: Hormones carried by the bloodstream (handled in Phase 6).
- **Synaptic signaling**: Neurotransmitters across synapses (for neural tissue).

**Implementation approach:**
- For paracrine signaling, solve diffusion equations on a coarse 3D grid (voxel size ~10-50μm, so each voxel contains several cells). Each signaling molecule species has its own concentration field.
- For juxtacrine signaling, build a cell neighbor graph (which cells are in physical contact). Use a Voronoi tessellation or Delaunay triangulation of cell center positions to determine neighbors.
- Each cell agent checks its environment (local concentrations of signaling molecules, neighbor states) at each timestep and responds according to its type-specific rules.

**5.3 Extracellular Matrix (ECM)**

The structural scaffold between cells:

- **Components**: Collagen fibers (tensile strength), elastin fibers (elasticity), proteoglycans (hydration, cushioning), fibronectin (cell attachment).
- **Mechanical properties**: ECM has elasticity, viscosity, and can resist compression and tension.
- **Remodeling**: Cells constantly deposit and degrade ECM components. Matrix metalloproteinases (MMPs) degrade collagen. Fibroblasts secrete new collagen.
- **Cell-ECM interactions**: Cells attach to ECM via integrin receptors. Cells sense ECM stiffness and respond (mechanotransduction) — stiffer ECM promotes cell proliferation, which is relevant to tumor growth.

**Implementation approach:**
- Model ECM as a set of fiber fields overlaid on the tissue grid. Each voxel has a collagen density, elastin density, and stiffness value.
- Mechanical model: use a simple elastic lattice model (springs connecting grid nodes) or a more sophisticated finite element model for tissue mechanics.
- Cell migration through ECM follows: cells extend protrusions, attach to ECM, pull themselves forward, and detach from the rear. Model as biased random walk with drift toward chemoattractant gradients.

**5.4 Blood Vessel Networks (Vasculature)**

Model the blood vessel network within a tissue:

- **Structure**: Arterioles → capillaries → venules. Capillaries are ~5-10μm diameter (barely wide enough for a red blood cell).
- **Blood flow**: Simplified hemodynamics. Blood carries oxygen, nutrients, hormones, drugs, and toxins to cells, and removes waste products (CO₂, urea, lactate).
- **Exchange**: At capillaries, substances exchange between blood and tissue via diffusion through the thin endothelial wall. Rate depends on the substance's properties and the endothelial barrier (which can be leaky in inflammation).
- **Angiogenesis**: New blood vessel growth in response to VEGF signaling. Tumors secrete VEGF to recruit blood vessels (critical for tumor growth beyond ~1mm).

**Implementation approach:**
- Model blood vessels as a network of connected tube segments. Each segment has a radius, length, flow rate, and set of concentrations (O₂, CO₂, glucose, etc.).
- Blood flow: use Poiseuille's law (Q = πr⁴ΔP / 8μL) at each vessel segment. Solve the network flow problem (pressures and flows at each node) using Kirchhoff's laws (analogous to electrical circuits).
- Substance exchange: at each capillary segment, compute exchange flux based on Fick's law. Substances move from blood to tissue or vice versa based on concentration gradient and permeability.
- This is a simplified model — it doesn't track individual red blood cells. Those come in later phases.

**5.5 Tissue-Level Phenomena**

With cells, ECM, and vasculature in place, model emergent tissue behaviors:

- **Inflammation**: Damage or infection triggers release of pro-inflammatory cytokines (TNF-α, IL-1, IL-6) → vasodilation (blood vessels widen, increasing blood flow) → increased vascular permeability (plasma leaks into tissue, causing swelling) → immune cell recruitment (neutrophils and macrophages migrate from blood into tissue) → immune cells phagocytose pathogens/dead cells → resolution (anti-inflammatory cytokines dampen the response).
- **Wound healing**: Hemostasis (blood clotting) → inflammation → proliferation (fibroblasts produce collagen, endothelial cells form new vessels) → remodeling (scar tissue matures).
- **Tumor growth**: A single cell acquires mutations that bypass cell cycle checkpoints → uncontrolled proliferation → tumor mass grows → center becomes hypoxic → VEGF secretion → angiogenesis → tumor grows further → potential invasion and metastasis.
  - **Connection to cigarette smoke**: Carcinogens cause DNA mutations → cells with accumulated mutations lose growth control → tumor formation. This is now directly simulatable.

#### Frontend — Tissue Visualizer

**5.6 Tissue-Scale 3D Renderer**

Rendering thousands of cells:

- **Instanced cell rendering**: Each cell is a sphere (or more complex shape for epithelial cells). Use `THREE.InstancedMesh` with per-instance color (by cell type), size (cell volume), and opacity (dead cells fade out).
- **ECM visualization**: Collagen fibers rendered as thin tubes or lines. Fiber density shown via opacity.
- **Blood vessel rendering**: Tubes following the vessel network graph. Red/blue color indicating oxygenation level. Animated "flow" effect (scrolling texture to show blood movement).
- **Signal gradients**: Optional volumetric rendering showing signaling molecule concentration gradients as colored fog (e.g., red fog for TNF-α in inflammation).
- **LOD**: Individual cells → cell cluster blobs → tissue texture as camera zooms out.

**5.7 Tissue Dashboard**

- Cell population counts by type (bar chart, updated in real-time)
- Oxygen/nutrient perfusion map (3D heatmap)
- Inflammation index (spatial map)
- Growth rate / cell division rate
- Timeline of tissue events

### Deliverables for Phase 5
- [ ] Backend: Agent-based cell population model with multiple cell types
- [ ] Backend: Cell-cell communication (paracrine, juxtacrine)
- [ ] Backend: Extracellular matrix model with mechanical properties
- [ ] Backend: Blood vessel network with flow and exchange
- [ ] Backend: Tissue phenomena (inflammation, wound healing, tumor growth)
- [ ] Frontend: Instanced cell renderer for thousands of cells
- [ ] Frontend: ECM, vasculature, and signal gradient visualization
- [ ] Frontend: Tissue dashboard
- [ ] Integration: Click on any cell to zoom into its Phase 4 cellular view
- [ ] Testing: Validate tumor growth rates, inflammation dynamics against published models

### Key Technical Challenges
1. **Scaling to thousands of cells** — Even simplified cell models, when run for thousands of cells with intercellular communication, are computationally expensive. Use hierarchical simulation: cells far from the action use the simplest model, cells near the focus use the detailed model.
2. **3D rendering of thousands of objects** — Instanced rendering handles this well up to ~100,000 cells. Beyond that, use impostor billboards (camera-facing sprites instead of 3D geometry).
3. **Blood flow network solver** — Solving Kirchhoff's laws on a large vessel network requires solving a sparse linear system. Use scipy.sparse.linalg.spsolve.
4. **Validation** — Tissue-level models have many parameters and emergent behaviors are sensitive to them. Validate against experimental data (e.g., tumor doubling times, wound healing timelines, inflammatory marker levels).

---

## Phase 6: Organ Simulator

### Goal
Assemble tissues into complete organs. Model the specific architecture, function, and physiology of each major human organ. At this scale, we use continuum models (PDEs, compartmental ODEs) for bulk behavior, with the ability to zoom into tissue and cellular detail from Phases 4-5.

### What Gets Built

#### Backend — Organ Engine

**6.1 Organ Architecture Models**

Build anatomically accurate models for each major organ:

**Lungs:**
- Structure: Trachea → bronchi → bronchioles → alveoli (branching tree, ~23 generations).
- ~480 million alveoli providing ~70m² surface area for gas exchange.
- Functional model: Gas exchange — O₂ diffuses from alveolar air into blood, CO₂ diffuses from blood into alveolar air. Governed by partial pressure gradients and membrane diffusion.
- Airflow: Breathing mechanics (diaphragm contraction → negative pleural pressure → air flows in). Tidal volume ~500mL, respiratory rate ~12-20 breaths/min.
- **Cigarette smoke entry point**: Smoke is inhaled into alveoli. Particles deposit in airways (larger particles in upper airways, smaller particles and gases reach alveoli). Gases (CO, benzene, formaldehyde, acrolein, hydrogen cyanide) cross the alveolar membrane into blood.

**Liver:**
- Structure: Organized into ~1 million lobules. Each lobule has a central vein surrounded by radiating plates of hepatocytes, with sinusoids (specialized capillaries) between them. Portal triads (hepatic artery, portal vein, bile duct) at the corners.
- Functions: Detoxification (cytochrome P450 enzymes metabolize drugs and toxins), bile production, glycogen storage, protein synthesis (albumin, clotting factors), cholesterol metabolism.
- **Cigarette smoke connection**: Benzene is metabolized in the liver by CYP2E1 → benzene oxide → muconic acid. Some intermediates (benzene oxide, benzoquinone) are reactive and damage DNA and proteins.

**Heart:**
- Structure: 4 chambers (left/right atria and ventricles), valves, conduction system (SA node, AV node, bundle of His, Purkinje fibers).
- Functional model: Cardiac cycle — electrical excitation → mechanical contraction → blood ejection. Cardiac output = stroke volume × heart rate.
- Blood pressure: systolic/diastolic pressures, pulse wave propagation through arteries.

**Brain:**
- Structure: Cerebral cortex (gray matter, white matter), cerebellum, brainstem, thalamus, hypothalamus, hippocampus.
- Functional model: Simplified neural network model. Neurons fire action potentials, neurotransmitters cross synapses. Not a full brain simulation — focus on the circuits relevant to substance effects (e.g., nicotine activating nicotinic acetylcholine receptors in the reward pathway).
- **Cigarette smoke connection**: Nicotine crosses the blood-brain barrier in ~10 seconds after inhalation. Binds to nicotinic acetylcholine receptors → dopamine release in the nucleus accumbens (reward circuit) → addiction.

**Kidneys:**
- Structure: ~1 million nephrons per kidney. Each nephron: glomerulus (filtration) → proximal tubule (reabsorption) → loop of Henle (concentration) → distal tubule → collecting duct.
- Functional model: Filtration (blood plasma filtered at glomerulus, 180L/day), reabsorption (99% of filtrate reabsorbed), secretion (waste products actively secreted into tubules), excretion (urine formation, ~1-2L/day).
- **Cigarette smoke connection**: Kidneys filter and excrete water-soluble metabolites of smoke chemicals.

**Skin:**
- Structure: Epidermis (keratinocytes, melanocytes), dermis (fibroblasts, collagen, blood vessels, nerves), hypodermis (fat).
- Functional model: Barrier function, thermoregulation (sweat glands, blood vessel dilation/constriction), sensation.

**Other organs to model** (at varying levels of detail): stomach, intestines (small and large), pancreas, spleen, bone marrow, thymus, adrenal glands, thyroid, reproductive organs.

**6.2 Organ Physiology Engine**

For each organ, implement the governing equations:

- **Gas exchange (lungs)**: Alveolar gas equation, oxygen-hemoglobin dissociation curve (Hill equation), Fick's law of diffusion across alveolar membrane.
- **Cardiac mechanics (heart)**: Frank-Starling mechanism, pressure-volume loops, Windkessel model for arterial compliance.
- **Renal clearance (kidneys)**: Glomerular filtration rate (GFR), tubular reabsorption/secretion kinetics, countercurrent multiplication in the loop of Henle.
- **Hepatic metabolism (liver)**: First-pass metabolism, hepatic extraction ratio, intrinsic clearance (CLint = Vmax/Km for each enzyme).
- **Neural signaling (brain)**: Hodgkin-Huxley equations for action potentials, synaptic transmission models.

**Implementation approach:**
- Each organ is a module with its own set of ODEs/PDEs.
- Organs communicate through the circulatory system (Phase 7) — they consume and produce substances in the blood.
- The organ engine maintains a "physiological state" for each organ: blood flow rate, metabolic rate, functional output (e.g., cardiac output for heart, GFR for kidneys, tidal volume for lungs).

**6.3 Organ-Level Substance Tracking**

When a substance reaches an organ via the bloodstream:

1. **Uptake**: Substance moves from blood into tissue based on blood flow rate, extraction ratio, and partition coefficient.
2. **Distribution**: Within the organ, substance distributes according to tissue composition (water content, lipid content, protein binding).
3. **Metabolism**: If the organ has enzymes that metabolize the substance, apply the kinetics. The liver is the primary metabolic organ, but other organs also have enzymes (e.g., CYP1A1 in the lungs metabolizes polycyclic aromatic hydrocarbons from cigarette smoke).
4. **Excretion**: Some organs excrete substances — kidneys into urine, liver into bile, lungs into exhaled air.
5. **Effect**: The substance's pharmacological or toxicological effect on the organ. Modified enzyme activities, receptor binding, cellular damage.

#### Frontend — Organ Visualizer

**6.4 Anatomical Organ Renderer**

Each organ needs a 3D mesh that is anatomically recognizable:

- Use medical-quality anatomical meshes. Sources: BodyParts3D (free, CC-licensed human anatomy models), Visible Human Project, or custom models.
- Each organ mesh supports cutaway views to show internal structure.
- Color-coding by functional regions (e.g., liver lobules, kidney cortex/medulla, lung lobes).
- Animated function visualization: heart beating, lungs inflating/deflating, kidney filtering.

**Implementation approach:**
- Load organ meshes as GLTF/GLB files into Three.js.
- Use morph targets for animated deformations (heart beating = cycling between systole and diastole morph targets, lungs = cycling between inspiration and expiration).
- Clipping planes for cutaway views, same as Phase 3.
- Overlay functional data as color maps on the organ surface (e.g., oxygen perfusion mapped to color gradient).

**6.5 Organ Dashboard**

- Organ-specific vital signs (cardiac output, GFR, respiratory rate, etc.)
- Substance concentration within the organ over time (line chart)
- Damage indicators (if applicable)
- "Zoom into tissue" button that transitions to the Phase 5 tissue view for a selected region

### Deliverables for Phase 6
- [ ] Backend: Anatomical models for lungs, liver, heart, brain, kidneys, skin, and at least 5 other organs
- [ ] Backend: Organ physiology engines (gas exchange, cardiac mechanics, renal clearance, hepatic metabolism, neural signaling)
- [ ] Backend: Organ-level substance uptake, metabolism, and excretion
- [ ] Frontend: Anatomical organ meshes with cutaway views and animations
- [ ] Frontend: Organ dashboards with vital signs and substance tracking
- [ ] Integration: Zoom from organ surface into tissue view into cellular view
- [ ] Testing: Validate organ physiology against textbook values (cardiac output ~5L/min, GFR ~120mL/min, etc.)

### Key Technical Challenges
1. **Anatomical accuracy** — Getting realistic organ meshes with correct internal structure is hard. The Visible Human Project provides CT/MRI-derived data but converting to usable 3D meshes requires significant effort.
2. **Organ physiology is deep** — Each organ could be a PhD thesis worth of modeling. Start simple (one or two key functions per organ) and add detail incrementally.
3. **Coupling organs** — Organs interact through the bloodstream. The heart pumps blood that the lungs oxygenate, that the liver detoxifies, that the kidneys filter. The coupling must be numerically stable.

---

## Phase 7: Whole Human Body Simulator

### Goal
Connect all organs via the circulatory system, nervous system, and endocrine system into a complete, functioning virtual human body. Implement a physiologically-based pharmacokinetic (PBPK) model that tracks how any substance distributes through the entire body over time. This is the phase where the cigarette simulation becomes fully realized.

### What Gets Built

#### Backend — Whole Body Engine

**7.1 Circulatory System**

The plumbing that connects everything:

- **Arterial tree**: Heart → aorta → major arteries → smaller arteries → arterioles → capillary beds in each organ.
- **Venous return**: Capillary beds → venules → veins → vena cava → heart.
- **Pulmonary circulation**: Right heart → pulmonary arteries → lung capillaries → pulmonary veins → left heart.
- **Blood composition**: Red blood cells (carrying hemoglobin for O₂ transport), white blood cells (immune), platelets (clotting), plasma (water + dissolved proteins + electrolytes + nutrients + waste + substances).

**Implementation approach:**
- Model as a compartmental system. Each organ is a compartment connected by arterial and venous blood flows.
- Blood flow to each organ is determined by: cardiac output × fraction of cardiac output going to that organ (e.g., liver gets ~25%, kidneys get ~20%, brain gets ~15%, muscle gets ~15%, etc.).
- Substance concentration in each compartment evolves according to:
  ```
  dC_organ/dt = Q_organ/V_organ * (C_arterial - C_venous) - CL_organ/V_organ * C_organ
  ```
  Where Q = blood flow, V = organ volume, C = concentration, CL = clearance.
- This is the standard PBPK model used in pharmaceutical drug development. Well-established, many published examples.

**7.2 PBPK (Physiologically-Based Pharmacokinetic) Model**

The mathematical framework for tracking substances through the body:

```
For each tissue compartment i:
V_i * dC_i/dt = Q_i * (C_arterial - C_i/K_p,i) - CL_i * C_i + R_i

Where:
- V_i = tissue volume
- C_i = substance concentration in tissue
- Q_i = blood flow to tissue
- C_arterial = arterial blood concentration
- K_p,i = tissue:plasma partition coefficient
- CL_i = metabolic clearance in tissue
- R_i = additional rate processes (absorption, secretion, etc.)

Arterial blood:
C_arterial = (sum of Q_i * C_venous,i) / Q_cardiac

Venous blood from tissue:
C_venous,i = C_i / K_p,i  (assuming well-stirred model)
```

**Substance-specific parameters needed:**
- Molecular weight, LogP, pKa, plasma protein binding fraction
- Tissue:plasma partition coefficients (K_p) for each organ — can be predicted from tissue composition (lipid, water, protein fractions) using Rodgers & Rowland or Berezhkovskiy methods
- Metabolic clearance in liver (and possibly other organs) — Michaelis-Menten parameters for each relevant enzyme
- Renal clearance (for kidney excretion)
- Absorption parameters (for inhaled substances: deposition fraction in airways, absorption rate across alveolar membrane)

**Implementation approach:**
- The PBPK model is a system of ~10-20 coupled ODEs (one per tissue compartment). This is computationally cheap — scipy.integrate.solve_ivp handles it in milliseconds.
- The challenge is parameterization, not computation. Build a database of substance parameters. For well-known substances (drugs, common chemicals), parameters are available in the literature. For novel substances, use QSAR (Quantitative Structure-Activity Relationship) models to predict from molecular structure.
- Implement a substance parameter predictor using RDKit descriptors + published QSAR models.

**7.3 Respiratory System**

Breathing and inhaled substance absorption:

- **Breathing mechanics**: Diaphragm contraction → lung expansion → air drawn in through nose/mouth → trachea → bronchi → alveoli. Exhalation reverses.
- **Inhaled substance deposition**: Particles and gases deposit at different locations in the respiratory tract. The ICRP lung deposition model calculates deposition fraction based on particle size (or gas solubility/reactivity).
  - Large particles (>10μm): trapped in nose/throat
  - Medium particles (1-10μm): deposit in bronchi
  - Small particles (0.1-1μm): reach alveoli
  - Gases: highly soluble/reactive gases (formaldehyde) absorbed in upper airways; less soluble gases (CO, benzene) reach alveoli
- **Gas absorption**: At alveoli, gases dissolve in the thin water layer and cross the membrane. Rate depends on partial pressure gradient, membrane thickness, surface area, and gas solubility (Henry's law).

**7.4 Nervous System (Simplified)**

Not a full neural simulation, but enough to model:

- **Autonomic nervous system**: Sympathetic (fight-or-flight) and parasympathetic (rest-and-digest) effects on organs. Heart rate, blood pressure, bronchodilation/bronchoconstriction, gut motility.
- **Pain signaling**: Tissue damage → nociceptor activation → pain signal to brain.
- **Substance effects on CNS**: Nicotine → reward pathway activation. Alcohol → GABA receptor potentiation. Caffeine → adenosine receptor blockade.

**7.5 Endocrine System**

Hormonal regulation:

- **Key hormones**: Insulin/glucagon (blood sugar regulation), cortisol (stress response), epinephrine/norepinephrine (sympathetic activation), thyroid hormones (metabolic rate), sex hormones.
- **Feedback loops**: Most hormonal systems operate via negative feedback. Model as ODE systems with Hill-function regulation.

**7.6 Immune System (Simplified)**

Whole-body immune response:

- **Innate immunity**: Neutrophils, macrophages, natural killer cells. First responders to tissue damage or infection.
- **Adaptive immunity**: T-cells and B-cells. Slower but specific. B-cells produce antibodies.
- **Inflammation cascade**: Local tissue damage → cytokine release → immune cell recruitment → systemic inflammatory response if severe.
- **Cigarette smoke effect**: Chronic smoke exposure → chronic lung inflammation → increased immune cell activation → increased oxidative stress → tissue damage → COPD, emphysema.

**7.7 The Cigarette Simulation (Integration Example)**

The flagship simulation that ties everything together:

**Timeline of a single cigarette puff:**

```
t=0s: User inhales. 4,000+ chemicals in smoke enter the airways.

t=0-3s: RESPIRATORY SYSTEM
- Smoke particles deposit in airways and alveoli
- Formaldehyde (water-soluble) absorbed in upper airways → irritates epithelium
- CO, benzene, nicotine (gases) reach alveoli
- CO crosses alveolar membrane into blood (partial pressure gradient)
- Benzene crosses membrane (high lipophilicity, LogP=2.1)
- Nicotine crosses membrane (un-ionized form at alveolar pH)

t=3-10s: CIRCULATORY SYSTEM
- Substances enter pulmonary venous blood → left heart → arterial circulation
- CO binds to hemoglobin (200x affinity vs O₂) → carboxyhemoglobin forms
- Blood carries substances to all organs

t=7-10s: BRAIN
- Nicotine crosses blood-brain barrier (lipophilic, small molecule)
- Binds to α4β2 nicotinic acetylcholine receptors in ventral tegmental area
- Triggers dopamine release in nucleus accumbens → reward sensation
- This is why smokers feel a "hit" within seconds

t=10-30s: LIVER (first pass of systemic circulation)
- Blood from GI tract goes directly to liver via portal vein
- Benzene metabolized by CYP2E1 → benzene oxide → phenol + catechol + hydroquinone
- Some reactive intermediates (benzoquinone) form protein and DNA adducts
- Nicotine metabolized by CYP2A6 → cotinine (less active)

t=30s-5min: ALL ORGANS
- CO distributes to all tissues. At 1-3% carboxyhemoglobin, cells receive slightly less O₂
- Benzene metabolites distribute throughout body
- Acrolein (another smoke component) reacts with and depletes glutathione (cellular antioxidant)

t=5-30min: CELLULAR EFFECTS
- In lung epithelial cells: formaldehyde forms DNA-protein crosslinks
- In liver cells: benzoquinone forms DNA adducts
- DNA damage response activated: p53 upregulated, cell cycle arrested
- Most damage repaired by DNA repair enzymes
- Unrepaired damage → mutations accumulate over years of smoking

t=hours: EXCRETION
- Water-soluble metabolites filtered by kidneys → urine
- CO exhaled from lungs (half-life ~5 hours)
- Cotinine (nicotine metabolite) detectable in blood for 1-10 days

t=years (long-term simulation):
- Chronic inflammation in lungs → COPD/emphysema
- Accumulated DNA mutations → increased cancer risk
- Chronic carboxyhemoglobin → cardiovascular disease
- Endothelial damage → atherosclerosis
```

#### Frontend — Whole Body Visualizer

**7.8 Anatomical Human Body Renderer**

A 3D human body model:

- Full body mesh with all organs in correct anatomical positions.
- Transparent skin/muscle layers that can be toggled to reveal organs.
- Circulatory system visible as a network of red (arterial) and blue (venous) tubes.
- Respiratory system visible as a branching airway tree.
- Nervous system visible as a network of fibers.

**Implementation approach:**
- Use a complete anatomical model (BodyParts3D, Visible Human Project, or a purchased medical-grade model).
- Layer system: skin → muscle → bones → organs → vessels → nerves. Each layer can be toggled on/off or made transparent.
- The body should be zoomable — zooming into the chest reveals the heart and lungs, zooming further into the lung reveals the tissue structure (Phase 5), zooming further reveals cells (Phase 4), and so on.

**7.9 Substance Flow Visualization**

Show substances moving through the body:

- Animated particles flowing through blood vessels (color-coded by substance type).
- Organ color changes to show substance accumulation (e.g., lungs darken with smoke, liver glows when metabolizing).
- Heat-map overlay showing substance concentration across the body.
- Trailing paths showing where the substance has been.

**7.10 Whole-Body Dashboard**

- Heart rate, blood pressure, respiratory rate, temperature
- Blood chemistry panel (O₂ saturation, CO₂, glucose, pH, hemoglobin, carboxyhemoglobin %)
- Per-organ substance concentration time curves (the classic PBPK plot)
- Damage accumulation meters per organ
- Timeline scrubber: rewind and fast-forward through the simulation
- Real-time clock showing simulated time elapsed

**7.11 Scenario Builder**

Let users set up complex scenarios:

- **Select an activity**: Smoking a cigarette, drinking alcohol, eating a meal, taking medication, exercising, sleeping
- **Set parameters**: Amount (1 cigarette, 2 beers, 200mg ibuprofen), body weight, age, sex, genetic variants (e.g., fast/slow metabolizers)
- **Combine scenarios**: Smoke a cigarette while drinking coffee. Take a medication on a full stomach vs. empty stomach. Exercise after eating.
- **Compare**: Side-by-side view of two scenarios (e.g., smoker vs. non-smoker exposed to secondhand smoke)

### Deliverables for Phase 7
- [ ] Backend: Circulatory system model connecting all organs
- [ ] Backend: PBPK model engine with substance parameter prediction
- [ ] Backend: Respiratory system with inhaled substance deposition
- [ ] Backend: Simplified nervous, endocrine, and immune systems
- [ ] Backend: Cigarette smoke simulation as flagship example
- [ ] Backend: Substance database (cigarette smoke components, common drugs, foods)
- [ ] Frontend: Full human body 3D renderer with layer toggling
- [ ] Frontend: Substance flow visualization (animated particles in vessels)
- [ ] Frontend: Whole-body dashboard with vitals and PBPK curves
- [ ] Frontend: Scenario builder UI
- [ ] Frontend: Seamless zoom from whole body → organ → tissue → cell → molecule → atom
- [ ] Integration: End-to-end cigarette smoke simulation
- [ ] Testing: Validate PBPK predictions against published human data for CO, nicotine, benzene

### Key Technical Challenges
1. **Seamless zoom across 10 orders of magnitude** — From a 1.8m human body to 1Å atoms. This is an extraordinary rendering challenge. Use a hierarchical scene graph where each zoom level loads the appropriate detail. The camera "position" maps to which scale is rendered. Use logarithmic zoom.
2. **PBPK parameterization** — Getting accurate tissue partition coefficients and clearance rates for thousands of chemicals is the bottleneck. Leverage QSAR models and published databases (EPA CompTox, ChEMBL).
3. **Real-time PBPK with cellular detail** — The PBPK model itself is cheap (20 ODEs), but connecting it to tissue and cellular models from earlier phases is expensive. Use a hierarchical timestepping approach: PBPK runs every 0.1s, tissue models run at 1s resolution, cellular models run on-demand only for the region the user is looking at.
4. **User experience** — This is a massive amount of information. The UI must guide the user's attention. Use a narrative mode: "The CO molecules are now entering your bloodstream..." with camera movements that follow the substance.

---

## Phase 8: Universal Organism Simulator

### Goal
Generalize from the human body to any living organism. Build a framework where the anatomy, physiology, and biochemistry of different species can be defined and simulated. Support any substance interaction: food, drink, medication, toxin, environmental factor, pathogen, or physical activity. This is the final, most ambitious phase.

### What Gets Built

#### Backend — Universal Organism Engine

**8.1 Organism Definition Framework**

Create a flexible, data-driven system for defining organisms:

```yaml
# Example: organism definition for a mouse
organism:
  name: "Mus musculus"
  common_name: "House mouse"
  body_plan:
    symmetry: bilateral
    body_mass: 0.025  # kg
    body_temperature: 37.0  # °C
    metabolic_rate: 0.5  # watts

  organs:
    - name: "Heart"
      type: "heart"
      mass: 0.00015  # kg
      blood_flow_fraction: 0.04
      position: [0.0, 0.5, 0.1]
      physiology_model: "cardiac_4chamber"
      parameters:
        heart_rate: 600  # bpm (mice have fast hearts)
        stroke_volume: 0.00002  # L

    - name: "Liver"
      type: "liver"
      mass: 0.0018  # kg
      blood_flow_fraction: 0.25
      position: [0.0, 0.3, 0.05]
      physiology_model: "hepatic_standard"
      parameters:
        cyp_expression:
          CYP2E1: 1.2  # relative to human (allometric scaling)
          CYP1A2: 0.8

    # ... more organs

  circulatory_system:
    type: "closed_double"  # closed circulatory, double circuit (pulmonary + systemic)
    cardiac_output: 0.024  # L/min
    blood_volume: 0.0023  # L

  respiratory_system:
    type: "lungs"
    tidal_volume: 0.00024  # L
    respiratory_rate: 160  # breaths/min

  cell_types:
    - name: "Hepatocyte"
      base_type: "eukaryotic"
      modifications:
        gene_expression:
          CYP2E1: "high"
          albumin: "high"
        organelle_counts:
          mitochondria: 2000
          peroxisomes: 600
```

**Implementation approach:**
- Define a base `OrganismTemplate` Pydantic model with all the parameters needed to instantiate a PBPK model and organ simulators.
- Provide templates for common organisms: human (adult male, adult female, child, infant), mouse, rat, dog, pig (these are the standard species in pharmacology).
- Allow allometric scaling: many physiological parameters scale with body mass via power laws (metabolic rate ∝ M^0.75, heart rate ∝ M^-0.25, etc.). Given a body mass, predict most parameters automatically.
- For exotic organisms (e.g., hummingbird, blue whale, tardigrade), the user provides what they know and the system fills in the rest using allometric scaling.
- Store organism definitions in YAML/JSON files. Users can create, share, and modify organism definitions.

**8.2 Phylogenetic Variation System**

Handle the biological differences between organisms:

- **Metabolic enzyme differences**: Different species have different cytochrome P450 enzymes with different activities. Mice metabolize caffeine faster than humans. Cats lack glucuronidation (UGT1A6), making many drugs toxic to them.
- **Organ presence/absence**: Not all organisms have all organs. Fish have gills instead of lungs. Insects have open circulatory systems. Plants don't have a circulatory system at all (xylem/phloem instead).
- **Body plan differences**: Bipedal vs. quadrupedal, segmented (insects), radially symmetric (jellyfish).
- **Temperature regulation**: Endothermic (mammals, birds) vs. ectothermic (reptiles, fish, insects). Affects metabolic rate and enzyme kinetics.
- **Special adaptations**: Ruminant digestion (cows have 4 stomach compartments), avian respiratory system (unidirectional air flow), amphibian cutaneous respiration (skin breathing).

**Implementation approach:**
- Define a taxonomy of organ types and circulatory system types. Each organism picks from this menu.
- Organ physiology models are parameterized, not hard-coded. The same "gas exchange" model works for lungs and gills with different parameters (surface area, membrane thickness, ventilation rate).
- For plants: a completely different architecture (roots, stem, leaves, vascular bundles) but the same multi-scale principle applies (cells → tissues → organs → organism).

**8.3 Universal Substance Interaction System**

Generalize the substance interaction system to handle anything:

- **Food/drink**: Digestion (breakdown of macronutrients in stomach and intestines), absorption (nutrients cross intestinal wall into blood), metabolism, storage.
  - Example: Eating a glucose tablet → glucose absorbed in small intestine → blood glucose rises → pancreas releases insulin → cells take up glucose → glycolysis + glycogen synthesis.
  - Example: Drinking ethanol → absorbed in stomach and small intestine → liver metabolizes via alcohol dehydrogenase → acetaldehyde → acetate → CO₂ + H₂O.

- **Medications/drugs**: Absorption (oral, IV, inhaled, transdermal, etc.), distribution (PBPK), metabolism (hepatic CYPs), excretion (renal, biliary). Pharmacodynamic effects at target receptors.
  - Example: Taking 200mg ibuprofen orally → dissolved in stomach → absorbed in small intestine → distributed via blood → inhibits COX-1/COX-2 enzymes → reduced prostaglandin synthesis → reduced inflammation and pain → metabolized in liver → excreted by kidneys.

- **Toxins/carcinogens**: Same ADME (absorption, distribution, metabolism, excretion) as drugs, but with toxic/mutagenic effects.
  - Example: Lead exposure → absorbed via lungs or GI tract → distributed to blood, soft tissues, bone → inhibits delta-aminolevulinic acid dehydratase (disrupts heme synthesis) → anemia, neurological damage.

- **Environmental factors**: Temperature, radiation, altitude, pressure.
  - Example: High altitude → lower partial pressure of O₂ → reduced O₂ saturation → compensatory increase in breathing rate and heart rate → over days, erythropoietin secretion → increased red blood cell production.

- **Physical activity**: Exercise → increased metabolic demand → increased heart rate, cardiac output, ventilation → increased blood flow to muscles → glycolysis and fatty acid oxidation in muscle cells → lactate production → heat generation → sweating.

- **Pathogens**: Bacteria, viruses, fungi.
  - Example: Influenza virus inhaled → infects respiratory epithelial cells → viral replication → cell death → immune response (interferon, NK cells, T-cells) → inflammation → fever → symptoms → recovery or complications.

**8.4 Substance Database**

A comprehensive, searchable database of substances and their effects:

- **Chemical properties**: Molecular weight, LogP, pKa, solubility, SMILES, 3D structure.
- **ADME parameters**: Absorption rate, bioavailability, protein binding, volume of distribution, clearance, half-life, metabolic pathways (which enzymes, which metabolites).
- **Pharmacodynamic parameters**: Target receptor/enzyme, binding affinity (Ki, IC50, EC50), mechanism of action.
- **Toxicological parameters**: LD50, carcinogenicity classification, mutagenicity, organ toxicity targets.
- **Composite substances**: "Cigarette smoke" is not one molecule — it's 4,000+ chemicals. Define composite substances as a list of components with concentrations.
  - Cigarette smoke: CO (4%), nicotine (1-2mg/cigarette), benzene (50μg/cigarette), formaldehyde (60μg/cigarette), acrolein (70μg/cigarette), tar (mixture of PAHs), NNK (tobacco-specific nitrosamine), cadmium, lead, arsenic, hydrogen cyanide, ammonia, etc.
  - Beer: Ethanol (5% v/v), water, CO₂, various flavor compounds.
  - Multivitamin: defined amounts of each vitamin and mineral.

**Implementation approach:**
- Seed the database from public sources: PubChem (chemical properties), DrugBank (drug ADME/PD), EPA CompTox (toxicology), KEGG (metabolic pathways), ChEMBL (bioactivity data).
- Use RDKit and QSAR models to predict missing ADME parameters from molecular structure.
- Allow users to add custom substances by providing a SMILES string — the system predicts properties automatically.
- PostgreSQL database with full-text search for substance names and a molecular fingerprint index for similarity search.

#### Frontend — Universal Organism Visualizer

**8.5 Organism Model Editor**

A UI for creating and editing organism definitions:

- Start from a template (human, mouse, etc.) or from scratch.
- Visual body builder: drag and drop organs onto a body plan.
- Parameter editor for each organ (mass, blood flow, enzyme expression).
- Allometric scaling helper: enter body mass and auto-fill predicted parameters.
- Import/export organism definitions as YAML/JSON.

**8.6 Universal Body Renderer**

Extend the human body renderer to handle any organism:

- Parameterized body mesh generation (or library of pre-made meshes for common organisms).
- Organ placement follows the organism definition.
- Same layer system (skin → muscle → organs → vessels → nerves) adapted per species.
- Same seamless zoom capability.

**8.7 Experiment Designer**

A comprehensive UI for designing simulation experiments:

- **Select organism**: Human (customizable: age, sex, weight, genetic variants), mouse, rat, or custom.
- **Select substance**: Search database, or define custom composite.
- **Select route of administration**: Oral, inhaled, intravenous, dermal, intramuscular, subcutaneous, ocular, etc.
- **Set dose**: Amount, concentration, volume.
- **Set schedule**: Single dose, repeated dosing (e.g., 1 cigarette every hour for 8 hours, or 200mg ibuprofen every 6 hours).
- **Set duration**: How long to simulate (seconds to years, with appropriate time acceleration).
- **Select observables**: What to monitor — blood concentration, organ concentrations, vital signs, cellular effects, molecular interactions.
- **Run and compare**: Run multiple experiments side-by-side. Compare a smoker vs. non-smoker. Compare drug effects in a human vs. a mouse.

**8.8 Narrative Mode**

A guided experience that explains what's happening as the simulation runs:

- Text narration (like a documentary): "The nicotine molecules, having crossed the alveolar membrane, are now being swept along in the pulmonary venous blood toward the left side of the heart..."
- Camera automatically follows the action (tracks substance flow through the body).
- Key events highlighted with callouts: "DNA adduct formed in hepatocyte #1,247!"
- User can take over manual control at any time.
- Narration adapts to the zoom level: molecular-level narration when zoomed to atoms, organ-level when zoomed out.

**8.9 Educational Mode**

Simplified views and explanations for non-expert users:

- Tooltips on every visual element explaining what it is and what it does.
- Guided tutorials: "Follow a molecule of glucose from your mouth to your muscles."
- Quiz mode: "Where does CO bind in the cell?" with interactive answer (click on the correct organelle/molecule).
- Difficulty levels: elementary (cartoon organs), undergraduate (accurate anatomy), professional (full simulation detail).

### Deliverables for Phase 8
- [ ] Backend: Organism definition framework with allometric scaling
- [ ] Backend: Templates for human, mouse, rat, dog, cat, pig, and at least 5 other organisms
- [ ] Backend: Phylogenetic variation system (enzyme differences, organ differences)
- [ ] Backend: Universal substance interaction system (food, drug, toxin, environment, pathogen)
- [ ] Backend: Comprehensive substance database seeded from public sources
- [ ] Backend: QSAR-based property prediction for novel substances
- [ ] Frontend: Organism model editor
- [ ] Frontend: Universal body renderer supporting any organism
- [ ] Frontend: Experiment designer with dose scheduling and comparisons
- [ ] Frontend: Narrative mode with camera tracking and text narration
- [ ] Frontend: Educational mode with tutorials and quizzes
- [ ] Integration: End-to-end simulation for any substance in any organism
- [ ] Testing: Cross-species validation (drug metabolism in human vs. mouse vs. rat)

### Key Technical Challenges
1. **Generalization without losing accuracy** — A system flexible enough to model a mouse and a whale will inevitably make compromises. The key is making the architecture extensible so that specialized models can be plugged in for specific organisms/organs without rewriting the framework.
2. **Data availability** — Physiological data for humans and common lab animals is extensive. For exotic species, data is sparse. Allometric scaling helps but is approximate.
3. **Combinatorial explosion** — 10,000 possible substances × 100 possible organisms × multiple routes of administration = millions of possible simulations. Can't pre-validate all of them. Need robust default handling and graceful degradation when data is missing.
4. **Performance at scale** — A full PBPK model with organ physiology, tissue dynamics, and selective cellular detail for multiple substances simultaneously requires careful computational budgeting. Use adaptive resolution: compute full detail only where the user is looking or where interesting things are happening.
5. **Narrative generation** — The narrative mode needs to produce accurate, engaging text. Consider using Claude API (via the Anthropic SDK) to generate dynamic narration based on the current simulation state, zooming level, and substance being tracked.

---

## Cross-Cutting Concerns (All Phases)

### Performance Strategy

| Scale | Atom count | Simulation approach | Typical timestep | Frontend rendering |
|---|---|---|---|---|
| Atomic | 1-100 | Quantum mechanics (approximate) | 0.1 fs | Volume rendering (orbitals) |
| Molecular | 100-100,000 | All-atom MD | 1-2 fs | Instanced spheres/cylinders |
| Organelle | 10⁶-10⁹ | Coarse-grained MD + reaction-diffusion | 10-100 fs (CG), 1ms (RD) | LOD meshes + instanced beads |
| Cell | 10⁹-10¹³ | Compartmental ODE + agent-based | 1ms-1s | LOD with point clouds |
| Tissue | 10³-10⁶ cells | Agent-based + continuum PDE | 1s-1min | Instanced cells + volume |
| Organ | 10⁶-10⁹ cells | Continuum PDE + compartmental | 0.1s-1s | Anatomical meshes |
| Body | 37 trillion cells | Compartmental ODE (PBPK) | 0.1s-1min | Full body mesh + LOD |
| Organism | varies | Same as body, parameterized | varies | Parameterized body mesh |

### Data Pipeline

```
User action (select substance, zoom camera, adjust parameter)
    ↓
Frontend sends request via WebSocket
    ↓
Backend receives request
    ↓
Appropriate simulation engine computes next state
    ↓
State delta encoded as binary (MessagePack / protobuf)
    ↓
Streamed to frontend via WebSocket
    ↓
Frontend decodes and updates Three.js scene
    ↓
GPU renders frame at 60fps
```

### Testing Strategy

- **Unit tests**: Every calculation function tested against known values (e.g., bond length of H₂ should be ~0.74Å, ATP yield from glucose oxidation should be ~30-32 ATP).
- **Integration tests**: End-to-end tests for each phase (e.g., create molecule from SMILES, run MD for 1000 steps, verify energy conservation).
- **Validation tests**: Compare simulation outputs against published experimental data (e.g., PBPK-predicted blood concentration curves vs. clinical pharmacokinetic data).
- **Visual regression tests**: Screenshot comparison tests for the 3D renderers.
- **Performance benchmarks**: Track simulation speed (ns/day for MD, frames/second for rendering) and alert on regressions.

### Development Environment

```
biochemistry/
├── README.md                    # This file
├── CLAUDE.md                    # AI assistant guidelines
├── docker-compose.yml           # All services
├── backend/
│   ├── pyproject.toml           # Python project config (uv/poetry)
│   ├── src/
│   │   ├── api/                 # FastAPI routes
│   │   ├── simulation/          # Simulation engines (one sub-package per phase)
│   │   │   ├── atomic/          # Phase 1
│   │   │   ├── molecular/       # Phase 2
│   │   │   ├── organelle/       # Phase 3
│   │   │   ├── cellular/        # Phase 4
│   │   │   ├── tissue/          # Phase 5
│   │   │   ├── organ/           # Phase 6
│   │   │   ├── body/            # Phase 7
│   │   │   └── organism/        # Phase 8
│   │   ├── data/                # Data models and database access
│   │   └── utils/               # Shared utilities
│   └── tests/
├── frontend/
│   ├── package.json
│   ├── src/
│   │   ├── components/          # React components
│   │   ├── renderers/           # Three.js rendering code (one sub-dir per phase)
│   │   ├── shaders/             # Custom GLSL shaders
│   │   ├── hooks/               # React hooks for simulation data
│   │   ├── stores/              # Zustand state stores
│   │   └── utils/               # Frontend utilities
│   └── public/
│       └── assets/
│           ├── meshes/          # 3D organ/body meshes (GLTF)
│           └── textures/        # Textures for organs, cells, etc.
├── data/
│   ├── elements/                # Periodic table data
│   ├── molecules/               # Pre-computed molecular structures
│   ├── organisms/               # Organism definition YAML files
│   └── substances/              # Substance property database
└── docs/                        # Additional documentation
```

---

## Getting Started (When You're Ready)

1. **Set up the monorepo**: Initialize the directory structure above. Use `uv` for Python dependency management, `pnpm` for Node.js.
2. **Start with Phase 1 backend**: Build the element database and atomic property API. This is the most self-contained piece.
3. **Start with Phase 1 frontend in parallel**: Set up React + Three.js, build the periodic table UI, and a basic 3D viewport.
4. **Connect them**: Fetch element data from the API, render an atom in the viewport.
5. **Iterate**: Each phase builds on the previous. You'll know you're ready for the next phase when the current phase has a working demo.

**You don't need to build this alone.** Each phase is a substantial project. Consider:
- Open-sourcing and building a community
- Using existing open-source tools where possible (RDKit, OpenMM, BioModels)
- Collaborating with domain experts (biochemists, pharmacologists, medical illustrators)
- Applying for research grants (NIH, NSF — computational biology and science education are funded areas)

---

## References and Resources

### Computational Chemistry
- Leach, A.R. "Molecular Modelling: Principles and Applications" — textbook on molecular simulation
- MARTINI force field: http://cgmartini.nl/ — coarse-grained MD parameters
- OpenMM: https://openmm.org/ — GPU-accelerated molecular dynamics toolkit

### Systems Biology
- Karr et al. (2012) "A Whole-Cell Computational Model Predicts Phenotype from Genotype" — the Mycoplasma whole-cell model, closest thing to what Phase 4 describes
- BioModels: https://www.ebi.ac.uk/biomodels/ — published mathematical models of biological systems
- Recon3D: Human metabolic reconstruction with 13,543 reactions

### Pharmacokinetics
- Rowland & Tozer "Clinical Pharmacokinetics and Pharmacodynamics" — the standard PBPK textbook
- PK-Sim / Open Systems Pharmacology: https://www.open-systems-pharmacology.org/ — open-source PBPK modeling platform
- Rodgers & Rowland (2006) — tissue:plasma partition coefficient prediction method

### Visualization
- Three.js: https://threejs.org/ — 3D rendering library
- React Three Fiber: https://docs.pmnd.rs/react-three-fiber — React renderer for Three.js
- Mol*: https://molstar.org/ — open-source molecular visualization (good reference implementation)
- BioDigital Human: https://www.biodigital.com/ — commercial 3D human body platform (similar macro-scale goals)

### Data Sources
- PubChem: https://pubchem.ncbi.nlm.nih.gov/ — chemical properties database
- DrugBank: https://go.drugbank.com/ — drug ADME and pharmacology database
- EPA CompTox: https://comptox.epa.gov/ — chemical toxicology data
- ChEMBL: https://www.ebi.ac.uk/chembl/ — bioactivity database
- BioNumbers: https://bionumbers.hms.harvard.edu/ — quantitative data for biological systems
- BRENDA: https://www.brenda-enzymes.org/ — enzyme kinetics database
- BodyParts3D: https://lifesciencedb.jp/bp3d/ — 3D human anatomy models

---

## License

TBD — Consider MIT or Apache 2.0 for maximum accessibility, or GPL if you want to ensure derivative works remain open source.
