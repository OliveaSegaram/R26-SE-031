import json
import unicodedata

from item_bank_builder import (
    DEFAULT_CURRICULUM_DIR,
    build_items,
    normalize_item_id,
    validation_summary,
)
from seed_item_bank import (
    remove_legacy_skill_two_activities_one_to_three_fields,
    remove_legacy_skill_two_activity_four_fields,
    remove_legacy_skill_two_activity_five_fields,
    remove_legacy_skill_three_fields,
    quarantine_superseded_skill_three_evidence,
    quarantine_superseded_skill_two_activity_one_evidence,
    quarantine_superseded_skill_two_activity_two_evidence,
    quarantine_superseded_skill_two_activity_three_evidence,
    quarantine_superseded_skill_two_activity_four_evidence,
    quarantine_superseded_skill_two_activity_five_evidence,
)


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
    inactive = [item for item in variants if not item["is_active"]]
    assert [item["item_id"] for item in inactive] == ["S3A5R01V1"]
    assert inactive[0]["single_floor_retry"] is True


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
        if core["has_reduced_remediation"]:
            if core["skill_id"] == "skill_3":
                assert remediation["difficulty_b"] <= core["difficulty_b"]
                assert remediation["remediation_strategy"] == (
                    "PREVIOUS_DIFFICULTY_LEVEL"
                )
            elif core["activity_id"] == "2.1":
                assert remediation["difficulty_b"] <= core["difficulty_b"]
                assert remediation["remediation_strategy"] in {
                    "FLOOR_REDUCED_CHOICES",
                    "PREVIOUS_DIFFICULTY_LEVEL",
                }
            else:
                assert remediation["difficulty_b"] < core["difficulty_b"]
            assert remediation["response_load_relation"] == "reduced"
        else:
            assert remediation["difficulty_b"] == core["difficulty_b"]
            assert remediation["response_load_relation"] == "equivalent"
        assert confirmation["difficulty_b"] == core["difficulty_b"]
        assert confirmation["response_load_relation"] == "equivalent"
        hashes = {
            core["content_hash"],
            remediation["content_hash"],
            confirmation["content_hash"],
        }
        if core["item_id"] == "S3A5R01":
            assert len(hashes) == 2
            assert remediation["content_hash"] == confirmation["content_hash"]
            assert remediation["is_active"] is False
            assert confirmation["is_active"] is True
            assert remediation["single_floor_retry"] is True
            assert confirmation["single_floor_retry"] is True
        else:
            assert len(hashes) == 3


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


def test_skill_one_sorting_never_classifies_ice_cream_as_fruit():
    sorting_items = [
        item for item in build_items()
        if item["activity_id"] == "1.3"
    ]

    assert sorting_items
    for item in sorting_items:
        fruit_assets = item["content"]["categories"].get("fruits", [])
        assert "fruits_food/ice_cream.png" not in fruit_assets, item["item_id"]


def test_skill_one_client_metadata_uses_the_same_official_kcs_as_item_bank():
    decoded = json.loads(
        (DEFAULT_CURRICULUM_DIR / "skill_1.json").read_text(encoding="utf-8")
    )
    activities = decoded[0]["activities"]
    expected = {
        "act_1": "KC_VISUAL_IDENTIFICATION",
        "act_2": "KC_VISUAL_MATCHING",
        "act_3": "KC_VISUAL_CATEGORIZATION",
        "act_4": "KC_VISUAL_PATTERN",
        "act_5": "KC_VISUAL_MEMORY",
    }

    assert {
        activity["id"]: activity["research_metadata"]["knowledge_component_id"]
        for activity in activities
    } == expected


def test_skill_two_client_metadata_uses_the_same_official_kcs_as_item_bank():
    decoded = json.loads(
        (DEFAULT_CURRICULUM_DIR / "skill_2.json").read_text(encoding="utf-8")
    )
    activities = decoded[0]["activities"]
    expected = {
        "act_1": "KC_LETTER_IDENTIFICATION",
        "act_2": "KC_LETTER_MATCHING",
        "act_3": "KC_PHONEME_LETTER_MAPPING",
        "act_4": "KC_LETTER_DECODING",
        "act_5": "KC_LETTER_MEMORY",
    }

    assert {
        activity["id"]: activity["research_metadata"]["knowledge_component_id"]
        for activity in activities
    } == expected

    bank_kcs = {
        item["activity_id"]: item["knowledge_component_id"]
        for item in build_items()
        if item["skill_id"] == "skill_2"
    }
    assert bank_kcs == {
        f"2.{index}": kc_id
        for index, kc_id in enumerate(expected.values(), start=1)
    }


