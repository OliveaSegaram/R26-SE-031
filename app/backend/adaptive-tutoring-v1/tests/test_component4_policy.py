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


def test_memory_removes_when_safe_then_highlights_at_two_cards():
    engine = PolicyEngine()
    two_card_state = {}
    two_card_memory = telemetry(
        supported_actions=["DISABLE_OPTION", "HIGHLIGHT_OPTION"],
        visible_option_ids=["MEMORY_O1", "MEMORY_O2"],
        correct_option_ids=["MEMORY_O1"],
        minimum_visible_options=2,
    )

    first_task = engine.get_support_action(
        two_card_memory, 2, 0, ["MEMORY_O2"], two_card_state, "1.5", 1
    )
    assert first_task["commands"][0]["type"] == "HIGHLIGHT_OPTIONS"
    assert first_task["commands"][0]["target_option_ids"] == ["MEMORY_O1"]

    three_card_state = {}
    three_card_memory = telemetry(
        supported_actions=["DISABLE_OPTION", "HIGHLIGHT_OPTION"],
        visible_option_ids=["MEMORY_O1", "MEMORY_O2", "MEMORY_O3"],
        correct_option_ids=["MEMORY_O1"],
        minimum_visible_options=2,
    )
    remove = engine.get_support_action(
        three_card_memory,
        3,
        0,
        ["MEMORY_O2", "MEMORY_O3"],
        three_card_state,
        "1.5",
        2,
    )
    highlight = engine.get_support_action(
        three_card_memory,
        3,
        0,
        ["MEMORY_O2", "MEMORY_O3"],
        three_card_state,
        "1.5",
        2,
    )

    assert remove["commands"][0]["type"] == "DISABLE_OPTIONS"
    assert remove["commands"][0]["target_option_ids"] == ["MEMORY_O2"]
    assert highlight["commands"][0]["type"] == "HIGHLIGHT_OPTIONS"
    assert highlight["commands"][0]["target_option_ids"] == ["MEMORY_O1"]


def test_five_card_memory_removes_at_most_two_then_highlights():
    engine = PolicyEngine()
    state = {}
    memory = telemetry(
        supported_actions=["DISABLE_OPTION", "HIGHLIGHT_OPTION"],
        visible_option_ids=[
            "MEMORY_O1",
            "MEMORY_O2",
            "MEMORY_O3",
            "MEMORY_O4",
            "MEMORY_O5",
        ],
        correct_option_ids=["MEMORY_O1"],
        minimum_visible_options=2,
    )
    distractors = ["MEMORY_O2", "MEMORY_O3", "MEMORY_O4", "MEMORY_O5"]

    first = engine.get_support_action(
        memory, 5, 0, distractors, state, "1.5", 5
    )
    second = engine.get_support_action(
        memory, 5, 0, distractors, state, "1.5", 5
    )
    third = engine.get_support_action(
        memory, 5, 0, distractors, state, "1.5", 5
    )

    assert first["commands"][0]["type"] == "DISABLE_OPTIONS"
    assert second["commands"][0]["type"] == "DISABLE_OPTIONS"
    assert third["commands"][0]["type"] == "HIGHLIGHT_OPTIONS"
    assert state["generic_scaffold_state"]["removed_option_ids"] == [
        "MEMORY_O2",
        "MEMORY_O3",
    ]


def test_sequence_policy_never_removes_a_future_required_token():
    engine = PolicyEngine()
    state = {}
    action = engine.get_support_action(
        telemetry(
            supported_actions=["REVEAL_FIRST_TOKEN", "HIGHLIGHT_OPTION"],
            correct_option_ids=["ITEM_O2"],
        ),
        4,
        0,
        [],
        state,
        "2.5",
        3,
    )

    assert action["commands"][0]["type"] == "REVEAL_FIRST_TOKEN"
    assert action["commands"][0]["target_option_ids"] == ["ITEM_O2"]
    assert action["remove_option_ids"] == []
