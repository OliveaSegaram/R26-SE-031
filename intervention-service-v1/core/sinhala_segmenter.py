"""
Sinhala Akshara Segmenter + Tag Lookup
----------------------------------------
Splits ANY Sinhala word (whether it's in the Grade 1 textbook or a brand
new word never seen before) into akshara units using Unicode character
classes -- not a lookup table. This is the piece that generalizes beyond
a fixed vocabulary, as we discussed.

An "akshara" here = one base consonant (or independent vowel), plus an
optional conjunct chain (virama + ZWJ + consonant, for clusters like
ක්‍ර), plus an optional dependent vowel sign (pillam).

After segmentation, each unit is looked up against the Grade 1 reference
table (grade1_akshara_table.json) to attach curriculum + difficulty tags.
If a unit isn't in the table yet (row still marked TODO), sensible
default tags are inferred structurally so the pipeline never breaks.
"""

import json
import unicodedata
from dataclasses import dataclass, field

# ---- Unicode ranges for Sinhala ----------------------------------------
INDEPENDENT_VOWELS = set("අආඇඈඉඊඋඌඍඎඑඒඓඔඕඖ")
CONSONANTS = set(
    "කඛගඝඞඟචඡජඣඤඦටඨඩඪණඬතථදධනඳපඵබභමඹයරලවශෂසහළෆ"
)
VIRAMA = "\u0DCA"          # ්  (hal kirima)
ZWJ = "\u200D"             # zero-width joiner, used for conjuncts (ක්‍ර)
DEPENDENT_VOWEL_SIGNS = set(
    "\u0DCF\u0DD0\u0DD1\u0DD2\u0DD3\u0DD4\u0DD6\u0DD8\u0DD9\u0DDA"
    "\u0DDB\u0DDC\u0DDD\u0DDE\u0DDF"
)  # ා ැ ෑ ි ී ු ූ ෘ ෙ ේ ෛ ො ෝ ෞ (approx set incl. rare ones)
ANUSVARA_VISARGA = set("\u0D82\u0D83")  # ං ඃ

VOWEL_SIGN_NAME = {
    "\u0DCF": "aa", "\u0DD0": "ae", "\u0DD1": "aae", "\u0DD2": "i",
    "\u0DD3": "ii", "\u0DD4": "u", "\u0DD6": "uu", "\u0DD9": "e",
    "\u0DDA": "ee", "\u0DDB": "e", "\u0DDC": "o", "\u0DDD": "oo",
    "\u0DDE": "oo", "\u0DDF": "uu",
}


@dataclass
class Akshara:
    text: str                 # the rendered grapheme, e.g. "ගෙ"
    base_consonant: str       # e.g. "ග", or "" for pure vowels
    vowel_form: str           # "hal_kirima" | "a" | "aa" | "ae" | ... 
    has_conjunct: bool = False
    position: int = 0         # index within the word (0-based)
    tags: list = field(default_factory=list)
    in_grade1_scope: bool = None  # True/False/None(unknown - not yet in table)