def test_every_skill_two_rendered_item_has_an_unambiguous_valid_answer():
    items = [item for item in build_items() if item["skill_id"] == "skill_2"]

    assert len(items) == 81
    assert {item["activity_id"] for item in items} == {
        "2.1", "2.2", "2.3", "2.4", "2.5"
    }
    for item in items:
        content = item["content"]
        activity_id = item["activity_id"]

        if activity_id == "2.1":
            rendered = content["items"]
            targets = [choice for choice in rendered if choice.get("is_target")]
            assert targets, item["item_id"]
            assert all(choice.get("value") for choice in rendered), item["item_id"]
        elif activity_id == "2.2":
            letters = content["letters"]
            assert letters and len(letters) == len(set(letters)), item["item_id"]
        elif activity_id in {"2.3", "2.4"}:
            options = content["options"]
            assert options and len(options) == len(set(options)), item["item_id"]
            correct_indices = list(content.get("correct_indices") or [])
            if not correct_indices:
                correct_indices = [content["correct_index"]]
            assert all(0 <= index < len(options) for index in correct_indices), (
                item["item_id"], correct_indices, options
            )
            correct_option = content.get("correctOption")
            if correct_option is not None:
                assert options[correct_indices[0]] == correct_option, item["item_id"]
        else:
            options = content["options"]
            pattern = content["pattern"]
            assert options and len(options) == len(set(options)), item["item_id"]
            assert pattern and all(token in options for token in pattern), item["item_id"]


def test_skill_two_activity_one_preserves_the_reviewed_difficulty_progression():
    by_id = {
        item["item_id"]: item
        for item in build_items()
        if item["activity_id"] == "2.1"
    }
    expected_signatures = {
        "S2A1R01": (3, 1),
        "S2A1R01V1": (2, 1),
        "S2A1R01V2": (3, 1),
        "S2A1R02": (2, 2),
        "S2A1R02V1": (3, 1),
        "S2A1R02V2": (2, 2),
        "S2A1R03": (1, 3),
        "S2A1R03V1": (2, 2),
        "S2A1R03V2": (1, 3),
        "S2A1R04": (0, 4),
        "S2A1R04V1": (1, 3),
        "S2A1R04V2": (0, 4),
        "S2A1R05": (0, 6),
        "S2A1R05V1": (0, 4),
        "S2A1R05V2": (0, 6),
        "S2A1R06": (0, 6),
        "S2A1R06V1": (0, 6),
        "S2A1R06V2": (0, 6),
        "S2A1R07": (0, 6),
        "S2A1R07V1": (0, 6),
        "S2A1R07V2": (0, 6),
    }

    assert set(by_id) == set(expected_signatures)
    frontend_root = DEFAULT_CURRICULUM_DIR.parents[2]
    for item_id, (expected_icons, expected_letters) in expected_signatures.items():
        document = by_id[item_id]
        choices = document["content"]["items"]
        icons = [choice for choice in choices if choice["type"] == "icon"]
        letters = [choice for choice in choices if choice["type"] == "letter"]
        targets = [choice for choice in choices if choice.get("is_target")]

        assert (len(icons), len(letters)) == (
            expected_icons,
            expected_letters,
        ), item_id
        assert targets and all(choice["type"] == "letter" for choice in targets), item_id
        assert all(not choice.get("is_target") for choice in icons), item_id
        assert all((frontend_root / choice["value"]).is_file() for choice in icons), item_id
        assert all(choice["value"] in document["content"]["prompt"] for choice in targets), item_id

        expected_version = 5 if item_id.endswith(("V1", "V2")) else 2
        assert document["item_version"] == expected_version, item_id

    simple_letters = {
        "අ", "ඉ", "උ", "එ", "ඔ", "ක", "ග", "ත", "ද", "න",
        "ප", "බ", "ම", "ය", "ර", "ල", "ව", "ස", "හ", "ට",
    }
    for item_id, item in by_id.items():
        if not item_id.endswith(("V1", "V2")):
            continue
        letters = [
            choice["value"]
            for choice in item["content"]["items"]
            if choice["type"] == "letter"
        ]
        assert set(letters) <= simple_letters, item_id
        expected_relation = "reduced" if item_id.endswith("V1") else "equivalent"
        assert item["response_load_relation"] == expected_relation, item_id

    # Each V1/V2 pool uses different pictures internally, and neither variant
    # replays the visual material from the core or its sibling variant.
    for round_number in range(1, 4):
        core_id = f"S2A1R{round_number:02d}"
        variant_ids = [f"{core_id}V1", f"{core_id}V2"]
        icon_sets = []
        for item_id in [core_id, *variant_ids]:
            icons = [
                choice["value"]
                for choice in by_id[item_id]["content"]["items"]
                if choice["type"] == "icon"
            ]
            if item_id in variant_ids:
                assert len(icons) == len(set(icons)), item_id
            icon_sets.append(set(icons))
        assert icon_sets[0].isdisjoint(icon_sets[1]), core_id
        assert icon_sets[0].isdisjoint(icon_sets[2]), core_id
        assert icon_sets[1].isdisjoint(icon_sets[2]), core_id

    # Round 3 deliberately increases visual discrimination by presenting one
    # image and three different letters, not three copies of one letter.
    for item_id in ("S2A1R03", "S2A1R03V1", "S2A1R03V2"):
        letters = [
            choice["value"]
            for choice in by_id[item_id]["content"]["items"]
            if choice["type"] == "letter"
        ]
        assert len(letters) == len(set(letters)), item_id

    round_six_targets = [
        choice["value"]
        for choice in by_id["S2A1R06V2"]["content"]["items"]
        if choice.get("is_target")
    ]
    round_seven_targets = [
        choice["value"]
        for choice in by_id["S2A1R07V2"]["content"]["items"]
        if choice.get("is_target")
    ]
    assert len(round_six_targets) == 2
    assert len(set(round_six_targets)) == 1
    assert len(round_seven_targets) == 2
    assert len(set(round_seven_targets)) == 2

    def task_signature(item):
        choices = item["content"]["items"]
        icons = [choice for choice in choices if choice["type"] == "icon"]
        letters = [choice for choice in choices if choice["type"] == "letter"]
        targets = [choice["value"] for choice in choices if choice.get("is_target")]
        return (
            len(icons),
            len(letters),
            len(targets),
            len(set(targets)),
            len({choice["value"] for choice in letters}),
        )

    # V1 uses the immediately preceding difficulty structure. V2 retains the
    # failed core structure exactly. R1 is the three-choice floor exception.
    assert task_signature(by_id["S2A1R01V1"])[:3] == (2, 1, 1)
    for round_number in range(2, 8):
        core_id = f"S2A1R{round_number:02d}"
        previous_id = f"S2A1R{round_number - 1:02d}"
        assert task_signature(by_id[f"{core_id}V1"]) == task_signature(
            by_id[previous_id]
        ), core_id
        assert by_id[f"{core_id}V1"]["remediation_source_round"] == (
            round_number - 1
        )
        assert by_id[f"{core_id}V1"]["remediation_strategy"] == (
            "PREVIOUS_DIFFICULTY_LEVEL"
        )
        assert task_signature(by_id[f"{core_id}V2"]) == task_signature(
            by_id[core_id]
        ), core_id


