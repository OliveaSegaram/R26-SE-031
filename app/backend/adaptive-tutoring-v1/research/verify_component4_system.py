"""Offline acceptance check for the Component 4 item and policy pipeline.

This command performs no database writes. It proves that the authored Skills
1–4 bank is structurally complete and that the synthetic research model can
choose and safely translate different supports for different task families.
It is functional verification, not evidence of learning efficacy.
"""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from types import SimpleNamespace
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from item_bank_builder import build_items, validation_summary  # noqa: E402
from services.action_policy_model import (  # noqa: E402
    ActionPolicyModel,
    context_features,
)
from services.policy_engine import PolicyEngine  # noqa: E402


SKILLS_IN_SCOPE = {"skill_1", "skill_2", "skill_3", "skill_4"}


def _verify_bank() -> dict[str, Any]:
    items = build_items()
    summary = validation_summary(items)
    active = [
        item
        for item in items
        if item["is_active"] and item["skill_id"] in SKILLS_IN_SCOPE
    ]
    groups: dict[str, set[str]] = defaultdict(set)
    for item in active:
        groups[item["equivalent_group_id"]].add(item["item_role"])

    missing_confirmation = sorted(
        group_id
        for group_id, roles in groups.items()
        if "CORE" in roles and "CONFIRMATION" not in roles
    )
    invalid_groups = sorted(
        group_id
        for group_id, roles in groups.items()
        if "CORE" not in roles or not roles.issubset(
            {"CORE", "REMEDIATION", "CONFIRMATION"}
        )
    )
    blockers = {
        "duplicate_variants": summary["duplicate_variants"],
        "unknown_kc": summary["unknown_kc"],
        "runtime_generated_items": summary["runtime_generated_items"],
        "missing_confirmation_groups": missing_confirmation,
        "invalid_equivalent_groups": invalid_groups,
    }
    if any(bool(value) for value in blockers.values()):
        raise AssertionError(f"Item-bank acceptance failed: {blockers}")

    role_counts = Counter(item["item_role"] for item in active)
    return {
        "status": "PASS",
        "skills": "1-4",
        "active_items": len(active),
        "core_items": role_counts["CORE"],
        "remediation_items": role_counts["REMEDIATION"],
        "confirmation_items": role_counts["CONFIRMATION"],
        "equivalent_groups": len(groups),
        "shared_floor_retry_groups": sum(
            1
            for roles in groups.values()
            if roles == {"CORE", "CONFIRMATION"}
        ),
        "blockers": blockers,
    }


def _scenario_telemetry(spec: dict[str, Any]) -> SimpleNamespace:
    option_count = spec["options"]
    return SimpleNamespace(
        supported_actions=spec["capabilities"],
        original_options_count=option_count,
        minimum_visible_options=2,
        visible_option_ids=[f"OPTION_{index}" for index in range(1, option_count + 1)],
        correct_option_ids=["OPTION_1"],
        total_round_latency_ms=spec["latency_ms"],
        attempt_count=spec.get("attempts", 2),
        incorrect_attempt_count=spec.get("incorrect_attempts", 1),
        hesitation_count=spec["hesitations"],
        misclick_count=1,
        audio_replay_count=spec.get("audio_replays", 0),
    )


def _verify_policy() -> dict[str, Any]:
    model = ActionPolicyModel()
    engine = PolicyEngine()
    scenarios = {
        "visual_choice": {
            "capabilities": ["REMOVE_OPTION", "HIGHLIGHT_OPTION"],
            "options": 4,
            "latency_ms": 3500,
            "hesitations": 0,
            "mastery": 0.45,
            "struggle": 2,
            "baseline": "SCAFFOLD_REMOVE_DISTRACTOR",
        },
        "audio_listening": {
            "capabilities": [
                "HIGHLIGHT_OPTION",
                "REPLAY_INSTRUCTION",
                "SLOW_AUDIO",
            ],
            "options": 4,
            "latency_ms": 15000,
            "hesitations": 0,
            "audio_replays": 2,
            "attempts": 3,
            "incorrect_attempts": 2,
            "mastery": 0.10,
            "struggle": 2,
            "fatigue": 0.10,
            "baseline": "SCAFFOLD_HIGHLIGHT_CORRECT",
        },
        "sorting": {
            "capabilities": [
                "HIGHLIGHT_DESTINATION",
                "SHOW_WORKED_EXAMPLE",
                "REPLAY_INSTRUCTION",
            ],
            "options": 3,
            "latency_ms": 15000,
            "hesitations": 0,
            "attempts": 3,
            "incorrect_attempts": 2,
            "mastery": 0.10,
            "struggle": 2,
            "fatigue": 0.50,
            "baseline": "SCAFFOLD_HIGHLIGHT_DESTINATION",
        },
        "sequence": {
            "capabilities": ["REVEAL_FIRST_TOKEN"],
            "options": 5,
            "latency_ms": 9000,
            "hesitations": 1,
            "mastery": 0.50,
            "struggle": 3,
            "baseline": "SCAFFOLD_REVEAL_FIRST_TOKEN",
        },
    }

    results: dict[str, Any] = {}
    for name, spec in scenarios.items():
        telemetry = _scenario_telemetry(spec)
        features = context_features(
            telemetry=telemetry,
            struggle_score=spec["struggle"],
            mastery=spec["mastery"],
            difficulty_b=0.2,
            fatigue=spec.get("fatigue", 0.2),
            behavioral_context={
                "first_attempt_accuracy": 0.40,
                "support_rate": 0.40,
            },
            learner_profile={},
        )
        decision = model.evaluate(
            baseline_action=spec["baseline"],
            telemetry=telemetry,
            features=features,
            requested_mode="simulation_model",
            data_origin="observed",
            assignment_key=f"offline-verification:{name}",
        )
        translated = engine.translate_model_support_action(
            action=decision["applied_action"],
            telemetry=telemetry,
            available_incorrect_ids=telemetry.visible_option_ids[1:],
            adaptive_state={},
        )
        if decision["applied_action"] not in decision["candidate_actions"]:
            raise AssertionError(f"{name}: model selected unsupported action")
        if not decision["controls_live_adaptation"]:
            raise AssertionError(f"{name}: simulation model did not control")
        if translated["decision"] != decision["applied_action"]:
            raise AssertionError(f"{name}: safe translator rejected selected action")
        if not translated["commands"]:
            raise AssertionError(f"{name}: selected support produced no command")

        results[name] = {
            "candidate_actions": decision["candidate_actions"],
            "predicted_success": decision["predicted_next_independent_success"],
            "utility_after_support_cost": decision["action_utilities"],
            "selected_action": decision["applied_action"],
            "rendered_command": translated["commands"][0]["type"],
            "execution_source": decision["execution_source"],
        }

    if len({result["selected_action"] for result in results.values()}) < 4:
        raise AssertionError("Verification contexts did not produce four distinct supports")

    return {
        "status": "PASS",
        "model_version": model.artifact.get("model_version"),
        "validation_status": model.artifact.get("validation_status"),
        "activation_allowed_for_observed_children": model.artifact.get(
            "activation_allowed", False
        ),
        "simulation_disclosure": (
            "Functional synthetic-model verification only; not efficacy evidence."
        ),
        "task_family_results": results,
    }


def main() -> None:
    result = {
        "component": "C4_ADAPTIVE_TUTORING",
        "overall_status": "PASS",
        "item_bank": _verify_bank(),
        "functional_ml_simulation": _verify_policy(),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
