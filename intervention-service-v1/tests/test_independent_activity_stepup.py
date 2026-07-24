"""
Unit tests for Independent Activity level step-up
(independent_activity_stepup_spec.md).
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "intervention-service-v1"))

from core.question_content import (
    Grade1WordList,
    get_candidates,
    get_independent_activity_content,
)
from core.reference_table import get_grade1_table


def test_fallback_when_higher_level_empty():
    """(a) If target_level has no candidates, fall back to guided_level."""
    table = get_grade1_table()
    # Empty word list → L3/L4 have no visual_confusion words
    empty_wl = Grade1WordList({"words": []})

    # Guided at 3 → try 4 (empty) → fall back to 3 (also empty) → absolute L1
    result = get_independent_activity_content(
        tag="visual_confusion",
        specific_instance=["ට", "ඨ"],
        guided_level=3,
        exclude_instance=None,
        table=table,
        word_list=empty_wl,
    )
    assert result["content_instance"]["display"]
    assert result["level"] >= 1

    # Clear fallback: invent a tag path where L2 is empty but L1 is not.
    # Use blend_required with a word list that only has level-1-length words
    # so guided_level=1 → target 2 empty → falls back to 1.
    short_only = Grade1WordList({
        "words": [
            {
                "word": "මල",
                "tags_present": ["blend_required"],
                "grade1_safe": True,
                "picture_ref": None,
            },
        ]
    })
    # L1 accepts n<=3; L2 wants 3<n<=5 — "මල" is len 2 → L2 empty
    r_fb = get_independent_activity_content(
        tag="blend_required",
        specific_instance="මල",
        guided_level=1,
        exclude_instance=None,
        table=table,
        word_list=short_only,
    )
    assert r_fb["level"] == 1
    assert r_fb["content_instance"]["word"] == "මල"

    # Guided at 1 with normal data → Independent prefers level 2 when available
    wl = Grade1WordList()
    result2 = get_independent_activity_content(
        tag="visual_confusion",
        specific_instance=["ට", "ඨ"],
        guided_level=1,
        exclude_instance=None,
        table=table,
        word_list=wl,
    )
    l2 = get_candidates("visual_confusion", 2, table, wl, ["ට", "ඨ"])
    if l2:
        assert result2["level"] == 2


def test_exclude_instance_respected():
    """(b) exclude_instance is removed when alternatives exist."""
    table = get_grade1_table()
    wl = Grade1WordList()
    cands = get_candidates("visual_confusion", 1, table, wl, ["ට", "ඨ"])
    assert len(cands) >= 1
    exclude = cands[0]

    # Force many draws — excluded id should not appear when alternatives exist
    if len(cands) >= 2:
        for _ in range(20):
            result = get_independent_activity_content(
                tag="visual_confusion",
                specific_instance=["ට", "ඨ"],
                guided_level=1,
                exclude_instance=exclude,
                table=table,
                word_list=wl,
            )
            # Step-up to L2 usually, but if still on same pool check exclusion
            if result["level"] == exclude["level"]:
                assert result["content_instance"]["id"] != exclude["id"]


def test_picture_ref_rules():
    """(c) picture_ref is None when level < 3 or word has no picture entry."""
    table = get_grade1_table()
    wl = Grade1WordList()

    # Level step from 1 → 2: must be None (level < 3)
    r_low = get_independent_activity_content(
        tag="visual_confusion",
        specific_instance=["ට", "ඨ"],
        guided_level=1,
        table=table,
        word_list=wl,
    )
    if r_low["level"] < 3:
        assert r_low["picture_ref"] is None

    # Fabricate a L3 word entry with null picture
    wl_pic = Grade1WordList({
        "words": [
            {
                "word": "පිට",
                "tags_present": ["visual_confusion"],
                "relevant_pair_or_letter": ["ට", "ඨ"],
                "grade1_safe": True,
                "picture_ref": None,
            },
            {
                "word": "වට",
                "tags_present": ["visual_confusion"],
                "relevant_pair_or_letter": ["ට", "ඨ"],
                "grade1_safe": True,
                "picture_ref": "images/around.png",
            },
        ]
    })
    # Guided 2 → Independent 3
    r3 = get_independent_activity_content(
        tag="visual_confusion",
        specific_instance=["ට", "ඨ"],
        guided_level=2,
        table=table,
        word_list=wl_pic,
    )
    assert r3["level"] == 3
    # picture_ref may be None or a path — never raises; null words OK
    pic = r3["picture_ref"]
    assert pic is None or isinstance(pic, str)

    # Explicit: word with no picture → None
    only_null = Grade1WordList({
        "words": [
            {
                "word": "පිට",
                "tags_present": ["visual_confusion"],
                "relevant_pair_or_letter": ["ට", "ඨ"],
                "grade1_safe": True,
                "picture_ref": None,
            }
        ]
    })
    r_null = get_independent_activity_content(
        tag="visual_confusion",
        specific_instance=["ට", "ඨ"],
        guided_level=2,
        table=table,
        word_list=only_null,
    )
    assert r_null["level"] == 3
    assert r_null["picture_ref"] is None


def test_word_list_get_picture():
    wl = Grade1WordList({
        "words": [
            {"word": "මල", "picture_ref": "images/flower.png", "grade1_safe": True},
            {"word": "පොත", "picture_ref": None, "grade1_safe": True},
        ]
    })
    assert wl.get_picture("මල") == "images/flower.png"
    assert wl.get_picture("පොත") is None
    assert wl.get_picture("missing") is None


if __name__ == "__main__":
    test_fallback_when_higher_level_empty()
    print("[OK] fallback")
    test_exclude_instance_respected()
    print("[OK] exclude_instance")
    test_picture_ref_rules()
    print("[OK] picture_ref rules")
    test_word_list_get_picture()
    print("[OK] get_picture")
    print("All independent-activity step-up tests passed.")