def test_skill_two_activity_two_preserves_pair_count_and_pilla_progression():
    by_id = {
        item["item_id"]: item
        for item in build_items()
        if item["activity_id"] == "2.2"
    }

    def signature(item):
        letters = item["content"]["letters"]
        return len(letters), sum(len(letter) > 1 for letter in letters)

    core_signatures = [(2, 0), (2, 1), (3, 1), (4, 2), (5, 2)]
    remediation_signatures = [(2, 0), (2, 0), (2, 1), (3, 1), (4, 2)]
    for round_number in range(1, 6):
        core_id = f"S2A2R{round_number:02d}"
        core = by_id[core_id]
        remediation = by_id[f"{core_id}V1"]
        confirmation = by_id[f"{core_id}V2"]

        assert signature(core) == core_signatures[round_number - 1]
        assert signature(remediation) == remediation_signatures[round_number - 1]
        assert signature(confirmation) == signature(core)
        assert remediation["item_version"] == 3
        assert confirmation["item_version"] == 3
        assert remediation["remediation_source_round"] == (
            round_number - 1 if round_number > 1 else None
        )
        assert remediation["remediation_strategy"] == (
            "PREVIOUS_DIFFICULTY_LEVEL"
            if round_number > 1
            else "FLOOR_EQUIVALENT_TASK"
        )

        if round_number > 1:
            assert signature(remediation) == signature(
                by_id[f"S2A2R{round_number - 1:02d}"]
            )
            assert remediation["difficulty_b"] == by_id[
                f"S2A2R{round_number - 1:02d}"
            ]["difficulty_b"]


def test_skill_two_activity_three_preserves_audio_difficulty_and_unique_targets():
    by_id = {
        item["item_id"]: item
        for item in build_items()
        if item["activity_id"] == "2.3"
    }
    core_signatures = [
        (2, "minimal_contrast_2"),
        (3, "distinct_graphemes_3"),
        (3, "confusable_graphemes_3"),
        (4, "confusable_graphemes_4"),
        (5, "confusable_graphemes_5"),
    ]
    remediation_signatures = [
        (2, "minimal_contrast_2"),
        (2, "minimal_contrast_2"),
        (3, "distinct_graphemes_3"),
        (3, "confusable_graphemes_3"),
        (4, "confusable_graphemes_4"),
    ]
    presentation_targets = []

    for round_number in range(1, 6):
        core_id = f"S2A3R{round_number:02d}"
        core = by_id[core_id]
        remediation = by_id[f"{core_id}V1"]
        confirmation = by_id[f"{core_id}V2"]

        def signature(item):
            return len(item["content"]["options"]), item["distractor_strategy"]

        assert signature(core) == core_signatures[round_number - 1]
        assert signature(remediation) == remediation_signatures[round_number - 1]
        assert signature(confirmation) == signature(core)
        assert {core["item_version"], remediation["item_version"], confirmation["item_version"]} == {3}
        assert remediation["remediation_source_round"] == (
            round_number - 1 if round_number > 1 else None
        )
        if round_number > 1:
            assert signature(remediation) == signature(
                by_id[f"S2A3R{round_number - 1:02d}"]
            )

        presentation_targets.extend([
            core["content"]["correctOption"],
            remediation["content"]["correctOption"],
            confirmation["content"]["correctOption"],
        ])

    assert all(
        previous != current
        for previous, current in zip(
            presentation_targets,
            presentation_targets[1:],
        )
    )