def segment_word(word: str) -> list:
    """
    Split a Sinhala word into a list of Akshara units.
    Works on any word, in-vocabulary or not.
    """
    word = unicodedata.normalize("NFC", word)
    units = []
    i = 0
    n = len(word)
    pos = 0

    while i < n:
        ch = word[i]

        # Case 1: independent vowel stands alone as its own unit
        if ch in INDEPENDENT_VOWELS:
            units.append(Akshara(text=ch, base_consonant="", vowel_form="independent_vowel", position=pos))
            i += 1
            pos += 1
            continue

        # Case 2: consonant - the main branch
        if ch in CONSONANTS:
            start = i
            base = ch
            i += 1
            has_conjunct = False

            # absorb conjunct chains: virama + ZWJ + consonant (ක් + ZWJ + ර -> ක්‍ර)
            while i + 1 < n and word[i] == VIRAMA and word[i + 1] == ZWJ:
                has_conjunct = True
                i += 2  # skip virama + ZWJ
                if i < n and word[i] in CONSONANTS:
                    i += 1  # absorb the joined consonant

            # plain hal kirima (virama with NO following ZWJ+consonant) = pure consonant sound
            if i < n and word[i] == VIRAMA and not has_conjunct:
                # check it's not actually a conjunct we already consumed
                if not (i + 1 < n and word[i + 1] == ZWJ):
                    i += 1
                    units.append(Akshara(
                        text=word[start:i], base_consonant=base,
                        vowel_form="hal_kirima", has_conjunct=False, position=pos
                    ))
                    pos += 1
                    continue

            # dependent vowel sign attached?
            if i < n and word[i] in DEPENDENT_VOWEL_SIGNS:
                sign = word[i]
                i += 1
                units.append(Akshara(
                    text=word[start:i], base_consonant=base,
                    vowel_form=VOWEL_SIGN_NAME.get(sign, "unknown_sign"),
                    has_conjunct=has_conjunct, position=pos
                ))
                pos += 1
                continue

            # bare consonant = inherent 'a' vowel sound
            units.append(Akshara(
                text=word[start:i], base_consonant=base,
                vowel_form="a", has_conjunct=has_conjunct, position=pos
            ))
            pos += 1
            continue

        # Case 3: anusvara / visarga - attach to previous unit if present, else own unit
        if ch in ANUSVARA_VISARGA:
            if units:
                units[-1].text += ch
            else:
                units.append(Akshara(text=ch, base_consonant="", vowel_form="nasal_mark", position=pos))
                pos += 1
            i += 1
            continue

        # Anything else (punctuation, spaces, non-Sinhala) - skip
        i += 1

    return units


def load_grade1_table(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def attach_tags(units: list, table: dict) -> list:
    """
    Look up each akshara unit against the Grade 1 reference table.
    Falls back to structural defaults if the consonant row is still
    marked TODO (verified: false / empty cells) so the pipeline is
    never blocked on incomplete data entry.
    """
    consonants_table = table.get("consonants", {})
    confusable_flat = set()
    for pair in table.get("confusable_pairs", {}).get("pairs", []):
        confusable_flat.update(pair)

    for u in units:
        if u.vowel_form == "independent_vowel":
            u.tags = []
            u.in_grade1_scope = True  # assume core vowels are in-scope; verify per curriculum
            continue

        row = consonants_table.get(u.base_consonant)
        cell = None
        if row and row.get("cells"):
            cell = row["cells"].get(u.vowel_form)

        if cell:
            u.tags = list(cell.get("tags", []))
            u.in_grade1_scope = cell.get("in_grade1_scope")
        else:
            # structural fallback defaults (used until table row is completed)
            tags = []
            if u.vowel_form == "hal_kirima":
                tags.append("hal_kirima")
            elif u.vowel_form not in ("a",):
                tags.append("blend_required")
            if u.base_consonant in confusable_flat:
                tags.append("visual_confusion")
            if u.has_conjunct:
                tags.append("blend_required")
            u.tags = tags
            u.in_grade1_scope = None  # unknown - table row not completed yet

    return units


def analyze_word(word: str, table: dict) -> list:
    units = segment_word(word)
    return attach_tags(units, table)


if __name__ == "__main__":
    import os
    table_path = os.path.join(os.path.dirname(__file__), "grade1_akshara_table.json")
    table = load_grade1_table(table_path)

    for demo_word in ["ගෙදර", "පොත", "ක්‍රීඩා", "ටැඹ"]:
        print(f"\nWord: {demo_word}")
        for u in analyze_word(demo_word, table):
            print(
                f"  [{u.position}] '{u.text}'  base={u.base_consonant or '-'}  "
                f"vowel_form={u.vowel_form}  conjunct={u.has_conjunct}  "
                f"tags={u.tags}  in_scope={u.in_grade1_scope}"
            )
