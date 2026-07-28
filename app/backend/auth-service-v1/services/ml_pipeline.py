"""
services/ml_pipeline.py
========================
Machine Learning Analytics Pipeline for Dyslexia / Dyspraxia Cognitive Profiling.

Feature Extraction → Cognitive Index Computation → Risk Classification

This module processes raw telemetry events stored in MongoDB and produces
a structured cognitive profile per student, including:
  - Visual Processing Score
  - Phonological Awareness Score
  - Motor Precision Score
  - Sustained Attention Score
  - Fatigue Drift
  - Dyslexia subtype risk classification
"""

from __future__ import annotations

import math
import statistics
from typing import Any, Optional


# ---------------------------------------------------------------------------
# Cognitive Index Tags — maps activity template types to cognitive domains
# ---------------------------------------------------------------------------
VISUAL_SKILLS_TEMPLATES = {
    "hidden_picture_game",
    "spot_difference",
    "shape_match",
    "visual_tracking",
    "pattern_completion",
}

PHONOLOGICAL_TEMPLATES = {
    "syllable_tap",
    "word_match",
    "letter_sound",
    "rhyme_sort",
    "phoneme_blend",
}

MOTOR_TEMPLATES = {
    "trace_letter",
    "drag_drop",
    "connect_dots",
    "shape_trace",
}


# ---------------------------------------------------------------------------
# Feature Extraction
# ---------------------------------------------------------------------------

def extract_features(events: list[dict[str, Any]]) -> dict[str, float]:
    """
    Compute the 6-dimensional cognitive feature vector from a list of
    raw TelemetryEvent dicts (as stored in MongoDB).

    Returns a dict with keys:
        visual_processing_speed   — higher = faster visual search
        motor_precision           — 0-100, penalised for misclicks
        hesitation_ratio          — average hesitations per round
        accuracy_slope            — linear trend in correctness (positive = improving)
        phonological_latency      — avg first-touch latency on phonological activities
        fatigue_drift             — latency difference between last-3 vs first-3 rounds
    """
    if not events:
        return _zero_features()

    n = len(events)

    # ---- Visual Processing Speed -------------------------------------------
    visual_events = [e for e in events if e.get("activity_name") in VISUAL_SKILLS_TEMPLATES]
    if visual_events:
        avg_ftl = statistics.mean(
            e.get("first_touch_latency_ms", 1500) for e in visual_events
        )
        # Invert: lower latency → higher score. Baseline = 2000 ms
        visual_processing_speed = max(0.0, min(100.0, (2000 - avg_ftl) / 20))
    else:
        visual_processing_speed = 50.0  # neutral when no data

    # ---- Motor Precision Score ----------------------------------------------
    total_taps = sum(
        len(e.get("touch_path", [])) for e in events
    )
    total_misclicks = sum(e.get("misclick_count", 0) for e in events)
    if total_taps > 0:
        motor_precision = max(0.0, (1 - total_misclicks / total_taps) * 100)
    else:
        motor_precision = 100.0  # default if no touch data

    # ---- Cognitive Hesitation Ratio ----------------------------------------
    hesitation_ratio = statistics.mean(
        e.get("hesitation_count", 0) for e in events
    )

    # ---- Accuracy Slope (linear regression) --------------------------------
    if n >= 2:
        scores = [e.get("score", 0) for e in events]
        x_mean = (n - 1) / 2
        y_mean = statistics.mean(scores)
        numerator = sum((i - x_mean) * (scores[i] - y_mean) for i in range(n))
        denominator = sum((i - x_mean) ** 2 for i in range(n))
        accuracy_slope = numerator / denominator if denominator != 0 else 0.0
    else:
        accuracy_slope = 0.0

    # ---- Phonological Latency ----------------------------------------------
    phono_events = [e for e in events if e.get("activity_name") in PHONOLOGICAL_TEMPLATES]
    if phono_events:
        phonological_latency = statistics.mean(
            e.get("first_touch_latency_ms", 1500) for e in phono_events
        )
    else:
        phonological_latency = 1500.0  # neutral baseline

    # ---- Fatigue Drift (last-3 vs first-3 latency delta) -------------------
    if n >= 6:
        early_latency = statistics.mean(
            e.get("total_round_latency_ms", 0) for e in events[:3]
        )
        late_latency = statistics.mean(
            e.get("total_round_latency_ms", 0) for e in events[-3:]
        )
        fatigue_drift = late_latency - early_latency  # positive = slowing down
    else:
        fatigue_drift = 0.0

    return {
        "visual_processing_speed": round(visual_processing_speed, 2),
        "motor_precision": round(motor_precision, 2),
        "hesitation_ratio": round(hesitation_ratio, 3),
        "accuracy_slope": round(accuracy_slope, 3),
        "phonological_latency": round(phonological_latency, 2),
        "fatigue_drift": round(fatigue_drift, 2),
    }


# ---------------------------------------------------------------------------
# Cognitive Index Computation (0-100 scores for each domain)
# ---------------------------------------------------------------------------

def compute_cognitive_indices(features: dict[str, float]) -> dict[str, float]:
    """
    Convert raw feature vector into normalized 0-100 cognitive index scores
    for presentation in the parent analytics dashboard.
    """
    visual_processing_score = _clamp(features["visual_processing_speed"])

    # Motor precision is already 0-100
    motor_precision_score = _clamp(features["motor_precision"])

    # Phonological score: invert latency (2500ms baseline)
    phonological_latency = features["phonological_latency"]
    phonological_awareness_score = _clamp((2500 - phonological_latency) / 25)

    # Sustained attention: penalise hesitation ratio; cap at 4 hesitations per round
    sustained_attention_score = _clamp(100 - (features["hesitation_ratio"] / 4) * 100)

    return {
        "visual_processing_score": round(visual_processing_score, 1),
        "phonological_awareness_score": round(phonological_awareness_score, 1),
        "motor_precision_score": round(motor_precision_score, 1),
        "sustained_attention_score": round(sustained_attention_score, 1),
    }