def test_skill_two_activity_four_preserves_reviewed_word_boundary_progression():
    by_id = {
        item["item_id"]: item
        for item in build_items()
        if item["activity_id"] == "2.4"
    }
    core_signatures = [
        (2, 0, 2, "first", 1),
        (2, 0, 3, "first", 1),
        (2, 1, 3, "last", 1),
        (3, 0, 4, "last", 1),
        (3, 2, 6, "both", 2),
    ]
    remediation_signatures = [
        (2, 0, 2, "first", 1),
        (2, 0, 2, "first", 1),
        (2, 0, 3, "first", 1),
        (2, 1, 3, "last", 1),
        (3, 0, 4, "last", 1),
    ]
    presentation_words = []

    def signature(item):
        content = item["content"]
        target_count = len(content.get("correct_indices") or [
            content["correct_index"]
        ])
        return (
            len(content["word_units"]),
            content["pilla_count"],
            len(content["options"]),
            content["target_position"],
            target_count,
        )

    for round_number in range(1, 6):
        core_id = f"S2A4R{round_number:02d}"
        core = by_id[core_id]
        remediation = by_id[f"{core_id}V1"]
        confirmation = by_id[f"{core_id}V2"]

        assert signature(core) == core_signatures[round_number - 1]
        assert signature(remediation) == remediation_signatures[round_number - 1]
        assert signature(confirmation) == signature(core)
        assert {core["item_version"], remediation["item_version"], confirmation["item_version"]} == {6}
        assert core["difficulty_features"] == {
            "word_unit_count": core_signatures[round_number - 1][0],
            "pilla_count": core_signatures[round_number - 1][1],
            "answer_pool_size": core_signatures[round_number - 1][2],
            "target_position": core_signatures[round_number - 1][3],
        }
        if round_number > 1:
            assert signature(remediation) == signature(
                by_id[f"S2A4R{round_number - 1:02d}"]
            )
        presentation_words.extend([
            core["content"]["target_word"],
            remediation["content"]["target_word"],
            confirmation["content"]["target_word"],
        ])

    assert len(presentation_words) == len(set(presentation_words))
    assert by_id["S2A4R01V1"]["content"] == {
        "target_word": "රස",
        "word_units": ["ර", "ස"],
        "pilla_count": 0,
        "target_position": "first",
        "options": ["න", "ර"],
        "prompt": "'රස' යන වචනයේ මුල් අකුර කුමක්ද?",
        "correctOption": "ර",
        "correct_index": 1,
    }
    assert by_id["S2A4R03V1"]["content"] == {
        "target_word": "ගම",
        "word_units": ["ග", "ම"],
        "pilla_count": 0,
        "target_position": "first",
        "options": ["බ", "ග", "ම"],
        "prompt": "'ගම' යන වචනයේ මුල් අකුර කුමක්ද?",
        "correctOption": "ග",
        "correct_index": 1,
    }
    assert by_id["S2A4R01"]["has_floor_remediation"] is True
    assert all(
        by_id[f"S2A4R{round_number:02d}"]["has_floor_remediation"] is False
        for round_number in range(2, 6)
    )


def test_skill_two_activity_five_preserves_reviewed_memory_progression():
    by_id = {
        item["item_id"]: item
        for item in build_items()
        if item["activity_id"] == "2.5"
    }
    core_signatures = [
        (2, 0, 3, 6),
        (2, 1, 3, 5),
        (3, 0, 4, 5),
        (3, 1, 4, 4),
        (3, 3, 4, 4),
    ]
    remediation_signatures = [
        (2, 0, 3, 8),
        (2, 0, 3, 7),
        (2, 1, 3, 7),
        (3, 0, 4, 6),
        (3, 1, 4, 6),
    ]
    confirmation_signatures = [
        (2, 0, 3, 6),
        (2, 1, 3, 5),
        (3, 0, 4, 5),
        (3, 1, 4, 4),
        (3, 2, 4, 4),
    ]
    expected_remediation_b = [-1.5, -1.0, -0.5, 0.0, 0.5]
    presentation_words = []

    def signature(item):
        content = item["content"]
        return (
            len(content["pattern"]),
            content["pilla_count"],
            len(content["options"]),
            content["show_seconds"],
        )

    for round_number in range(1, 6):
        core_id = f"S2A5R{round_number:02d}"
        core = by_id[core_id]
        remediation = by_id[f"{core_id}V1"]
        confirmation = by_id[f"{core_id}V2"]
        index = round_number - 1

        assert signature(core) == core_signatures[index]
        assert signature(remediation) == remediation_signatures[index]
        assert signature(confirmation) == confirmation_signatures[index]
        assert remediation["difficulty_b"] == expected_remediation_b[index]
        assert confirmation["difficulty_b"] == core["difficulty_b"]
        assert {core["item_version"], remediation["item_version"], confirmation["item_version"]} == {3}
        assert core["difficulty_features"] == {
            "pattern_length": core_signatures[index][0],
            "pilla_count": core_signatures[index][1],
            "answer_pool_size": core_signatures[index][2],
            "show_seconds": core_signatures[index][3],
        }
        presentation_words.extend([
            core["content"]["target_word"],
            remediation["content"]["target_word"],
            confirmation["content"]["target_word"],
        ])

    assert len(presentation_words) == len(set(presentation_words))
    assert by_id["S2A5R02V2"]["content"]["target_word"] == "ගල්"
    assert by_id["S2A5R04V1"]["content"]["target_word"] == "අහස"
    assert by_id["S2A5R04V2"]["content"]["target_word"] == "පනාව"
    assert by_id["S2A5R05V1"]["content"]["target_word"] == "තරුව"
    assert by_id["S2A5R05V2"]["content"]["target_word"] == "පුටුව"


