"""
services/feature_engineering.py
================================
Advanced feature extraction for the 18-dimensional cognitive feature vector.
Extends the base 6 features from ml_pipeline.py with 10 derived behavioral metrics.
"""

import math
import statistics
import numpy as np
from typing import List, Dict, Any
from sklearn.cluster import DBSCAN


def compute_scan_path_length(touch_path: List[Dict]) -> float:
    """Sum of Euclidean distances between consecutive touch points."""
    if len(touch_path) < 2:
        return 0.0
    total = 0.0
    for i in range(1, len(touch_path)):
        dx = touch_path[i].get("x_ratio", 0) - touch_path[i-1].get("x_ratio", 0)
        dy = touch_path[i].get("y_ratio", 0) - touch_path[i-1].get("y_ratio", 0)
        total += math.sqrt(dx*dx + dy*dy)
    return round(total, 4)


def compute_regression_count(touch_path: List[Dict]) -> int:
    """Count backward horizontal movements (re-reading indicators)."""
    count = 0
    for i in range(1, len(touch_path)):
        if touch_path[i].get("x_ratio", 0) < touch_path[i-1].get("x_ratio", 0) - 0.02:
            count += 1
    return count


def compute_response_consistency(latencies: List[int]) -> float:
    """Standard deviation of round latencies — erratic timing = attention issues."""
    if len(latencies) < 2:
        return 0.0
    return round(statistics.stdev(latencies), 2)


def compute_coefficient_of_variation(values: List[float]) -> float:
    """CV = stdev/mean — measures relative variability."""
    if len(values) < 2:
        return 0.0
    mean = statistics.mean(values)
    if mean == 0:
        return 0.0
    return round(statistics.stdev(values) / mean, 4)


def compute_touch_cluster_count(touch_path: List[Dict]) -> int:
    """DBSCAN clustering on touch coordinates to find fixation areas."""
    if len(touch_path) < 3:
        return 0
    coords = np.array([[p.get("x_ratio", 0), p.get("y_ratio", 0)] for p in touch_path])
    clustering = DBSCAN(eps=0.05, min_samples=3).fit(coords)
    n_clusters = len(set(clustering.labels_)) - (1 if -1 in clustering.labels_ else 0)
    return n_clusters


def extract_advanced_features(all_events: List[Dict]) -> Dict[str, float]:
    """
    Compute the 10 additional derived features from raw telemetry events.
    These are appended to the base features.
    """
    if not all_events:
        return _zero_advanced()

    # Flatten all touch paths
    all_touch_points = []
    all_latencies = []
    all_first_touch = []
    total_rounds = len(all_events)
    total_abandoned = 0
    total_audio_replays = 0
    misclick_per_session = []

    for e in all_events:
        path = e.get("touch_path", [])
        all_touch_points.extend(path)
        all_latencies.append(e.get("total_round_latency_ms", 0))
        ftl = e.get("first_touch_latency_ms", 0)
        if ftl > 0:
            all_first_touch.append(ftl)
        if e.get("is_abandoned", False):
            total_abandoned += 1
        total_audio_replays += e.get("audio_replay_count", 0)
        misclick_per_session.append(e.get("misclick_count", 0))

    # Feature 9: Scan Path Length
    scan_path_length = compute_scan_path_length(all_touch_points)

    # Feature 10: Regression Count
    touch_regression_count = compute_regression_count(all_touch_points)

    # Feature 11: Response Consistency
    response_consistency = compute_response_consistency(all_latencies)

    # Feature 12: First-Touch Variability
    first_touch_variability = compute_coefficient_of_variation(
        [float(x) for x in all_first_touch]
    )

    # Feature 13: Abandonment Rate
    abandonment_rate = round(total_abandoned / max(total_rounds, 1), 4)

    # Feature 14: Audio Dependency Score
    audio_dependency_score = round(total_audio_replays / max(total_rounds, 1), 4)

    # Feature 15: Misclick Trend Slope
    if len(misclick_per_session) >= 2:
        n = len(misclick_per_session)
        x_mean = (n - 1) / 2
        y_mean = statistics.mean(misclick_per_session)
        num = sum((i - x_mean) * (misclick_per_session[i] - y_mean) for i in range(n))
        den = sum((i - x_mean) ** 2 for i in range(n))
        misclick_trend_slope = num / den if den != 0 else 0.0
    else:
        misclick_trend_slope = 0.0

    # Feature 16: Session Duration Ratio (actual / expected ~300s)
    total_time = sum(all_latencies) / 1000.0  # convert ms to seconds
    expected_time = total_rounds * 15.0  # ~15s expected per round
    session_duration_ratio = round(
        total_time / max(expected_time, 1.0), 4
    )

    # Feature 18: Touch Cluster Count
    touch_cluster_count = compute_touch_cluster_count(all_touch_points)

    return {
        "scan_path_length": scan_path_length,
        "touch_regression_count": touch_regression_count,
        "response_consistency": response_consistency,
        "first_touch_variability": first_touch_variability,
        "abandonment_rate": abandonment_rate,
        "audio_dependency_score": audio_dependency_score,
        "misclick_trend_slope": round(misclick_trend_slope, 4),
        "session_duration_ratio": session_duration_ratio,
        "touch_cluster_count": touch_cluster_count,
    }


def _zero_advanced() -> Dict[str, float]:
    return {
        "scan_path_length": 0.0,
        "touch_regression_count": 0.0,
        "response_consistency": 0.0,
        "first_touch_variability": 0.0,
        "abandonment_rate": 0.0,
        "audio_dependency_score": 0.0,
        "misclick_trend_slope": 0.0,
        "session_duration_ratio": 1.0,
        "touch_cluster_count": 0.0,
    }
