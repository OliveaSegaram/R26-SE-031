"""
Question / Independent-Activity content selection for C4.

Levels (per research spec):
  1 — isolated bare letters / pair members
  2 — letter + common pillam forms
  3 — short Grade-1 words containing the difficulty
  4 — fuller Grade-1 words

Independent Activity steps up one level from Guided Practice
(see independent_activity_stepup_spec.md).
"""

from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Union

from .reference_table import get_grade1_table, instance_key

DEFAULT_WORD_LIST_PATH = (
    Path(__file__).parent.parent / "data" / "grade1_word_list.json"
)

# Common pillam forms for Level 2 discrimination content
_LEVEL2_PILLAM = ("aa", "ae", "i", "e", "o")


def load_word_list(path: Optional[Union[str, Path]] = None) -> Dict[str, Any]:
    p = Path(path or DEFAULT_WORD_LIST_PATH)
    with open(p, "r", encoding="utf-8") as f:
        return json.load(f)


class Grade1WordList:
    """Thin wrapper over grade1_word_list.json."""

    def __init__(self, data: Optional[dict] = None, path: Optional[Union[str, Path]] = None):
        self._data = data or load_word_list(path)
        self.words: List[dict] = list(self._data.get("words", []))

    def get_picture(self, word: Optional[str]) -> Optional[str]:
        if not word:
            return None
        for entry in self.words:
            if entry.get("word") == word:
                ref = entry.get("picture_ref")
                return ref if ref else None
        return None

    def words_for_tag(
        self,
        tag: str,
        specific_instance: Any = None,
        *,
        grade1_safe_only: bool = True,
    ) -> List[dict]:
        out = []
        for entry in self.words:
            if grade1_safe_only and not entry.get("grade1_safe", False):
                continue
            if tag not in (entry.get("tags_present") or []):
                continue
            if specific_instance is not None and tag == "visual_confusion":
                pair = entry.get("relevant_pair_or_letter")
                if not pair:
                    continue
                # Match if instance overlaps this word's pair
                inst = (
                    list(specific_instance)
                    if isinstance(specific_instance, (list, tuple))
                    else [specific_instance]
                )
                if not any(x in pair for x in inst):
                    continue
            # Skip obvious placeholders
            w = entry.get("word") or ""
            if w.startswith("REPLACE_ME"):
                continue
            out.append(entry)
        return out


def _pair_glyphs(specific_instance: Any, table: dict) -> List[str]:
    if isinstance(specific_instance, (list, tuple)) and len(specific_instance) >= 2:
        return [str(specific_instance[0]), str(specific_instance[1])]
    if isinstance(specific_instance, str) and specific_instance:
        # Try confusable partner
        for a, b in table.get("confusable_pairs", {}).get("pairs", []):
            if specific_instance == a:
                return [a, b]
            if specific_instance == b:
                return [b, a]
        return [specific_instance]
    return ["ට", "ඨ"]


def _pillam_forms(specific_instance: Any, table: dict) -> List[str]:
    """Level-2: forms with pillam for the base consonant(s)."""
    forms: List[str] = []
    bases: List[str] = []
    if isinstance(specific_instance, str) and ":" in specific_instance:
        base, _ = specific_instance.split(":", 1)
        bases = [base]
    else:
        bases = _pair_glyphs(specific_instance, table)

    for base in bases:
        cells = table.get("consonants", {}).get(base, {}).get("cells", {})
        for vf in _LEVEL2_PILLAM:
            cell = cells.get(vf)
            if not cell:
                continue
            if cell.get("in_grade1_scope") is False:
                continue
            form = cell.get("form")
            if form:
                forms.append(form)
        # Always include bare 'a' form if in scope
        a_cell = cells.get("a")
        if a_cell and a_cell.get("in_grade1_scope") is not False and a_cell.get("form"):
            forms.append(a_cell["form"])
    # Deduplicate preserve order
    seen = set()
    uniq = []
    for f in forms:
        if f not in seen:
            seen.add(f)
            uniq.append(f)
    return uniq or _pair_glyphs(specific_instance, table)


def _content_id(level: int, display: str, word: Optional[str] = None) -> str:
    if word:
        return f"L{level}:word:{word}"
    return f"L{level}:glyph:{display}"