def test_item_bank_sync_quarantines_only_superseded_activity_one_variants():
    class Result:
        modified_count = 2

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update, **kwargs):
            self.calls.append((query, update, kwargs))
            return Result()

    class Database:
        adaptive_decisions = Collection()
        telemetry_events = Collection()
        telemetry_sessions = Collection()

    database = Database()
    result = quarantine_superseded_skill_two_activity_one_evidence(
        database,
        build_items(),
    )

    assert result == {
        "superseded_adaptive_decisions": 2,
        "superseded_telemetry_events": 2,
        "superseded_telemetry_sessions": 2,
    }
    decision_filter = database.adaptive_decisions.calls[0][0]
    assert len(decision_filter["current_item"]["$in"]) == 14
    assert decision_filter["item_version"] == {"$ne": 5}
    assert database.telemetry_sessions.calls[0][2]["array_filters"][0][
        "event.item_version"
    ] == {"$ne": 5}


def test_item_bank_sync_quarantines_superseded_activity_two_variants():
    class Result:
        modified_count = 3

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update, **kwargs):
            self.calls.append((query, update, kwargs))
            return Result()

    class Database:
        adaptive_decisions = Collection()
        telemetry_events = Collection()
        telemetry_sessions = Collection()

    database = Database()
    result = quarantine_superseded_skill_two_activity_two_evidence(
        database,
        build_items(),
    )

    assert result == {
        "superseded_s2a2_adaptive_decisions": 3,
        "superseded_s2a2_telemetry_events": 3,
        "superseded_s2a2_telemetry_sessions": 3,
    }
    decision_filter = database.adaptive_decisions.calls[0][0]
    assert len(decision_filter["current_item"]["$in"]) == 10
    assert decision_filter["item_version"] == {"$ne": 3}
    assert database.telemetry_sessions.calls[0][2]["array_filters"][0][
        "event.item_version"
    ] == {"$ne": 3}


def test_item_bank_sync_quarantines_all_superseded_activity_three_items():
    class Result:
        modified_count = 4

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update, **kwargs):
            self.calls.append((query, update, kwargs))
            return Result()

    class Database:
        adaptive_decisions = Collection()
        telemetry_events = Collection()
        telemetry_sessions = Collection()

    database = Database()
    result = quarantine_superseded_skill_two_activity_three_evidence(
        database,
        build_items(),
    )

    assert result == {
        "superseded_s2a3_adaptive_decisions": 4,
        "superseded_s2a3_telemetry_events": 4,
        "superseded_s2a3_telemetry_sessions": 4,
    }
    decision_filter = database.adaptive_decisions.calls[0][0]
    assert len(decision_filter["current_item"]["$in"]) == 15
    assert decision_filter["item_version"] == {"$ne": 3}


def test_item_bank_sync_quarantines_all_superseded_activity_four_items():
    class Result:
        modified_count = 5

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update, **kwargs):
            self.calls.append((query, update, kwargs))
            return Result()

    class Database:
        adaptive_decisions = Collection()
        telemetry_events = Collection()
        telemetry_sessions = Collection()

    database = Database()
    result = quarantine_superseded_skill_two_activity_four_evidence(
        database,
        build_items(),
    )

    assert result == {
        "superseded_s2a4_adaptive_decisions": 5,
        "superseded_s2a4_telemetry_events": 5,
        "superseded_s2a4_telemetry_sessions": 5,
    }
    decision_filter = database.adaptive_decisions.calls[0][0]
    assert len(decision_filter["current_item"]["$in"]) == 15
    assert decision_filter["item_version"] == {"$ne": 6}


def test_item_bank_sync_quarantines_all_superseded_activity_five_items():
    class Result:
        modified_count = 6

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update, **kwargs):
            self.calls.append((query, update, kwargs))
            return Result()

    class Database:
        adaptive_decisions = Collection()
        telemetry_events = Collection()
        telemetry_sessions = Collection()

    database = Database()
    result = quarantine_superseded_skill_two_activity_five_evidence(
        database,
        build_items(),
    )

    assert result == {
        "superseded_s2a5_adaptive_decisions": 6,
        "superseded_s2a5_telemetry_events": 6,
        "superseded_s2a5_telemetry_sessions": 6,
    }
    decision_filter = database.adaptive_decisions.calls[0][0]
    assert len(decision_filter["current_item"]["$in"]) == 15
    assert decision_filter["item_version"] == {"$ne": 3}


def test_item_bank_sync_quarantines_all_superseded_skill_three_items():
    class Result:
        modified_count = 2

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update, **kwargs):
            self.calls.append((query, update, kwargs))
            return Result()

    class Database:
        adaptive_decisions = Collection()
        telemetry_events = Collection()
        telemetry_sessions = Collection()

    database = Database()
    result = quarantine_superseded_skill_three_evidence(
        database,
        build_items(),
    )

    assert result == {
        "superseded_s3_adaptive_decisions": 12,
        "superseded_s3_telemetry_events": 12,
        "superseded_s3_telemetry_sessions": 12,
    }
    assert len(database.adaptive_decisions.calls) == 6
    for activity_number, call in enumerate(
        database.adaptive_decisions.calls[:5], start=1
    ):
        expected_version = 10 if activity_number in {4, 5} else 9
        assert len(call[0]["current_item"]["$in"]) == 15
        assert call[0]["item_version"] == {"$ne": expected_version}
    canonical_skill_three_ids = [
        item["item_id"]
        for item in build_items()
        if item["skill_id"] == "skill_3"
    ]
    assert database.telemetry_events.calls[-1][0] == {
        "skill_id": "skill_3",
        "item_id": {"$nin": canonical_skill_three_ids},
        "research_eligible": {"$ne": False},
    }


