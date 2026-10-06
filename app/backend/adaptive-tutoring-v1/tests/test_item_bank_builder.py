from item_bank_builder import build_items, normalize_item_id, validation_summary


def test_item_bank_is_canonical_complete_and_research_ready():
    items = build_items()
    summary = validation_summary(items)
    ids = [item["item_id"] for item in items]

    assert len(ids) == len(set(ids))
    assert summary["total_items"] >= 150
    assert summary["active_items"] >= 140
    assert summary["unknown_kc"] == 0
    assert summary["runtime_generated_items"] == 20
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
    assert exact_duplicates
    assert all(not item["is_active"] for item in exact_duplicates)
    assert all(
        item["validation"]["review_status"] == "needs_content_revision"
        for item in exact_duplicates
    )


def test_historical_item_ids_normalize_to_one_stable_format():
    assert normalize_item_id("S2_A1_R1") == "S2A1R01"
    assert normalize_item_id("s3-a4-r05v2") == "S3A4R05V2"


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
