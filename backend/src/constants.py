"""Universal physical and mathematical constants.

The ONLY place in the codebase where numerical literals with physical or
mathematical meaning may appear. See CLAUDE.md §Data-Driven — domain
parameters (element properties, force-field coefficients, pathway kinetics,
physiological values) belong in the database or data files, never here.

Values are SI units unless otherwise annotated, and follow the 2019 SI
redefinition (seven defining constants now exact). Source: CODATA 2018.
"""
from __future__ import annotations

# ---- Exact-by-definition (2019 SI redefinition) ----
AVOGADRO: float = 6.022_140_76e23
"""Avogadro constant N_A (1/mol). Exact."""

BOLTZMANN: float = 1.380_649e-23
"""Boltzmann constant k_B (J/K). Exact."""

SPEED_OF_LIGHT: float = 299_792_458.0
"""Speed of light in vacuum c (m/s). Exact."""

ELEMENTARY_CHARGE: float = 1.602_176_634e-19
"""Elementary charge e (C). Exact."""

PLANCK: float = 6.626_070_15e-34
"""Planck constant h (J·s). Exact."""

# ---- Derived (exact because inputs are exact) ----
GAS_CONSTANT: float = AVOGADRO * BOLTZMANN
"""Molar gas constant R = N_A · k_B (J/(mol·K))."""
