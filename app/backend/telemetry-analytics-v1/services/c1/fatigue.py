import yaml
import os

def _load_config():
    config_path = os.path.join(os.path.dirname(__file__), "..", "..", "config", "thresholds.yaml")
    if not os.path.exists(config_path):
        return {}
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

CONFIG = _load_config()

def calculate_fatigue_score(latency_drift: float, error_drift: float, hesitation_drift: float) -> float:
    # A simple ensemble scoring based on available drifts
    score = 0.0
    valid = 0
    if latency_drift is not None:
        score += max(0.0, latency_drift)
        valid += 1
    if error_drift is not None:
        score += max(0.0, error_drift)
        valid += 1
    if hesitation_drift is not None:
        score += max(0.0, hesitation_drift)
        valid += 1
    
    if valid == 0:
        return 0.0
        
    return min(1.0, score / valid)

def get_fatigue_state(score: float) -> str:
    cfg = CONFIG.get("fatigue", {"low_max": 0.30, "moderate_max": 0.60, "high_max": 0.80})
    if score <= cfg["low_max"]:
        return "LOW"
    elif score <= cfg["moderate_max"]:
        return "MODERATE"
    elif score <= cfg["high_max"]:
        return "HIGH"
    return "VERY_HIGH"
