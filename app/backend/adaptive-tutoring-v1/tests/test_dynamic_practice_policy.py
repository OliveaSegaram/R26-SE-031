from services.dynamic_practice_policy import DynamicPracticePolicy
from services.item_selector import ItemSelector


def _complete(
    policy,
    state,
    *,
    role,
    quality,
    current_item,
):
    return policy.get_next_action(
        activity_id="2.2",
        current_item_id=current_item,
        item_role=role,
        response_quality=quality,
        current_b=0.5,
        state=state,
        error_profile={
            "equivalent_group_id": "S2A2R04",
            "target_units": ["ස", "ර"],
            "component_units": ["ස", "ර", "ලි", "දු"],
            "error_tags": ["letter_matching"],
            "diagnostic_confidence": 1.0,
        },
        policy_reason=[],
        has_reduced_remediation=True,
        has_floor_remediation=False,
    )


def test_activity_two_isolates_one_diagnosed_unit_without_extra_target_pair():
    policy = DynamicPracticePolicy()
    state = {"next_phase": "CORE"}

    core = _complete(
        policy,
        state,
        role="CORE",
        quality="ASSISTED_SUCCESS",
        current_item="S2A2R04",
    )
    assert core["next_phase"] == "REMEDIATION"
    assert core["selection_intent"]["target_units"] == ["ස"]
    assert state["practice_remediation_units"] == ["ස"]
    assert state["practice_confirmation_units"] == ["ස"]

    remediation = _complete(
        policy,
        state,
        role="REMEDIATION",
        quality="CLEAN_SUCCESS",
        current_item="S2A2R04V7",
    )
    assert remediation["next_phase"] == "CONFIRMATION"
    assert remediation["selection_intent"]["target_units"] == ["ස"]

    confirmation = _complete(
        policy,
        state,
        role="CONFIRMATION",
        quality="CLEAN_SUCCESS",
        current_item="S2A2R04V8",
    )
    assert confirmation["next_phase"] == "CORE"
    assert "practice_origin_item_id" not in state


def test_activity_two_runs_generic_v1_v2_after_targeted_pair_needed_support():
    policy = DynamicPracticePolicy()
    state = {"next_phase": "CORE"}

    _complete(
        policy,
        state,
        role="CORE",
        quality="ASSISTED_SUCCESS",
        current_item="S2A2R05",
    )
    targeted_remediation = _complete(
        policy,
        state,
        role="REMEDIATION",
        quality="ASSISTED_SUCCESS",
        current_item="S2A2R05V3",
    )
    assert targeted_remediation["next_phase"] == "CONFIRMATION"
    assert targeted_remediation["selection_intent"]["target_units"] == ["ස"]

    targeted_confirmation = _complete(
        policy,
        state,
        role="CONFIRMATION",
        quality="CLEAN_SUCCESS",
        current_item="S2A2R05V4",
    )
    assert targeted_confirmation["next_phase"] == "REMEDIATION"
    assert targeted_confirmation["selection_intent"][
        "generic_authored_fallback"
    ] is True
    assert targeted_confirmation["selection_intent"]["target_units"] == []

    generic_remediation = _complete(
        policy,
        state,
        role="REMEDIATION",
        quality="CLEAN_SUCCESS",
        current_item="S2A2R05V1",
    )
    assert generic_remediation["next_phase"] == "CONFIRMATION"
    assert generic_remediation["selection_intent"][
        "generic_authored_fallback"
    ] is True

    generic_confirmation = _complete(
        policy,
        state,
        role="CONFIRMATION",
        quality="CLEAN_SUCCESS",
        current_item="S2A2R05V2",
    )
    assert generic_confirmation["next_phase"] == "CORE"
    assert "practice_origin_item_id" not in state


def test_generic_fallback_selects_authored_v1_v2_not_another_targeted_item():
    selector = ItemSelector()
    candidates = []
    for item_id, role, targeted in (
        ("S2A2R05V1", "REMEDIATION", False),
        ("S2A2R05V2", "CONFIRMATION", False),
        ("S2A2R05V3", "REMEDIATION", True),
        ("S2A2R05V4", "CONFIRMATION", True),
    ):
        candidates.append({
            "item_id": item_id,
            "activity_id": "2.2",
            "knowledge_component_id": "KC_LETTER_MATCHING",
            "equivalent_group_id": "S2A2R05",
            "item_role": role,
            "is_core": False,
            "is_active": True,
            "targeted_practice": targeted,
            "targeted_unit": "න" if targeted else None,
            "difficulty_b": 0.5 if role == "REMEDIATION" else 1.0,
            "content": {"letters": ["න", "පා", "බ", "මු", "ය"]},
        })

    common = {
        "current_item_id": "S2A2R05V4",
        "current_activity": "2.2",
        "knowledge_component_id": "KC_LETTER_MATCHING",
        "candidates": candidates,
        "excluded_item_ids": [],
        "exposure_counts": {},
        "micro_skill_evidence": {},
        "requested_mode": "simulation_model",
        "data_origin": "observed",
    }
    remediation = selector.select_targeted_practice_item(
        target_difficulty=0.5,
        selection_intent={
            "role": "REMEDIATION",
            "origin_equivalent_group_id": "S2A2R05",
            "target_units": [],
            "generic_authored_fallback": True,
        },
        **common,
    )
    confirmation = selector.select_targeted_practice_item(
        target_difficulty=1.0,
        selection_intent={
            "role": "CONFIRMATION",
            "origin_equivalent_group_id": "S2A2R05",
            "target_units": [],
            "generic_authored_fallback": True,
        },
        **common,
    )

    assert remediation["selected_item"] == "S2A2R05V1"
    assert confirmation["selected_item"] == "S2A2R05V2"
    assert remediation["candidate_scope"] == "SAME_ORIGIN_GENERIC_FALLBACK"
    assert confirmation["candidate_scope"] == "SAME_ORIGIN_GENERIC_FALLBACK"
