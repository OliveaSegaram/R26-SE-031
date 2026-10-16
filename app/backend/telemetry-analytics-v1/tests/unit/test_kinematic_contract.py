from routers.telemetry import _kinematic_events
from services.comp2_kinematics import extract_comp2_features


def test_flutter_touch_path_is_normalized_into_c2_features():
    events = _kinematic_events([{
        "is_correct": False,
        "targets": ["බ"],
        "selected_answers": ["ඩ"],
        "touch_path": [
            {"x_ratio": 0.1, "y_ratio": 0.2, "timestamp_ms": 900, "type": "down"},
            {"x_ratio": 0.3, "y_ratio": 0.4, "timestamp_ms": 1000, "type": "move"},
            {"x_ratio": 0.5, "y_ratio": 0.6, "timestamp_ms": 1100, "type": "move"},
            {"x_ratio": 0.7, "y_ratio": 0.8, "timestamp_ms": 1200, "type": "up"},
        ],
    }])
    assert events[0]["touch_stream"][0] == {
        "x": 0.1,
        "y": 0.2,
        "t": 900,
        "type": "DOWN",
    }
    features = extract_comp2_features(events)
    assert features["time_to_first_touch_ms"] == 900.0
    assert features["mean_dwell_time_ms"] == 300.0
    assert features["orthographic_confusion_index"] > 0.99
