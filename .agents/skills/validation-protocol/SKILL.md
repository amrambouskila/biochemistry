---
name: validation-protocol
description: Proactively applied when writing or modifying tests — ensures numerical validation follows project standards
---

# Validation Protocol

When you are creating or modifying test files, follow this protocol. Validation is critical in this project because errors compound across scales — an unvalidated force field produces garbage at every subsequent phase.

## Test structure requirements

1. **Mirror the source tree**: Test file at `backend/tests/simulation/atomic/test_orbitals.py` tests `backend/src/simulation/atomic/orbitals.py`

2. **Three categories of tests** (every module needs all three):
   - **Unit tests**: Individual functions tested against analytical solutions
   - **Integration tests**: Multiple components working together
   - **Validation tests**: Output compared against published experimental or reference data — this is the most important category

3. **Numerical comparison**: Always use `np.testing.assert_allclose(actual, expected, atol=..., rtol=...)`. NEVER use `==` for floating-point comparison. Document why the chosen tolerance is appropriate in a comment.

4. **Parametrize**: Use `@pytest.mark.parametrize` for testing across multiple elements, molecules, conditions, or parameters. A test that only checks one case is incomplete.

5. **No mocking of physics**: Never mock a simulation calculation. Test against known analytical solutions or published values. Mocking physics hides bugs that compound across scales.

## Validation reference sources

When writing validation tests, cite the reference source:

- **Atomic**: NIST Atomic Spectra Database (wavelengths), NIST ionization energies
- **Molecular**: Published bond lengths/angles (CRC Handbook), energy conservation in NVE ensemble
- **Force field**: UFF paper (Rappé et al., 1992) for equilibrium parameters
- **Organelle**: Experimental membrane thickness (~4nm for POPC), area per lipid (~0.64 nm²)
- **Cellular**: BioNumbers database (concentrations, copy numbers, rates)
- **Tissue**: Published tumor doubling times, inflammation timelines
- **Organ**: Textbook physiological values (cardiac output ~5 L/min, GFR ~120 mL/min)
- **PBPK**: Published clinical pharmacokinetic data (drug half-lives, bioavailability)

Include the reference as a comment in the test:
```python
# Reference: NIST Atomic Spectra Database, Hydrogen Balmer series
# Hα = 656.28 nm
np.testing.assert_allclose(computed_wavelength, 656.28, atol=0.1)
```

## Gate validation

After completing a set of tests, check whether the current phase's GATE criteria (from `docs/MASTER_PLAN.md`) are now satisfied. If all GATE criteria pass, inform the user that the gate is clear and the next stage/phase can begin.