def get_candidates(
    tag: str,
    level: int,
    table: Optional[dict] = None,
    word_list: Optional[Grade1WordList] = None,
    specific_instance: Any = None,
) -> List[Dict[str, Any]]:
    """
    Return content instance dicts for (tag, level).

    Each instance:
      {
        "id": str,
        "level": int,
        "display": str,          # primary glyph or word shown/spoken
        "pair": [a, b] | None,   # for discrimination
        "word": str | None,
        "picture_ref": str | None,
      }
    """
    table = table or get_grade1_table()
    word_list = word_list or Grade1WordList()
    level = max(1, min(4, int(level)))
    candidates: List[Dict[str, Any]] = []

    if tag == "blend_required":
        # Prefer word-list entries at every level (soft length split)
        entries = word_list.words_for_tag(tag, specific_instance)
        for entry in entries:
            word = entry.get("word") or ""
            if not word:
                continue
            n = len(word)
            if level == 1 and n > 3:
                continue
            if level == 2 and (n < 3 or n > 5):
                continue
            if level == 3 and n > 6:
                continue
            if level == 4 and n <= 3 and len(entries) > 2:
                continue
            candidates.append({
                "id": _content_id(level, word, word),
                "level": level,
                "display": word,
                "pair": None,
                "word": word,
                "picture_ref": entry.get("picture_ref"),
            })
        return candidates

    if tag == "hal_kirima":
        # Level 1–2: isolated / related forms; 3–4: words if any
        if level <= 2:
            base = specific_instance if isinstance(specific_instance, str) else "ක"
            if isinstance(base, str) and ":" in base:
                base = base.split(":", 1)[0]
            if isinstance(base, str) and len(base) >= 1:
                bare = base[0]
            else:
                bare = "ක"
            hal = bare + "\u0DCA"
            forms = [hal] if level == 1 else [hal, bare]
            for g in forms:
                candidates.append({
                    "id": _content_id(level, g),
                    "level": level,
                    "display": g,
                    "pair": None,
                    "word": None,
                    "picture_ref": None,
                })
            return candidates
        # L3–4: words tagged hal_kirima (may be empty → caller falls back)
        entries = word_list.words_for_tag(tag, specific_instance)
        for entry in entries:
            word = entry.get("word") or ""
            if not word:
                continue
            candidates.append({
                "id": _content_id(level, word, word),
                "level": level,
                "display": word,
                "pair": None,
                "word": word,
                "picture_ref": entry.get("picture_ref"),
            })
        return candidates

    if level <= 2:
        glyphs = (
            _pair_glyphs(specific_instance, table)
            if level == 1
            else _pillam_forms(specific_instance, table)
        )
        pair = _pair_glyphs(specific_instance, table)
        for g in glyphs:
            candidates.append({
                "id": _content_id(level, g),
                "level": level,
                "display": g,
                "pair": pair,
                "word": None,
                "picture_ref": None,
            })
        return candidates

    # Levels 3–4: Grade-1 words (visual_confusion / pillam_subtle / others)
    entries = word_list.words_for_tag(tag, specific_instance)
    # Level 3 ≈ shorter words; Level 4 ≈ longer — soft split by akshara count proxy
    for entry in entries:
        word = entry.get("word") or ""
        # crude length split: L3 <= 4 chars, L4 anything safe
        if level == 3 and len(word) > 5:
            continue
        if level == 4 and len(word) <= 3 and len(entries) > 2:
            # Prefer longer at L4 when alternatives exist
            continue
        pair = entry.get("relevant_pair_or_letter")
        if not pair:
            pair = _pair_glyphs(specific_instance, table)
        candidates.append({
            "id": _content_id(level, word, word),
            "level": level,
            "display": word,
            "pair": list(pair) if pair else None,
            "word": word,
            "picture_ref": entry.get("picture_ref"),
        })
    return candidates


def get_independent_activity_content(
    tag: str,
    specific_instance: Any,
    guided_level: int,
    exclude_instance: Optional[Union[str, Dict[str, Any]]] = None,
    table: Optional[dict] = None,
    word_list: Optional[Grade1WordList] = None,
) -> Dict[str, Any]:
    """
    Step up one level from Guided Practice for Independent Activity.

    Returns:
      {
        "level": int,
        "content_instance": dict,
        "picture_ref": str | None,
      }
    """
    table = table or get_grade1_table()
    word_list = word_list or Grade1WordList()
    guided_level = max(1, min(4, int(guided_level)))
    target_level = min(guided_level + 1, 4)

    candidates = get_candidates(
        tag, target_level, table, word_list, specific_instance
    )
    if not candidates:
        target_level = guided_level
        candidates = get_candidates(
            tag, target_level, table, word_list, specific_instance
        )

    exclude_id = None
    if isinstance(exclude_instance, dict):
        exclude_id = exclude_instance.get("id")
    elif isinstance(exclude_instance, str):
        exclude_id = exclude_instance

    filtered = [c for c in candidates if c.get("id") != exclude_id] if exclude_id else list(candidates)
    if not filtered:
        filtered = list(candidates)

    if not filtered:
        # Absolute fallback: level-1 pair member
        pair = _pair_glyphs(specific_instance, table)
        content = {
            "id": _content_id(1, pair[0]),
            "level": 1,
            "display": pair[0],
            "pair": pair,
            "word": None,
            "picture_ref": None,
        }
        return {
            "level": 1,
            "content_instance": content,
            "picture_ref": None,
        }

    content_instance = random.choice(filtered)
    picture_ref = None
    if target_level in (3, 4):
        picture_ref = content_instance.get("picture_ref")
        if picture_ref is None and content_instance.get("word"):
            picture_ref = word_list.get_picture(content_instance["word"])

    return {
        "level": target_level,
        "content_instance": content_instance,
        "picture_ref": picture_ref,  # None if N/A or missing — not an error
    }
