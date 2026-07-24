"""
Sanity checks for C4 BKT mastery updates (real BKT, not flat ±deltas).
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent
sys.path.insert(0, str(REPO))
sys.path.insert(0, str(ROOT))

from core.mastery_tracker import (
    P_INIT,
    P_GUESS,
    P_LEARN,
    P_SLIP,
    bkt_update,
    get_level,
    update_mastery,
)


def test_params():
    assert P_INIT == 0.10
    assert P_LEARN == 0.20
    assert P_SLIP == 0.10
    assert P_GUESS == 0.15


def test_bounds_and_monotonic_correct():
    p = P_INIT
    trajectory = [p]
    for _ in range(12):
        p = bkt_update(p, True)
        trajectory.append(p)
        assert 0.0 <= p <= 1.0
    # Trends upward and approaches high knowledge
    assert trajectory[-1] > trajectory[0]
    assert trajectory[-1] > 0.85
    # Non-decreasing under all-correct (with learning)
    for a, b in zip(trajectory, trajectory[1:]):
        assert b >= a - 1e-12


def test_incorrect_pulls_down_but_bounded():
    p = 0.9
    for _ in range(8):
        p = bkt_update(p, False)
        assert 0.0 <= p <= 1.0
    assert p < 0.9
    assert p >= 0.0


def test_alternating_trajectory_printable():
    """Simulate alternating correct/incorrect; print p_know path for manual sanity."""
    p = P_INIT
    path = [round(p, 4)]
    observations = [True, False, True, True, False, True, True, True, False, True]
    for obs in observations:
        p = bkt_update(p, obs)
        path.append(round(p, 4))
        assert 0.0 <= p <= 1.0

    print("BKT alternating trajectory (start=P_INIT):")
    print("  obs:", ["C" if x else "I" for x in observations])
    print("  p_know:", path)
    # More corrects than incorrects overall → should end above init
    assert path[-1] > path[0]
    # Never out of bounds
    assert all(0.0 <= x <= 1.0 for x in path)


def test_update_mastery_alias():
    assert abs(update_mastery(P_INIT, True) - bkt_update(P_INIT, True)) < 1e-12
    assert abs(update_mastery(P_INIT, False) - bkt_update(P_INIT, False)) < 1e-12


def test_level_bands_still_work():
    assert get_level(0.10) == 1
    assert get_level(0.3) == 1
    assert get_level(0.5) == 2
    assert get_level(0.7) == 3
    assert get_level(0.9) == 4


if __name__ == "__main__":
    test_params()
    print("[OK] params")
    test_bounds_and_monotonic_correct()
    print("[OK] all-correct climbs toward 1")
    test_incorrect_pulls_down_but_bounded()
    print("[OK] incorrect pulls down, bounded")
    test_alternating_trajectory_printable()
    print("[OK] alternating trajectory")
    test_update_mastery_alias()
    print("[OK] update_mastery alias")
    test_level_bands_still_work()
    print("[OK] level bands")
    print("All C4 BKT mastery tests passed.")
