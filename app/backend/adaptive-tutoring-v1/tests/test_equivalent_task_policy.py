from services.equivalent_task_policy import EquivalentTaskPolicy


def decide(item_id: str, quality: str, state=None):
    return EquivalentTaskPolicy().get_next_action(
        activity_id="3.1",
        current_item_id=item_id,
        response_quality=quality,
        current_b=0.5,
        state={} if state is None else state,
        policy_reason=[f"RESPONSE_QUALITY: {quality}"],
    )


def test_assisted_core_uses_unseen_same_level_remediation():
    action = decide("S3A1R03", "ASSISTED_SUCCESS")
    assert action["next_item"] == "S3A1R03V1"
    assert action["next_phase"] == "REMEDIATION"
    assert action["target_difficulty"] == 0.5


def test_remediation_always_moves_to_distinct_confirmation():
    state = {"next_phase": "REMEDIATION"}
    action = decide("S3A1R03V1", "ASSISTED_SUCCESS", state)
    assert action["next_item"] == "S3A1R03V2"
    assert action["next_phase"] == "CONFIRMATION"
    assert action["confirmation_required"] is True


def test_clean_confirmation_returns_to_normal_core_selection():
    state = {"next_phase": "CONFIRMATION"}
    action = decide("S3A1R03V2", "CLEAN_SUCCESS", state)
    assert action["decision"] == "CONTINUE"
    assert action["next_item"] == ""
    assert state["next_phase"] == "CORE"
    assert "remediation_origin_item_id" not in state


def test_assisted_confirmation_is_bounded_and_flags_review():
    state = {"next_phase": "CONFIRMATION"}
    action = decide("S3A1R03V2", "ASSISTED_SUCCESS", state)
    assert action["decision"] == "CONTINUE"
    assert state["teacher_review_required"] is True
    assert state["teacher_review_item_id"] == "S3A1R03"


def test_struggled_but_independent_core_skips_remediation():
    action = decide("S3A1R03", "STRUGGLED_SUCCESS")
    assert action["next_item"] == "S3A1R03V2"
    assert action["next_phase"] == "CONFIRMATION"