def test_item_bank_sync_removes_legacy_activity_four_aliases():
    class Result:
        modified_count = 5

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update):
            self.calls.append((query, update))
            return Result()

    class Database:
        item_bank = Collection()

    database = Database()
    result = remove_legacy_skill_two_activity_four_fields(
        database,
        build_items(),
    )

    assert result == {"cleaned_s2a4_legacy_item_records": 5}
    query, update = database.item_bank.calls[0]
    assert len(query["item_id"]["$in"]) == 15
    assert update == {"$unset": {"frontend_item_alias": ""}}


def test_item_bank_sync_removes_legacy_activity_one_to_three_fields():
    class Result:
        modified_count = 37

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update):
            self.calls.append((query, update))
            return Result()

    class Database:
        item_bank = Collection()

    database = Database()
    result = remove_legacy_skill_two_activities_one_to_three_fields(
        database,
        build_items(),
    )

    assert result == {"cleaned_s2a1_to_s2a3_legacy_item_records": 37}
    query, update = database.item_bank.calls[0]
    assert len(query["item_id"]["$in"]) == 51
    assert update == {"$unset": {
        "frontend_item_alias": "",
        "kc_id": "",
        "target": "",
        "variant": "",
        "slip_s": "",
        "created_at": "",
        "updated_at": "",
    }}


def test_item_bank_sync_removes_legacy_activity_five_fields():
    class Result:
        modified_count = 15

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update):
            self.calls.append((query, update))
            return Result()

    class Database:
        item_bank = Collection()

    database = Database()
    result = remove_legacy_skill_two_activity_five_fields(
        database,
        build_items(),
    )

    assert result == {"cleaned_s2a5_legacy_item_records": 15}
    query, update = database.item_bank.calls[0]
    assert len(query["item_id"]["$in"]) == 15
    assert update == {
        "$unset": {"difficulty": "", "frontend_item_alias": ""}
    }


def test_item_bank_sync_removes_legacy_skill_three_aliases():
    class Result:
        modified_count = 25

    class Collection:
        def __init__(self):
            self.calls = []

        def update_many(self, query, update):
            self.calls.append((query, update))
            return Result()

    class Database:
        item_bank = Collection()

    database = Database()
    result = remove_legacy_skill_three_fields(database, build_items())

    assert result == {"cleaned_s3_legacy_item_records": 25}
    query, update = database.item_bank.calls[0]
    assert len(query["item_id"]["$in"]) == 75
    assert update == {"$unset": {"frontend_item_alias": ""}}


def _response_load(content):
    if content.get("targets"):
        return int(content.get("target_count", 1)) + len(content.get("distractors") or [])
    if content.get("target_assets"):
        return len(content["target_assets"])
    if content.get("categories"):
        return sum(len(values) for values in content["categories"].values())
    for key in ("options", "items", "letters", "assets", "scrambled_letters", "scrambled_words", "pattern"):
        if content.get(key):
            return len(content[key])
    return 0


def test_remediation_reduces_load_when_valid_and_confirmation_preserves_it():
    items = build_items()
    by_id = {item["item_id"]: item for item in items}
    cores = [item for item in items if item["is_core"] and item["skill_id"] in {
        "skill_1", "skill_2", "skill_3", "skill_4"
    }]

    for core in cores:
        remediation = by_id[f'{core["item_id"]}V1']
        confirmation = by_id[f'{core["item_id"]}V2']
        core_load = _response_load(core["content"])
        remediation_load = _response_load(remediation["content"])
        confirmation_load = _response_load(confirmation["content"])
        assert confirmation_load == core_load, confirmation["item_id"]
        if core["skill_id"] != "skill_3":
            assert remediation_load <= core_load, remediation["item_id"]
        if core["has_reduced_remediation"]:
            if core["activity_id"] == "2.1":
                assert remediation["remediation_strategy"] in {
                    "FLOOR_REDUCED_CHOICES",
                    "PREVIOUS_DIFFICULTY_LEVEL",
                }
            else:
                has_more_viewing_time = (
                    remediation["content"].get("show_milliseconds", 0)
                    > core["content"].get("show_milliseconds", 0)
                    or remediation["content"].get("show_seconds", 0)
                    > core["content"].get("show_seconds", 0)
                )
                lower_orthographic_load = (
                    core["activity_id"] == "2.2"
                    and sum(len(value) > 1 for value in remediation["content"]["letters"])
                    < sum(len(value) > 1 for value in core["content"]["letters"])
                )
                distractor_rank = {
                    "minimal_contrast_2": 0,
                    "distinct_graphemes_3": 1,
                    "confusable_graphemes_3": 2,
                    "confusable_graphemes_4": 3,
                    "confusable_graphemes_5": 4,
                }
                lower_distractor_complexity = (
                    core["activity_id"] == "2.3"
                    and distractor_rank[remediation["distractor_strategy"]]
                    < distractor_rank[core["distractor_strategy"]]
                )
                activity_four_levels = [
                    (2, 0, 2, "first"),
                    (2, 0, 3, "first"),
                    (2, 1, 3, "last"),
                    (3, 0, 4, "last"),
                    (3, 2, 6, "both"),
                ]
                lower_word_boundary_complexity = (
                    core["activity_id"] == "2.4"
                    and activity_four_levels.index((
                        remediation["difficulty_features"]["word_unit_count"],
                        remediation["difficulty_features"]["pilla_count"],
                        remediation["difficulty_features"]["answer_pool_size"],
                        remediation["difficulty_features"]["target_position"],
                    ))
                    < activity_four_levels.index((
                        core["difficulty_features"]["word_unit_count"],
                        core["difficulty_features"]["pilla_count"],
                        core["difficulty_features"]["answer_pool_size"],
                        core["difficulty_features"]["target_position"],
                    ))
                )
                lower_skill_three_structure = (
                    core["skill_id"] == "skill_3"
                    and remediation["remediation_source_round"] == core["round"] - 1
                    and remediation["difficulty_b"] <= core["difficulty_b"]
                )
                assert (
                    remediation_load < core_load
                    or has_more_viewing_time
                    or lower_orthographic_load
                    or lower_distractor_complexity
                    or lower_word_boundary_complexity
                    or lower_skill_three_structure
                ), remediation["item_id"]


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