# ---------------------------------------------------------------------------
# Risk Classifier — Rule-Based (upgradeable to sklearn RandomForest)
# ---------------------------------------------------------------------------

def classify_risk(
    features: dict[str, float],
    indices: dict[str, float],
) -> dict[str, str]:
    """
    Classify dyslexia subtype risk levels from feature vector and cognitive indices.

    Risk categories: 'Low' | 'Moderate' | 'High'

    This uses interpretable rule-based thresholds derived from educational
    psychology research on early childhood learning difficulty indicators.
    Intended to be replaced / enhanced with a trained sklearn model once
    enough labelled data accumulates.
    """
    visual_risk = _threshold_risk(
        score=indices["visual_processing_score"],
        high_threshold=40,
        moderate_threshold=65,
    )
    phonological_risk = _threshold_risk(
        score=indices["phonological_awareness_score"],
        high_threshold=40,
        moderate_threshold=65,
    )
    motor_risk = _threshold_risk(
        score=indices["motor_precision_score"],
        high_threshold=50,
        moderate_threshold=72,
    )
    attention_risk = _threshold_risk(
        score=indices["sustained_attention_score"],
        high_threshold=45,
        moderate_threshold=68,
    )

    # Overall risk — highest individual component risk determines overall
    risk_levels = [visual_risk, phonological_risk, motor_risk, attention_risk]
    if "High" in risk_levels:
        overall = "Needs Attention"
    elif risk_levels.count("Moderate") >= 2:
        overall = "Moderate Risk"
    else:
        overall = "Low Risk"

    return {
        "overall_risk": overall,
        "visual_dyslexia_risk": visual_risk,
        "phonological_dyslexia_risk": phonological_risk,
        "motor_dysgraphia_risk": motor_risk,
        "attention_risk": attention_risk,
    }


# ---------------------------------------------------------------------------
# Intervention Recommendation Engine
# ---------------------------------------------------------------------------

def generate_interventions(
    risk: dict[str, str],
    features: dict[str, float],
) -> list[str]:
    """
    Generate a list of personalized skill-specific intervention recommendations
    based on the child's risk profile.
    """
    interventions: list[str] = []

    if risk["visual_dyslexia_risk"] in ("Moderate", "High"):
        interventions.append(
            "Increase practice on Visual Skills (Skills 1 & 2) — "
            "Spot the Difference and Hidden Picture activities improve visual scanning."
        )

    if risk["phonological_dyslexia_risk"] in ("Moderate", "High"):
        interventions.append(
            "Focus on Phonological Awareness activities (Skills 5 & 6) — "
            "Syllable tapping and letter-sound matching exercises strengthen phonemic awareness."
        )

    if risk["motor_dysgraphia_risk"] in ("Moderate", "High"):
        interventions.append(
            "Practice Letter Tracing activities (Skill 3) — "
            "Fine motor control exercises improve pen grip and letter formation."
        )

    if risk["attention_risk"] in ("Moderate", "High"):
        interventions.append(
            "Consider shorter, more frequent learning sessions (5-10 minutes) "
            "to reduce cognitive fatigue and improve sustained attention."
        )

    if features["fatigue_drift"] > 1500:
        interventions.append(
            "The child shows significant fatigue during longer activity sessions. "
            "Enabling the Daily Limit feature is recommended."
        )

    if features["accuracy_slope"] < -2.0:
        interventions.append(
            "Accuracy tends to decline across rounds within a session — "
            "this may indicate frustration or difficulty. Consider enabling easier levels."
        )

    if not interventions:
        interventions.append(
            "Great progress! Continue the current learning plan. "
            "Review completed skills weekly to reinforce retention."
        )

    return interventions


# ---------------------------------------------------------------------------
# Full Pipeline Entry Point
# ---------------------------------------------------------------------------

def run_pipeline(telemetry_sessions: list[dict[str, Any]]) -> dict[str, Any]:
    """
    Full end-to-end ML analytics pipeline.

    Args:
        telemetry_sessions: List of raw telemetry session documents from MongoDB,
                            each containing an `events` list of TelemetryEvent dicts.

    Returns:
        Cognitive profile dict ready for storage in `cognitive_profiles` collection.
    """
    # Flatten all events across all sessions
    all_events: list[dict[str, Any]] = []
    for session in telemetry_sessions:
        all_events.extend(session.get("events", []))

    features = extract_features(all_events)
    indices = compute_cognitive_indices(features)
    risk = classify_risk(features, indices)
    interventions = generate_interventions(risk, features)

    return {
        "feature_vector": features,
        "cognitive_indices": indices,
        "risk_assessment": risk,
        "recommended_interventions": interventions,
        "data_points": len(all_events),
    }


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _clamp(value: float, lo: float = 0.0, hi: float = 100.0) -> float:
    return max(lo, min(hi, value))


def _threshold_risk(score: float, high_threshold: float, moderate_threshold: float) -> str:
    if score < high_threshold:
        return "High"
    if score < moderate_threshold:
        return "Moderate"
    return "Low"


def _zero_features() -> dict[str, float]:
    return {
        "visual_processing_speed": 50.0,
        "motor_precision": 100.0,
        "hesitation_ratio": 0.0,
        "accuracy_slope": 0.0,
        "phonological_latency": 1500.0,
        "fatigue_drift": 0.0,
    }
