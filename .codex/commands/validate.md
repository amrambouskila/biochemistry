---
name: validate
description: Validate simulation code against correctness, completeness, and AGENTS.md requirements
---

Validate simulation code against correctness, completeness, and AGENTS.md requirements. This is an inspection workflow — read, verify, report.

## Before anything else

1. Re-read AGENTS.md — specifically Common Pitfalls #3 (Skipping validation) and the Definition of Done criteria
2. Read docs/MASTER_PLAN.md — find the GATE criteria for the current phase
3. If $ARGUMENTS is provided, scope the validation to that module or phase. Otherwise, validate everything in `backend/src/simulation/`

## Validation layers

Work through each layer in order. Do not skip any.

### Layer 1: Structural completeness

For every module in `backend/src/simulation/`:
- [ ] Does a corresponding test file exist in `backend/tests/`?
- [ ] Does the engine define input/output/timestep/spatial resolution?
- [ ] Are all function signatures fully type-annotated?
- [ ] Are array shapes documented in docstrings?

### Layer 2: Numerical correctness

For every test file in `backend/tests/`:
- [ ] Are numerical comparisons using `np.testing.assert_allclose` (not `==`)?
- [ ] Are tolerances documented and justified? (e.g., `atol=1e-10` for energy conservation)
- [ ] Is at least one test comparing against a known analytical solution or published reference value?
- [ ] Are tests parametrized for multiple conditions where applicable?

### Layer 3: Data-driven compliance

Scan all simulation code for:
- [ ] Hard-coded physical constants — flag anything that should be in `backend/src/constants.py`
- [ ] Hard-coded element/molecule properties — should come from database or data files
- [ ] Magic numbers without named references or unit documentation

### Layer 4: Performance compliance

Scan simulation code for:
- [ ] Python `for` loops iterating over atoms/particles (should be vectorized)
- [ ] Python lists used for numerical data (should be NumPy arrays)
- [ ] NumPy arrays without explicit dtypes
- [ ] `scipy.spatial.KDTree` instead of `cKDTree`
- [ ] Missing Numba `@jit(nopython=True)` on hot loops

### Layer 5: Reference validation (most important)

For each simulation engine, check if there is at least one test that validates output against published data:
- Phase 1: Orbital shapes match quantum mechanical predictions
- Phase 2: Bond lengths (H₂: 0.74Å, O₂: 1.21Å, N₂: 1.10Å), bond angles (water: 104.5°, methane: 109.5°), energy conservation (<0.1% drift over 10,000 NVE steps)
- Phase 3: Diffusion coefficients match experimental values
- Phase 4: Gene expression noise matches Gillespie predictions
- Phase 5+: Tissue-scale behavior matches known physiological ranges

If no reference validation exists for a module, flag it as **critical** — an unvalidated engine produces garbage that compounds across scales.

## Output format

Per-layer report:

| Layer | Status | Issues |
|-------|--------|--------|
| Structural | PASS/FAIL | List missing tests, undocumented interfaces |
| Numerical | PASS/FAIL | List bad comparisons, unjustified tolerances |
| Data-driven | PASS/FAIL | List hard-coded values with file:line |
| Performance | PASS/FAIL | List violations with file:line |
| Reference | PASS/FAIL | List unvalidated engines |

End with a prioritized list of what to fix first.