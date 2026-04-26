---
name: data-driven-check
description: Proactively applied when writing simulation or model code — ensures no hard-coded physical values
---

# Data-Driven Check

This project has a strict rule: physical constants, element properties, force field parameters, enzyme kinetics, and physiological parameters must NEVER be hard-coded in simulation code. They must come from data files or databases.

## When you see a number in simulation code, ask:

1. **Is it a universal physical constant?** (speed of light, Boltzmann constant, Avogadro's number, Planck's constant, etc.)
   → It should be imported from `backend/src/constants.py`, not written as a literal

2. **Is it an element property?** (atomic mass, electronegativity, radius, ionization energy)
   → It should come from the element database, not a literal

3. **Is it a force field parameter?** (bond length, angle, LJ epsilon/sigma, partial charge)
   → It should come from a parameter file in `backend/data/force_fields/`, not a literal

4. **Is it a biological parameter?** (enzyme Km/Vmax, diffusion coefficient, membrane permeability, organ blood flow fraction)
   → It should come from the substance/organism database or a YAML/SBML data file, not a literal

5. **Is it a numerical algorithm parameter?** (grid size, timestep, tolerance, cutoff distance)
   → These CAN be hard-coded as defaults but should be configurable via function arguments

## The only acceptable hard-coded numbers are:

- Array dimensions and loop bounds
- Mathematical constants (π, e, 0, 1, 2)
- Algorithm-specific constants (integration coefficients, finite difference stencil weights)
- Default values for configurable parameters (with the default documented)

## If you find a violation

Flag it immediately. Replace the literal with a reference to the appropriate data source. If the data source doesn't exist yet, create it or add a TODO referencing the specific task in `docs/MASTER_PLAN.md` that will create it.