def test_skill_three_has_reviewed_previous_level_remediation_and_equivalent_confirmation():
    skill_three = [
        item for item in build_items() if item["skill_id"] == "skill_3"
    ]
    by_id = {item["item_id"]: item for item in skill_three}
    frontend_root = DEFAULT_CURRICULUM_DIR.parents[2]

    assert len(skill_three) == 75
    assert len(by_id) == 75

    expected_core_signatures = {
        "3.1": [(2, 0, 2), (2, 0, 3), (3, 0, 4), (3, 1, 4), (3, 2, 5)],
        "3.2": [(2, 0, 2), (2, 1, 3), (3, 1, 3), (3, 2, 4), (3, 2, 5)],
        "3.3": [(2, 0, 2), (2, 1, 2), (3, 1, 3), (3, 2, 3), (3, 2, 4)],
        "3.4": [(2, 0, 2), (2, 1, 3), (3, 1, 3), (3, 2, 4), (3, 3, 4)],
        "3.5": [(2, 0, 2), (2, 0, 2), (3, 0, 3), (3, 1, 3), (3, 2, 3)],
    }

    def signature(item):
        features = item["difficulty_features"]
        return (
            features["word_unit_count"],
            features["pilla_count"],
            features["answer_pool_size"],
        )

    for activity_id, expected in expected_core_signatures.items():
        activity_number = int(activity_id.split(".")[1])
        for round_number, core_signature in enumerate(expected, start=1):
            base_id = f"S3A{activity_number}R{round_number:02d}"
            core = by_id[base_id]
            remediation = by_id[f"{base_id}V1"]
            confirmation = by_id[f"{base_id}V2"]

            expected_version = 10 if activity_id in {"3.4", "3.5"} else 9
            assert core["item_version"] == expected_version
            assert remediation["item_version"] == expected_version
            assert confirmation["item_version"] == expected_version
            assert signature(core) == core_signature, base_id
            expected_confirmation = core_signature
            if confirmation["item_id"] == "S3A5R02V2":
                expected_confirmation = (2, 1, 2)
            assert signature(confirmation) == expected_confirmation, (
                confirmation["item_id"]
            )
            expected_remediation = expected[max(0, round_number - 2)]
            if remediation["item_id"] == "S3A5R03V1":
                expected_remediation = (2, 1, 2)
            assert signature(remediation) == expected_remediation, remediation["item_id"]
            assert confirmation["difficulty_b"] == core["difficulty_b"]

            if round_number == 1:
                assert remediation["response_load_relation"] == "equivalent"
                assert remediation["remediation_source_round"] is None
                assert remediation["remediation_strategy"] == "FLOOR_EQUIVALENT_TASK"
            else:
                assert remediation["response_load_relation"] == "reduced"
                assert remediation["difficulty_b"] <= core["difficulty_b"]
                assert remediation["remediation_source_round"] == round_number - 1
                assert remediation["remediation_strategy"] == "PREVIOUS_DIFFICULTY_LEVEL"

            for item in (core, remediation, confirmation):
                image_url = item["content"].get("image_url")
                if activity_id in {"3.1", "3.4", "3.5"}:
                    assert image_url, item["item_id"]
                    assert (frontend_root / image_url).is_file(), item["item_id"]

    assert by_id["S3A1R03V1"]["content"]["correctOption"] == "දත"
    assert by_id["S3A1R03V1"]["content"]["image_url"].endswith("tooth.png")
    assert len(by_id["S3A1R05"]["content"]["options"]) == 5
    assert len(by_id["S3A1R05V2"]["content"]["options"]) == 5

    activity_four_r1_confirmation = by_id["S3A4R01V2"]
    assert activity_four_r1_confirmation["content"] == {
        "prompt": "'කන' වචනයේ අඩු අකුර තෝරන්න",
        "image_url": "assets/images/activity_icons/body_parts/ear.png",
        "sequence": [None, "න"],
        "options": ["ක", "ග"],
        "correctOption": "ක",
        "correct_index": 0,
    }
    assert activity_four_r1_confirmation["difficulty_features"] == {
        "word_unit_count": 2,
        "pilla_count": 0,
        "answer_pool_size": 2,
        "has_matching_image": True,
    }

    activity_four_r2_confirmation = by_id["S3A4R02V2"]
    assert activity_four_r2_confirmation["content"] == {
        "prompt": "'නැව' වචනයේ අඩු අකුර තෝරන්න",
        "image_url": "assets/images/activity_icons/vehicles/boat.png",
        "sequence": ["නැ", None],
        "options": ["ව", "ර", "ල"],
        "correctOption": "ව",
        "correct_index": 0,
    }
    assert activity_four_r2_confirmation["difficulty_features"] == {
        "word_unit_count": 2,
        "pilla_count": 1,
        "answer_pool_size": 3,
        "has_matching_image": True,
    }

    assert by_id["S3A5R01V1"]["content"] == by_id["S3A5R01V2"]["content"]
    assert by_id["S3A5R01V2"]["content"]["correct_word"] == "ගස"
    assert by_id["S3A5R02V1"]["content"]["correct_word"] == "කන"
    assert by_id["S3A5R02V1"]["content"]["image_url"].endswith("ear.png")
    assert by_id["S3A5R02V1"]["difficulty_features"] == {
        "word_unit_count": 2,
        "pilla_count": 0,
        "answer_pool_size": 2,
        "has_matching_image": True,
    }
    assert by_id["S3A5R02"]["has_reduced_remediation"] is True
    assert by_id["S3A5R02V1"]["response_load_relation"] == "reduced"
    assert (
        by_id["S3A5R02V1"]["difficulty_b"]
        == by_id["S3A5R01"]["difficulty_b"]
    )
    assert by_id["S3A5R02V2"]["content"]["correct_word"] == "පාර"
    assert by_id["S3A5R02V2"]["content"]["image_url"].endswith("road.png")
    assert by_id["S3A5R02V2"]["difficulty_features"] == {
        "word_unit_count": 2,
        "pilla_count": 1,
        "answer_pool_size": 2,
        "has_matching_image": True,
    }
    assert by_id["S3A5R03V1"]["content"]["correct_word"] == "නැව"
    assert by_id["S3A5R03V1"]["difficulty_features"] == {
        "word_unit_count": 2,
        "pilla_count": 1,
        "answer_pool_size": 2,
        "has_matching_image": True,
    }


