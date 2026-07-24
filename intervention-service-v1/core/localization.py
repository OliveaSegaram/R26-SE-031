"""
Struggle localization — 3-zone energy/silence detection (no ML).

Maps pause/energy irregularities in a word-level audio clip onto
start / middle / end of the akshara sequence.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional, Sequence, Union

import numpy as np

from .sinhala_segmenter import Akshara

ZONE_START = "start"
ZONE_MIDDLE = "middle"
ZONE_END = "end"


@dataclass
class LocalizationResult:
    zone: str                    # start | middle | end
    akshara_index: int
    confidence: float
    tags_boosted: List[str]


def _zone_for_index(index: int, n: int) -> str:
    if n <= 1:
        return ZONE_START
    if n == 2:
        return ZONE_START if index == 0 else ZONE_END
    third = max(n // 3, 1)
    if index < third:
        return ZONE_START
    if index >= n - third:
        return ZONE_END
    return ZONE_MIDDLE


def _index_for_zone(zone: str, n: int) -> int:
    if n <= 0:
        return 0
    if zone == ZONE_START:
        return 0
    if zone == ZONE_END:
        return n - 1
    return n // 2


def _rms_frames(samples: np.ndarray, sr: int, frame_ms: int = 50) -> np.ndarray:
    frame = max(int(sr * frame_ms / 1000), 1)
    if len(samples) < frame:
        return np.array([float(np.sqrt(np.mean(samples.astype(float) ** 2)))])
    n = len(samples) // frame
    trimmed = samples[: n * frame].reshape(n, frame).astype(float)
    return np.sqrt(np.mean(trimmed ** 2, axis=1))


def localize_from_audio(
    samples: np.ndarray,
    sample_rate: int,
    akshara_count: int,
    silence_ratio: float = 0.15,
) -> LocalizationResult:
    """
    3-zone localization from RMS energy.

    - Silence before sound starts -> start
    - Long silence / dip mid-clip -> middle
    - Stumble near end -> end
    """
    n = max(akshara_count, 1)
    if samples is None or len(samples) == 0:
        return LocalizationResult(ZONE_MIDDLE, _index_for_zone(ZONE_MIDDLE, n), 0.4, [])

    rms = _rms_frames(np.asarray(samples).flatten(), sample_rate)
    peak = float(np.max(rms)) if len(rms) else 0.0
    if peak <= 1e-9:
        return LocalizationResult(ZONE_START, 0, 0.5, [])

    thresh = peak * silence_ratio
    voiced = rms >= thresh

    # Leading silence -> struggle at first unit
    leading = 0
    for v in voiced:
        if not v:
            leading += 1
        else:
            break
    if leading >= max(2, len(voiced) // 8):
        return LocalizationResult(ZONE_START, 0, 0.75, [])

    # Trailing irregularity
    trailing = 0
    for v in reversed(voiced):
        if not v:
            trailing += 1
        else:
            break
    if trailing >= max(2, len(voiced) // 8):
        idx = n - 1
        return LocalizationResult(ZONE_END, idx, 0.7, [])

    # Longest internal silence island
    best_len = 0
    best_center = len(voiced) // 2
    run = 0
    run_start = 0
    for i, v in enumerate(voiced):
        if not v:
            if run == 0:
                run_start = i
            run += 1
            if run > best_len:
                best_len = run
                best_center = run_start + run // 2
        else:
            run = 0

    if best_len >= max(2, len(voiced) // 10):
        frac = best_center / max(len(voiced) - 1, 1)
        idx = int(round(frac * (n - 1)))
        zone = _zone_for_index(idx, n)
        return LocalizationResult(zone, idx, 0.65, [])

    # Default: middle of word
    idx = n // 2
    return LocalizationResult(ZONE_MIDDLE, idx, 0.45, [])


def localize_from_zone_hint(
    zone: Optional[str],
    akshara_count: int,
    confidence: float = 0.55,
) -> LocalizationResult:
    """Fallback when audio is unavailable (mobile can send reading-position zone)."""
    n = max(akshara_count, 1)
    z = zone if zone in (ZONE_START, ZONE_MIDDLE, ZONE_END) else ZONE_MIDDLE
    return LocalizationResult(z, _index_for_zone(z, n), confidence, [])


def apply_error_pattern_boost(
    result: LocalizationResult,
    error_pattern_vector: Union[Sequence[int], dict, None],
) -> LocalizationResult:
    """
    Cross-check with C1 error_pattern_vector.
    List form: [reversal, omission, substitution, hesitation]
    """
    flags: List[str] = []
    boost = 0.0
    boosted_tags: List[str] = []

    rev = omi = sub = hes = 0
    if isinstance(error_pattern_vector, dict):
        rev = int(error_pattern_vector.get("reversal", 0))
        omi = int(error_pattern_vector.get("omission", 0))
        sub = int(error_pattern_vector.get("substitution", 0))
        hes = int(error_pattern_vector.get("hesitation", 0))
    elif isinstance(error_pattern_vector, (list, tuple)) and len(error_pattern_vector) >= 4:
        rev, omi, sub, hes = [int(x) for x in error_pattern_vector[:4]]

    if rev or sub:
        boost += 0.15
        boosted_tags.append("visual_confusion")
        if rev:
            flags.append("reversal")
        if sub:
            flags.append("substitution")
    if omi:
        boost += 0.1
        boosted_tags.extend(["hal_kirima", "pillam_subtle"])
        flags.append("omission")
    if hes:
        boost += 0.05
        flags.append("hesitation")

    conf = min(1.0, result.confidence + boost)
    return LocalizationResult(
        zone=result.zone,
        akshara_index=result.akshara_index,
        confidence=conf,
        tags_boosted=boosted_tags,
    )


def localize_struggle(
    aksharas: Sequence[Akshara],
    *,
    audio_samples: Optional[np.ndarray] = None,
    sample_rate: int = 16000,
    zone_hint: Optional[str] = None,
    error_pattern_vector: Union[Sequence[int], dict, None] = None,
) -> LocalizationResult:
    n = len(aksharas)
    if audio_samples is not None and len(audio_samples) > 0:
        result = localize_from_audio(audio_samples, sample_rate, n)
    else:
        result = localize_from_zone_hint(zone_hint, n)
    return apply_error_pattern_boost(result, error_pattern_vector)
