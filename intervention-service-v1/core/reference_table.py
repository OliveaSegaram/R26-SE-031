"""
Grade-1 reference table helpers for C4.

Hard rule: anything shown to a Grade-1 child must pass validate_content().
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Union

from .sinhala_segmenter import Akshara, analyze_word, attach_tags, load_grade1_table, segment_word

DEFAULT_TABLE_PATH = Path(__file__).parent.parent / "data" / "grade1_akshara_table.json"

# Tag priority for dispatcher (identity confusion before blend fluency)
TAG_PRIORITY = (
    "visual_confusion",
    "pillam_subtle",
    "hal_kirima",
    "blend_required",
)

_table_cache: Optional[dict] = None


def get_grade1_table(path: Optional[Union[str, Path]] = None) -> dict:
    global _table_cache
    if path is None and _table_cache is not None:
        return _table_cache
    table = load_grade1_table(str(path or DEFAULT_TABLE_PATH))
    if path is None:
        _table_cache = table
    return table


def lookup_akshara(akshara: Akshara, table: Optional[dict] = None) -> Dict[str, Any]:
    """Return {in_grade1_scope, tags} for one akshara (with structural fallback)."""
    table = table or get_grade1_table()
    attach_tags([akshara], table)
    return {
        "in_grade1_scope": akshara.in_grade1_scope,
        "tags": list(akshara.tags),
        "text": akshara.text,
        "base_consonant": akshara.base_consonant,
        "vowel_form": akshara.vowel_form,
    }


def pick_primary_tag(tags: Sequence[str]) -> Optional[str]:
    for tag in TAG_PRIORITY:
        if tag in tags:
            return tag
    return None


def validate_content(
    text_or_units: Union[str, Sequence[Akshara]],
    table: Optional[dict] = None,
    *,
    allow_unknown: bool = False,
) -> bool:
    """
    Gate: every akshara must be in Grade-1 scope before showing to the child.

    allow_unknown=False treats unfinished TODO rows (in_grade1_scope=None) as fail.
    """
    table = table or get_grade1_table()
    if isinstance(text_or_units, str):
        units = analyze_word(text_or_units, table)
    else:
        units = attach_tags(list(text_or_units), table)

    if not units:
        return False

    for u in units:
        if u.in_grade1_scope is True:
            continue
        if u.in_grade1_scope is None and allow_unknown:
            continue
        return False
    return True


def resolve_specific_instance(
    tag: str,
    akshara: Akshara,
    table: Optional[dict] = None,
) -> Union[List[str], str]:
    """
    Build the mastery key instance for a tag:
      visual_confusion -> confusable pair list
      pillam_subtle    -> pillam vowel_form
      hal_kirima       -> base consonant
      blend_required   -> akshara text / sequence
    """
    table = table or get_grade1_table()
    if tag == "visual_confusion":
        for pair in table.get("confusable_pairs", {}).get("pairs", []):
            if akshara.base_consonant in pair or akshara.text in pair:
                return list(pair)
        # pillam confusable pairs (ෙ/ේ etc.)
        for pair in table.get("confusable_pairs", {}).get("pairs", []):
            if any(len(p) == 1 and ord(p) >= 0x0DCF for p in pair):
                # vowel-sign pair — match via form if present in cell tags only
                pass
        return [akshara.base_consonant or akshara.text]
    if tag == "pillam_subtle":
        return f"{akshara.base_consonant}:{akshara.vowel_form}"
    if tag == "hal_kirima":
        return akshara.base_consonant or akshara.text
    if tag == "blend_required":
        return akshara.text
    return akshara.text


def instance_key(specific_instance: Union[List[str], str, Sequence[str]]) -> str:
    if isinstance(specific_instance, (list, tuple)):
        return "|".join(specific_instance)
    return str(specific_instance)


def find_confusable_partner(letter: str, table: Optional[dict] = None) -> Optional[str]:
    table = table or get_grade1_table()
    for a, b in table.get("confusable_pairs", {}).get("pairs", []):
        if letter == a:
            return b
        if letter == b:
            return a
    return None
