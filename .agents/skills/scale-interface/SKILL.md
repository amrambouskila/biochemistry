---
name: scale-interface
description: Proactively applied when modifying engine interfaces or data models that cross scale boundaries
---

# Scale Interface Guardian

This project spans 8 scales from atoms to organisms. The interfaces between scales are the most architecturally critical code. When you are modifying any engine interface or data model that crosses scale boundaries, apply extra scrutiny.

## The scale chain

```
Atomic (1Å, 1fs)
  ↓ atom positions, types → molecular structure
Molecular (1Å, 1fs)
  ↓ all-atom structure → CG bead mapping
Organelle CG (5Å, 10fs)
  ↓ bead positions → reaction particle positions
Organelle RD (10nm, 1μs)
  ↓ particle counts → concentration fields
Cellular (100nm, 1ms)
  ↓ compartment concentrations → cell agent state
Tissue (10μm, 1s)
  ↓ cell population stats → organ physiology inputs
Organ (1mm, 0.1s)
  ↓ organ outputs (blood concentrations) → PBPK compartment
Body (1m, 0.1s)
  ↓ PBPK parameters → organism template values
Organism (varies)
```

## Before modifying an interface

1. Identify which two scales this interface connects
2. Read the current interface contract in `backend/src/simulation/interfaces.py`
3. Check both the engine ABOVE and the engine BELOW to confirm they still work with your changes
4. If you change the output format of engine N, you MUST update the input handling of engine N+1
5. If you change the input format of engine N, you MUST update the output of engine N-1

## Unit conversion at boundaries

Every scale has a canonical unit system (see `docs/MASTER_PLAN.md` Cross-Phase Concerns). When data crosses a scale boundary, units MUST be explicitly converted. Document the conversion with a comment:

```python
# Convert from molecular scale (Å) to organelle scale (nm)
positions_nm = positions_angstrom * 0.1
```

## Never break backward compatibility silently

If you must change an interface, verify that all existing tests for both adjacent scales still pass. If they don't, fix them — don't just update the tests to match the new (possibly wrong) output.