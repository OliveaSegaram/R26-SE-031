from types import SimpleNamespace

from services.policy_engine import PolicyEngine


def telemetry(**overrides):
    values = {
        "supported_actions": ["REMOVE_OPTION", "HIGHLIGHT_OPTION"],
        "visible_option_ids": ["ITEM_O1", "ITEM_O2", "ITEM_O3", "ITEM_O4"],
        "correct_option_ids": ["ITEM_O1"],
        "minimum_visible_options": 2,
    }
    values.update(overrides)
    return SimpleNamespace(**values)


def test_capability_policy_escalates_deterministically_and_preserves_two_choices():
    engine = PolicyEngine()
    state = {}

    first = engine.get_support_action(
        telemetry(), 4, 0, ["ITEM_O2", "ITEM_O3", "ITEM_O4"], state, "3.1", 1
    )
    second = engine.get_support_action(
        telemetry(), 4, 0, ["ITEM_O2", "ITEM_O3", "ITEM_O4"], state, "3.1", 1
    )
    third = engine.get_support_action(
        telemetry(), 4, 0, ["ITEM_O2", "ITEM_O3", "ITEM_O4"], state, "3.1", 1
    )

    assert first["commands"][0]["target_option_ids"] == ["ITEM_O2"]
    assert second["commands"][0]["target_option_ids"] == ["ITEM_O3"]
    assert third["commands"][0]["type"] == "HIGHLIGHT_OPTIONS"
    assert third["commands"][0]["target_option_ids"] == ["ITEM_O1"]
    assert state["generic_scaffold_state"]["removed_option_ids"] == [
        "ITEM_O2",
        "ITEM_O3",
    ]


def test_policy_uses_only_capabilities_advertised_by_the_activity():
    engine = PolicyEngine()
    state = {}
    action = engine.get_support_action(
        telemetry(
            supported_actions=["REPLAY_INSTRUCTION"],
            correct_option_ids=[],
        ),
        0,
        0,
        [],
        state,
        "6.1",
        1,
    )

    assert action["commands"][0]["type"] == "REPLAY_INSTRUCTION"
    assert action["policy_version"] == "C4_CAPABILITY_POLICY_V2"
    assert action["action_id"].startswith("c4-")

