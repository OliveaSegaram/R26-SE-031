"""Adaptive level engine for Task 02 — early dyslexia identification."""

from __future__ import annotations

import json
import random
import unicodedata
import uuid
from copy import deepcopy
from pathlib import Path
from typing import Any

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "grade1_textbook_words.json"

TASK_TYPES = ("word_match", "picture_word", "word_build", "picture_word_match")
SESSION_TOTAL = 8  # 2 questions per task type × 4 types
BUILD_LETTER_MIN = 2
BUILD_LETTER_MAX = 6
BUILD_DISTRACTOR_LETTERS = [
    "ක", "ම", "ල", "ර", "ස", "ප", "ත", "න", "ග", "ව", "ද", "බ", "හ", "ය",
]

# Words grouped by difficulty tier for adaptive questioning.
LEVEL_BY_SYLLABLES = {1: (1, 1), 2: (2, 3), 3: (4, 99)}


def _load_words() -> list[dict[str, Any]]:
    with open(DATA_PATH, encoding="utf-8") as f:
        payload = json.load(f)
    words: list[dict[str, Any]] = []
    for lesson in payload["lessons"]:
        for w in lesson["words"]:
            entry = deepcopy(w)
            entry["lesson_id"] = lesson["id"]
            entry["lesson_title"] = lesson["title"]
            entry["level"] = _word_level(entry)
            words.append(entry)
    return words


def _split_graphemes(text: str) -> list[str]:
    """One Sinhala letter (grapheme) per item — consonant + vowel signs stay together."""
    clusters: list[str] = []
    i = 0
    chars = list(text)
    while i < len(chars):
        ch = chars[i]
        if ch == " ":
            clusters.append(" ")
            i += 1
            continue
        cluster = ch
        i += 1
        while i < len(chars) and unicodedata.category(chars[i]) in ("Mn", "Mc", "Me"):
            cluster += chars[i]
            i += 1
        clusters.append(cluster)
    return clusters


def _word_letters(word: dict[str, Any]) -> list[str]:
    return _split_graphemes(word.get("word", ""))


