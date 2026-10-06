from item_bank_builder import build_items, normalize_item_id, validation_summary


def test_item_bank_is_canonical_complete_and_research_ready():
    items = build_items()
    summary = validation_summary(items)
    ids = [item["item_id"] for item in items]

    assert len(ids) == len(set(ids))
    assert summary["total_items"] >= 150
    assert summary["active_items"] >= 140
    assert summary["unknown_kc"] == 0
    assert summary["runtime_generated_items"] == 0
    assert all(item["allowed_scaffolds"] for item in items)
    assert all(-3.0 <= item["difficulty_b"] <= 3.0 for item in items)
    assert all(item["validation"]["age_band"] == "Grade 1" for item in items)
    assert all(item["validation"]["language"] == "si-LK" for item in items)
    skill_one_kcs = {
        item["knowledge_component_id"]
        for item in items
        if item["skill_id"] == "skill_1"
    }
    assert "KC_VISUAL_SUPPORT" not in skill_one_kcs
    assert "KC_VISUAL_IDENTIFICATION" in skill_one_kcs
    assert "KC_VISUAL_MEMORY" in skill_one_kcs


def test_variants_are_grouped_and_exact_duplicates_are_not_served():
    items = build_items()
    variants = [item for item in items if not item["is_core"]]
    exact_duplicates = [
        item for item in variants if item["validation"]["duplicate_of_core"]
    ]

    assert variants
    assert all(item["equivalent_group_id"] for item in variants)
    assert not exact_duplicates
    assert all(item["is_active"] for item in variants)


def test_every_skill_one_to_four_core_has_distinct_remediation_and_confirmation():
    items = build_items()
    scoped = [
        item for item in items
        if item["skill_id"] in {"skill_1", "skill_2", "skill_3", "skill_4"}
    ]
    by_id = {item["item_id"]: item for item in scoped}
    cores = [item for item in scoped if item["is_core"]]

    assert len(cores) == 97
    for core in cores:
        remediation = by_id[f'{core["item_id"]}V1']
        confirmation = by_id[f'{core["item_id"]}V2']
        assert remediation["item_role"] == "REMEDIATION"
        assert confirmation["item_role"] == "CONFIRMATION"
        assert remediation["difficulty_b"] == core["difficulty_b"]
        assert confirmation["difficulty_b"] == core["difficulty_b"]
        assert len({core["content_hash"], remediation["content_hash"], confirmation["content_hash"]}) == 3


def test_historical_item_ids_normalize_to_one_stable_format():
    assert normalize_item_id("S2_A1_R1") == "S2A1R01"
    assert normalize_item_id("s3-a4-r05v2") == "S3A4R05V2"


def test_pair_matching_variants_never_repeat_a_required_letter():
    pair_variants = [
        item for item in build_items()
        if item["activity_id"] == "2.2" and not item["is_core"]
    ]

    assert len(pair_variants) == 10
    for item in pair_variants:
        values = [
            option["value"] for option in item["options"]
            if option["role"] == "pair_target"
        ]
        assert len(values) == len(set(values)), item["item_id"]


def test_equivalent_tasks_preserve_core_response_load():
    items = build_items()
    by_id = {item["item_id"]: item for item in items}
    variants = [
        item for item in items
        if not item["is_core"]
        and item["skill_id"] in {"skill_1", "skill_2", "skill_3", "skill_4"}
    ]

    for variant in variants:
        core = by_id[variant["equivalent_group_id"]]
        assert len(variant["options"]) == len(core["options"]), variant["item_id"]


def test_hidden_search_items_have_stable_target_and_distractor_records():
    items = {
        item["item_id"]: item
        for item in build_items()
        if item["activity_id"] == "1.1" and item["is_core"]
    }

    assert [len(items[f"S1A1R0{round_number}"]["options"])
            for round_number in range(1, 6)] == [4, 7, 9, 12, 15]
    first = items["S1A1R01"]["options"]
    assert first[0]["option_id"] == "S1A1R01_T1"
    assert first[0]["role"] == "target"
    assert {option["role"] for option in first[1:]} == {"distractor"}