def test_skill_three_image_word_pools_use_consistent_word_lengths():
    items = [
        item for item in build_items()
        if item["activity_id"] == "3.1"
    ]

    for item in items:
        options = item["content"]["options"]
        # The item-bank feature is the authoritative normalized Sinhala unit
        # count; every answer in one pool must occupy the same number of units.
        expected_length = item["difficulty_features"]["word_unit_count"]
        normalized_lengths = {
            sum(1 for character in option if unicodedata.category(character) == "Lo")
            for option in options
        }
        assert normalized_lengths == {expected_length}, (item["item_id"], options)


def test_skill_three_word_formation_uses_unique_targets_and_equal_length_pools():
    items = [
        item for item in build_items()
        if item["activity_id"] == "3.2"
    ]

    assert len(items) == 15
    targets = [item["content"]["correctOption"] for item in items]
    assert len(set(targets)) == len(targets)
    assert targets.count("පුටුව") == 1
    assert sum(
        option == "පුටුව"
        for item in items
        for option in item["content"]["options"]
    ) == 1

    for item in items:
        options = item["content"]["options"]
        expected_length = item["difficulty_features"]["word_unit_count"]
        normalized_lengths = {
            sum(
                1
                for character in option
                if unicodedata.category(character) == "Lo"
            )
            for option in options
        }
        assert normalized_lengths == {expected_length}, (
            item["item_id"],
            options,
        )


def test_skill_three_audio_word_pools_match_the_spoken_target_length():
    items = [
        item for item in build_items()
        if item["activity_id"] == "3.3"
    ]

    assert len(items) == 15
    targets = [item["content"]["correctOption"] for item in items]
    assert len(set(targets)) == len(targets)
    for item in items:
        content = item["content"]
        target = content["correctOption"]
        assert content["audio_text"] == target
        expected_length = item["difficulty_features"]["word_unit_count"]
        normalized_lengths = {
            sum(
                1
                for character in option
                if unicodedata.category(character) == "Lo"
            )
            for option in content["options"]
        }
        assert normalized_lengths == {expected_length}, (
            item["item_id"],
            content["options"],
        )


def test_skill_three_activity_one_first_three_levels_have_no_pillam():
    items = [
        item for item in build_items()
        if item["activity_id"] == "3.1" and item["round"] <= 3
    ]

    assert len(items) == 9
    for item in items:
        content = item["content"]
        words = [content["correctOption"], *content["options"]]
        assert item["difficulty_features"]["pilla_count"] == 0, item["item_id"]
        assert all(
            not unicodedata.category(character).startswith("M")
            for word in words
            for character in word
        ), (item["item_id"], words)