def _buildable_words(words: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Short single words only — one letter per box (no phrases or long words)."""
    pool: list[dict[str, Any]] = []
    for w in words:
        text = w.get("word", "")
        if " " in text:
            continue
        letters = _word_letters(w)
        if BUILD_LETTER_MIN <= len(letters) <= BUILD_LETTER_MAX:
            pool.append(w)
    return pool


def _playable_words(words: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Only approved Grade-1 vocabulary from grade1_textbook_words.json."""
    return [w for w in words if len(w.get("word", "")) > 1]


def _word_level(word: dict[str, Any]) -> int:
    n = len(word.get("syllables") or [word["word"]])
    if n <= 1:
        return 1
    if n <= 3:
        return 2
    return 3


def _similar_distractors(pool: list[dict], target: dict, count: int = 2) -> list[dict]:
    """Words that start with the same letter — harder picture/word choices."""
    letters = _word_letters(target)
    if not letters:
        return _distractors(pool, target, count)
    first = letters[0]
    similar = [
        w for w in pool
        if w["word"] != target["word"] and _word_letters(w)[:1] == [first]
    ]
    if len(similar) >= count:
        random.shuffle(similar)
        return similar[:count]
    return _distractors(pool, target, count)


def _distractors(pool: list[dict], target: dict, count: int = 2) -> list[dict]:
    lesson = target.get("lesson_id")
    same_lesson = [
        w for w in pool
        if w["word"] != target["word"] and w.get("lesson_id") == lesson
    ]
    if len(same_lesson) >= count:
        random.shuffle(same_lesson)
        return same_lesson[:count]

    others = [w for w in pool if w["word"] != target["word"]]
    random.shuffle(others)
    return others[:count]


def _pick_match_set(state: dict[str, Any], count: int, level: int) -> list[dict[str, Any]]:
    """Pick several words for a picture↔word matching round."""
    pool: list[dict[str, Any]] = state["words"]
    if level >= 3:
        by_lesson: dict[int, list[dict[str, Any]]] = {}
        for w in pool:
            lid = w.get("lesson_id")
            if lid is not None:
                by_lesson.setdefault(lid, []).append(w)
        viable = [lesson_words for lesson_words in by_lesson.values() if len(lesson_words) >= count]
        if viable:
            return random.sample(random.choice(viable), count)

    deck_key = "match_word_deck"
    pos_key = "match_deck_pos"
    deck: list[dict] = state.get(deck_key) or []
    pos: int = state.get(pos_key, 0)
    if not deck or pos + count > len(deck):
        deck = list(pool)
        random.shuffle(deck)
        state[deck_key] = deck
        pos = 0
    selected = deck[pos : pos + count]
    state[pos_key] = pos + count
    return selected


def _pick_word(state: dict[str, Any], pool: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    """Pick the next word without repeating until the deck is exhausted."""
    words = pool if pool is not None else state["words"]
    deck_key = "word_deck" if pool is None else "build_word_deck"
    pos_key = "deck_pos" if pool is None else "build_deck_pos"
    deck: list[dict] = state.get(deck_key) or []
    pos: int = state.get(pos_key, 0)
    if not deck or pos >= len(deck):
        deck = list(words)
        random.shuffle(deck)
        state[deck_key] = deck
        pos = 0
    word = deck[pos]
    state[pos_key] = pos + 1
    return word


def _word_visual(word: dict) -> str:
    return word.get("visual") or "letter"


def _build_word_match(word: dict, pool: list[dict], level: int) -> dict[str, Any]:
    options = [word] + _distractors(pool, word, 3)
    random.shuffle(options)
    return {
        "task_type": "word_match",
        "level": level,
        "prompt": "මේ වචනයට ගැලපෙන පින්තූරය තෝරන්න!",
        "target_word": word["word"],
        "display_word": word["word"] if level >= 2 else word["word"][0],
        "visual": _word_visual(word),
        "card_color": word.get("card_color"),
        "options": [
            {
                "id": o["word"],
                "label": o["word"],
                "visual": _word_visual(o),
                "card_color": o.get("card_color"),
            }
            for o in options
        ],
        "correct_id": word["word"],
        "hint": word["meaning"] if level == 1 else None,
        "lesson_ref": word.get("lesson_ref"),
    }


def _build_picture_word(word: dict, pool: list[dict], level: int) -> dict[str, Any]:
    dist_fn = _similar_distractors if level >= 3 else _distractors
    options = [word] + dist_fn(pool, word, 2)
    random.shuffle(options)
    prompt = "පින්තූරය බලා වචනය තෝරන්න!"
    if level == 1:
        prompt = "පින්තූරය බලා අකුර තෝරන්න!"
        dist = dist_fn(pool, word, 3)
        letters = {word["word"][0]}
        option_words: list[dict] = [{"word": word["word"][0]}]
        for d in dist:
            ch = d["word"][0]
            if ch not in letters:
                letters.add(ch)
                option_words.append({"word": ch})
            if len(option_words) >= 3:
                break
        while len(option_words) < 3:
            option_words.append({"word": "?"})
        options = option_words
        random.shuffle(options)
    elif level >= 3:
        prompt = "පින්තූරය බලා හරි වචනය තෝරන්න! සමාන වචන වලට සැලකිලිමත් වන්න!"
    return {
        "task_type": "picture_word",
        "level": level,
        "prompt": prompt,
        "visual": _word_visual(word),
        "card_color": word.get("card_color"),
        "meaning_hint": word["meaning"] if level <= 2 else None,
        "options": [{"id": o["word"], "label": o["word"]} for o in options],
        "correct_id": word["word"][0] if level == 1 else word["word"],
        "lesson_ref": word.get("lesson_ref"),
    }


def _build_word_build(word: dict, level: int) -> dict[str, Any]:
    letters = _word_letters(word)
    # Always one box per letter — never show fewer slots than the word has.
    needed = set(letters)
    extras: list[str] = []
    for candidate in BUILD_DISTRACTOR_LETTERS:
        if candidate in needed:
            continue
        if any(n.startswith(candidate) or candidate.startswith(n) for n in needed):
            continue
        extras.append(candidate)
    random.shuffle(extras)
    extra_count = {1: 2, 2: 3, 3: 4}.get(level, 3)
    tiles = list(letters) + extras[: max(0, extra_count)]
    random.shuffle(tiles)
    return {
        "task_type": "word_build",
        "level": level,
        "prompt": "එක අකුරු එක බොක්සයකට දාලා වචනය හදන්න!",
        "target_word": word["word"],
        "visual": _word_visual(word),
        "card_color": word.get("card_color"),
        "tiles": tiles,
        "correct_sequence": letters,
        "correct_id": word["word"],
        "lesson_ref": word.get("lesson_ref"),
    }


def _build_picture_word_match(pool: list[dict], level: int, state: dict[str, Any]) -> dict[str, Any]:
    pair_count = 3 if level == 1 else 4
    words = _pick_match_set(state, pair_count, level)
    pairs = [
        {
            "id": w["word"],
            "word": w["word"],
            "visual": _word_visual(w),
            "meaning": w.get("meaning", ""),
        }
        for w in words
    ]
    mapping = {w["word"]: w["word"] for w in words}
    prompts = {
        1: "වචනයක් තෝරා ගැලපෙන පින්තූරය තෝරන්න!",
        2: "සිංහල වචනයට හරි පින්තූරය යොදන්න!",
        3: "සමාන වචන වලට සැලකිලිමත් වෙලා හරි යුගල තෝරන්න!",
    }
    return {
        "task_type": "picture_word_match",
        "level": level,
        "prompt": prompts.get(level, prompts[2]),
        "pairs": pairs,
        "correct_id": json.dumps(mapping, ensure_ascii=False),
        "lesson_ref": words[0].get("lesson_ref") if words else None,
    }


BUILDERS = {
    "word_match": _build_word_match,
    "picture_word": _build_picture_word,
    "word_build": _build_word_build,
}


class AdaptiveSession:
    """In-memory session; swap for MongoDB in production."""

    _store: dict[str, dict[str, Any]] = {}

    @classmethod
    def create(cls, student_id: str = "guest") -> dict[str, Any]:
        all_words = _load_words()
        words = _playable_words(all_words)
        build_words = _buildable_words(words)
        if not words:
            raise RuntimeError("No playable words in grade1_textbook_words.json")
        if not build_words:
            raise RuntimeError("No buildable words for word_build tasks")
        session_id = str(uuid.uuid4())[:12]
        task_order = [t for t in TASK_TYPES for _ in range(2)]
        state = {
            "session_id": session_id,
            "student_id": student_id,
            "current_level": 2,
            "task_index": 0,
            "task_order": task_order,
            "words": words,
            "build_words": build_words,
            "word_deck": [],
            "deck_pos": 0,
            "build_word_deck": [],
            "build_deck_pos": 0,
            "match_word_deck": [],
            "match_deck_pos": 0,
            "last_task_type": None,
            "responses": [],
            "score_by_level": {1: 0, 2: 0, 3: 0},
            "attempts_by_level": {1: 0, 2: 0, 3: 0},
            "completed": False,
        }
        cls._store[session_id] = state
        return cls._snapshot(state)

    @classmethod
    def get(cls, session_id: str) -> dict[str, Any] | None:
        state = cls._store.get(session_id)
        return cls._snapshot(state) if state else None

    @classmethod
    def next_question(cls, session_id: str) -> dict[str, Any]:
        state = cls._store.get(session_id)
        if not state:
            raise KeyError("session not found")
        if state["completed"]:
            return {"completed": True, "summary": cls._summary(state)}

        task_type = state["task_order"][state["task_index"]]
        # Each activity type starts at level 2 (medium), then adapts up/down.
        if state.get("last_task_type") != task_type:
            state["current_level"] = 2
        state["last_task_type"] = task_type

        level = state["current_level"]
        builder = BUILDERS.get(task_type)
        if task_type == "picture_word_match":
            question = _build_picture_word_match(state["words"], level, state)
        elif task_type == "word_build":
            word = _pick_word(state, pool=state["build_words"])
            question = builder(word, level)
        else:
            word = _pick_word(state)
            question = builder(word, state["words"], level)

        state["active_question"] = question
        return {"session_id": session_id, "question": question, "progress": cls._progress(state)}

    @classmethod
    def submit(cls, session_id: str, answer: str) -> dict[str, Any]:
        state = cls._store.get(session_id)
        if not state or "active_question" not in state:
            raise KeyError("no active question")

        q = state["active_question"]
        if q["task_type"] == "word_build":
            expected = "".join(q["correct_sequence"])
            correct = answer.strip() == expected or answer.strip() == (q.get("target_word") or "")
        elif q["task_type"] == "picture_word_match":
            try:
                submitted = json.loads(answer)
            except json.JSONDecodeError:
                correct = False
            else:
                try:
                    expected = json.loads(q["correct_id"])
                except json.JSONDecodeError:
                    correct = False
                else:
                    correct = submitted == expected
        else:
            correct = answer.strip() == q["correct_id"]

        level = q["level"]
        state["attempts_by_level"][level] += 1
        if correct:
            state["score_by_level"][level] += 1

        prev_level = state["current_level"]
        # Adaptive staircase: L2 start → wrong goes easier → correct at L2 goes harder.
        if not correct:
            if level >= 2:
                state["current_level"] = max(1, level - 1)
                next_action = "level_down"
            else:
                next_action = "stay_easy"
        elif level < 3:
            state["current_level"] = min(3, level + 1)
            next_action = "level_up"
        else:
            next_action = "stay_hard"

        state["responses"].append(
            {
                "task_type": q["task_type"],
                "level": level,
                "word": q.get("target_word") or q.get("correct_id"),
                "correct": correct,
                "answer": answer,
            }
        )
        del state["active_question"]
        state["task_index"] += 1

        if state["task_index"] >= SESSION_TOTAL:
            state["completed"] = True
            return {
                "correct": correct,
                "next_action": next_action,
                "new_level": state["current_level"],
                "previous_level": prev_level,
                "completed": True,
                "summary": cls._summary(state),
            }

        return {
            "correct": correct,
            "next_action": next_action,
            "new_level": state["current_level"],
            "previous_level": prev_level,
            "completed": False,
            "progress": cls._progress(state),
        }

    @staticmethod
    def _progress(state: dict) -> dict[str, int]:
        return {
            "answered": state["task_index"],
            "total": SESSION_TOTAL,
            "current_level": state["current_level"],
            "task_type": (
                state["task_order"][state["task_index"]]
                if state["task_index"] < SESSION_TOTAL
                else None
            ),
        }

    @classmethod
    def _summary(cls, state: dict) -> dict[str, Any]:
        total_attempts = sum(state["attempts_by_level"].values())
        total_correct = sum(state["score_by_level"].values())
        accuracy = round(total_correct / max(1, total_attempts), 2)
        l1 = state["attempts_by_level"][1]
        l2 = state["attempts_by_level"][2]
        l3 = state["attempts_by_level"][3]

        if accuracy >= 0.8 and l3 >= 2:
            risk = "low"
            label = "හොඳයි! කියවීමේ මූලික කුසලතා ශක්තිමත්ය."
        elif accuracy >= 0.55 or (l2 >= 2 and state["score_by_level"][2] >= 1):
            risk = "moderate"
            label = "මධ්‍යම. සරල වචන වලින් උදව් අවශ්‍ය විය හැක."
        else:
            risk = "elevated"
            label = "උදව් අවශ්‍යයි. මූලික අකුරු සහ සරල වචන වලින් පටන් ගමු."

        return {
            "accuracy": accuracy,
            "risk_level": risk,
            "label_si": label,
            "by_level": state["score_by_level"],
            "attempts_by_level": state["attempts_by_level"],
            "responses": state["responses"],
        }

    @staticmethod
    def _snapshot(state: dict | None) -> dict[str, Any] | None:
        if not state:
            return None
        return {
            "session_id": state["session_id"],
            "student_id": state["student_id"],
            "current_level": state["current_level"],
            "progress": AdaptiveSession._progress(state),
            "completed": state["completed"],
        }


def list_curriculum() -> dict[str, Any]:
    with open(DATA_PATH, encoding="utf-8") as f:
        payload = json.load(f)
    payload["playable_word_count"] = len(_playable_words(_load_words()))
    return payload
