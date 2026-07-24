"""
Quick unit tests for C4 Grade-1 pipeline (no Mongo / no server required).
Run: python -m pytest intervention-service-v1/tests/test_c4_pipeline.py -q
  or: python intervention-service-v1/tests/test_c4_pipeline.py
"""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "intervention-service-v1"))

from core.sinhala_segmenter import segment_word, analyze_word
from core.reference_table import get_grade1_table, validate_content, pick_primary_tag
from core.mastery_tracker import update_mastery, get_level
from core.localization import localize_from_zone_hint, apply_error_pattern_boost
from core.pipeline import InterventionPipeline
from core.intervention_cycle import Stage
import numpy as np


def test_segment_and_tags():
    table = get_grade1_table()
    units = analyze_word("ටැඹ", table)
    assert len(units) >= 2
    assert units[0].base_consonant == "ට"
    primary = pick_primary_tag(units[0].tags)
    assert primary in ("visual_confusion", "pillam_subtle", "blend_required", "hal_kirima", None)


def test_validate_content_ka_row():
    assert validate_content("ක") is True
    assert validate_content("කා") is True


def test_mastery_math():
    # Flat ±deltas replaced by real BKT; spot-check via bkt_update path
    from core.mastery_tracker import P_INIT, bkt_update
    after_correct = update_mastery(P_INIT, True)
    after_incorrect = update_mastery(P_INIT, False)
    assert abs(after_correct - bkt_update(P_INIT, True)) < 1e-9
    assert abs(after_incorrect - bkt_update(P_INIT, False)) < 1e-9
    assert after_correct > P_INIT
    assert 0.0 <= after_incorrect <= 1.0
    assert get_level(0.3) == 1
    assert get_level(0.5) == 2
    assert get_level(0.7) == 3
    assert get_level(0.9) == 4


def test_localization_zones():
    r = localize_from_zone_hint("start", 3)
    assert r.zone == "start" and r.akshara_index == 0
    boosted = apply_error_pattern_boost(r, [1, 0, 1, 0])
    assert "visual_confusion" in boosted.tags_boosted
    assert boosted.confidence > r.confidence


def test_audio_localization_middle_silence():
    from core.localization import localize_from_audio
    sr = 16000
    # 0.3s tone, 0.2s silence, 0.3s tone
    tone = (0.2 * np.sin(2 * np.pi * 440 * np.arange(int(0.3 * sr)) / sr)).astype(float)
    silence = np.zeros(int(0.2 * sr))
    samples = np.concatenate([tone, silence, tone])
    r = localize_from_audio(samples, sr, akshara_count=3)
    assert r.zone in ("start", "middle", "end")


async def _e2e_discrimination():
    pipe = InterventionPipeline()
    trig = await pipe.trigger(
        child_id="child_demo_1",
        word="ටැඹ",
        phonological_strain_index=0.6,
        error_pattern_vector=[1, 0, 1, 0],
        zone_hint="start",
    )
    assert trig["triggered"] is True
    assert trig["tag"]
    assert trig["engine"]

    start = await pipe.start_cycle(
        child_id="child_demo_1",
        tag=trig["tag"],
        specific_instance=trig["specific_instance"],
        word=trig["word"],
        cycle_mode="short",  # Teach -> Progress Check only
        localization_zone=trig["localization_zone"],
        localization_confidence=trig["localization_confidence"],
        error_pattern_flags=trig["error_pattern_flags"],
    )
    assert start["stage"] == Stage.TEACH.value
    mid = await pipe.respond_cycle(start["cycle_id"], Stage.TEACH.value, {})
    assert mid["stage"] == Stage.PROGRESS_CHECK.value
    # Pass progress check
    end = await pipe.respond_cycle(
        start["cycle_id"],
        Stage.PROGRESS_CHECK.value,
        {"correct": True, "attempted": True},
    )
    assert end["exit"] is True
    assert end["mastery_update"]["mastery_after"] > end["mastery_update"]["mastery_before"]


def test_e2e_short_cycle():
    asyncio.run(_e2e_discrimination())


if __name__ == "__main__":
    test_segment_and_tags()
    print("[OK] segment_and_tags")
    test_validate_content_ka_row()
    print("[OK] validate_content")
    test_mastery_math()
    print("[OK] mastery_math")
    test_localization_zones()
    print("[OK] localization")
    test_audio_localization_middle_silence()
    print("[OK] audio_localization")
    test_e2e_short_cycle()
    print("[OK] e2e_short_cycle discrimination")
    print("All C4 pipeline smoke tests passed.")
