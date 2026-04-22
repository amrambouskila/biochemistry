"""Validate physical constants against CODATA-endorsed reference values."""
from __future__ import annotations

import pytest

from src import constants


@pytest.mark.parametrize(
    ("name", "expected"),
    [
        ("AVOGADRO", 6.022_140_76e23),
        ("BOLTZMANN", 1.380_649e-23),
        ("SPEED_OF_LIGHT", 299_792_458.0),
        ("ELEMENTARY_CHARGE", 1.602_176_634e-19),
        ("PLANCK", 6.626_070_15e-34),
    ],
)
def test_exact_constants_match_2019_si(name: str, expected: float) -> None:
    assert getattr(constants, name) == expected


def test_gas_constant_matches_codata() -> None:
    # CODATA 2018: R = 8.314 462 618 153 24 J/(mol·K). Exact product of two exact
    # inputs; compare to recommended-value printed precision.
    assert constants.GAS_CONSTANT == pytest.approx(8.314_462_618_153_24, rel=1e-14)
