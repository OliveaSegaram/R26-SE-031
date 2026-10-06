"""Generate the reviewed Component 4 item variants for Skills 1-4.

This is a deterministic curriculum build step.  It snapshots the four Skill 1
runtime generators into the canonical curriculum and gives every core item two
unseen, same-difficulty equivalents:

* V1 - remediation content
* V2 - independent confirmation content

The generated JSON remains the runtime source for Flutter and the item-bank
source for the adaptive service, preventing frontend/backend content drift.
"""

from __future__ import annotations

import copy
import json
import re
from pathlib import Path
from typing import Any, Callable, Dict, List


ROOT = Path(__file__).resolve().parents[2]
CURRICULUM = ROOT / "frontend" / "assets" / "data" / "curriculum"

ASSETS = [
    "animals/bird.png", "animals/butterfly.png", "animals/cat.png",
    "animals/cow.png", "animals/dog.png", "animals/elephant.png",
    "animals/fish.png", "animals/frog.png", "animals/rabbit.png",
    "animals/snail.png", "animals/turtle.png", "fruits_food/apple.png",
    "fruits_food/banana.png", "fruits_food/grapes.png",
    "fruits_food/ice_cream.png", "fruits_food/mango.png",
    "fruits_food/orange.png", "fruits_food/watermelon.png",
    "flowers/nil_manel.png", "flowers/nelum.png", "flowers/araliya.png",
    "flowers/wada_mal.png", "flowers/flower_05.png", "vehicles/airplane.png",
    "vehicles/bicycle.png", "vehicles/boat.png", "vehicles/train.png",
    "vehicles/van.png", "everyday_objects/book.png", "everyday_objects/key.png",
    "everyday_objects/bell.png", "everyday_objects/clock.png",
    "everyday_objects/hat.png", "everyday_objects/kite.png",
    "everyday_objects/umbrella.png", "everyday_objects/pencil.png",
]

ASSET_NAMES = {
    "animals/bird.png": "කුරුල්ලා", "animals/butterfly.png": "සමනලයා",
    "animals/cat.png": "පූසා", "animals/cow.png": "එළදෙන",
    "animals/dog.png": "බල්ලා", "animals/elephant.png": "අලියා",
    "animals/fish.png": "මාළුවා", "animals/frog.png": "ගෙම්බා",
    "animals/rabbit.png": "හාවා", "animals/snail.png": "ගොළුබෙල්ලා",
    "animals/turtle.png": "ඉබ්බා", "fruits_food/apple.png": "ඇපල් ගෙඩිය",
    "fruits_food/banana.png": "කෙසෙල් ගෙඩිය", "fruits_food/grapes.png": "මිදි",
    "fruits_food/mango.png": "අඹ ගෙඩිය", "fruits_food/orange.png": "දොඩම් ගෙඩිය",
    "fruits_food/watermelon.png": "කොමඩු ගෙඩිය", "vehicles/boat.png": "ඔරුව",
    "vehicles/train.png": "දුම්රිය", "vehicles/van.png": "වෑන් රථය",
    "vehicles/airplane.png": "ගුවන් යානය", "vehicles/bicycle.png": "බයිසිකලය",
    "everyday_objects/book.png": "පොත", "everyday_objects/key.png": "යතුර",
    "everyday_objects/bell.png": "සීනුව", "everyday_objects/clock.png": "ඔරලෝසුව",
    "everyday_objects/hat.png": "තොප්පිය", "everyday_objects/kite.png": "සරුංගලය",
}


def canonical(value: str) -> str:
    compact = value.replace("_", "").replace("-", "")
    match = re.fullmatch(r"S(\d+)A(\d+)R(\d+)(V\d+)?", compact, re.I)
    if not match:
        return value
    return f"S{match.group(1)}A{match.group(2)}R{int(match.group(3)):02d}{match.group(4) or ''}".upper()


def metadata(round_number: int, difficulty: float, *, anchor: bool = False) -> Dict[str, Any]:
    return {
        "item_version": 2,
        "difficulty_label": "easy" if difficulty < -0.25 else "hard" if difficulty > 0.75 else "medium",
        "difficulty_b": difficulty,
        "is_anchor": anchor,
        "equivalent_group_id": "",
    }


def skill1_rounds() -> Dict[str, List[Dict[str, Any]]]:
    shadow_counts = [2, 3, 4, 5, 6]
    shadows = []
    for index, count in enumerate(shadow_counts):
        row = {"target_assets": ASSETS[index:index + count], "difficulty": index + 1}
        row.update(metadata(index + 1, [-1.0, -1.0, 0.0, 0.0, 1.0][index], anchor=index == 3))
        shadows.append(row)

    category_assets = {
        "animals": ASSETS[0:11],
        "fruits": ASSETS[11:18],
        "flowers": ASSETS[18:23],
        "vehicles": ASSETS[23:28],
    }
    category_labels = {"animals": "සතුන්", "fruits": "පලතුරු", "flowers": "මල්", "vehicles": "වාහන"}
    category_icons = {"animals": "animals/elephant.png", "fruits": "fruits_food/apple.png", "flowers": "flowers/nelum.png", "vehicles": "vehicles/van.png"}
    layouts = [(["animals", "fruits"], [2, 1]), (["vehicles", "flowers"], [2, 2]),
               (["animals", "fruits"], [3, 3]), (["animals", "fruits", "vehicles"], [2, 2, 2]),
               (["fruits", "vehicles", "flowers"], [3, 3, 3])]
    sorting = []
    for index, (categories, counts) in enumerate(layouts):
        selected = {key: category_assets[key][:counts[pos]] for pos, key in enumerate(categories)}
        row = {
            "categories": selected,
            "category_labels": {key: category_labels[key] for key in categories},
            "category_icons": {key: category_icons[key] for key in categories},
            "difficulty": index + 1,
        }
        row.update(metadata(index + 1, [-1.0, -1.0, 0.0, 0.0, 1.0][index], anchor=index == 3))
        sorting.append(row)

    structures = ["ABAB", "AABB", "ABCAB", "ABCDAB", "ABBCABBC"]
    option_counts = [2, 3, 3, 4, 4]
    patterns = []
    for index, structure in enumerate(structures):
        symbols = sorted(set(structure))
        mapping = {symbol: ASSETS[index * 4 + pos] for pos, symbol in enumerate(symbols)}
        full = [mapping[symbol] for symbol in structure]
        correct = full[-1]
        options = [correct]
        for asset in ASSETS[index * 4 + len(symbols):]:
            if asset not in options:
                options.append(asset)
            if len(options) == option_counts[index]:
                break
        row = {
            "sequence": [*full[:-1], None], "missing_index": len(full) - 1,
            "correct_answer": correct, "options": options, "difficulty": index + 1,
        }
        row.update(metadata(index + 1, [-1.0, -1.0, 0.0, 0.0, 1.0][index], anchor=index == 3))
        patterns.append(row)

    memory = []
    for index, (count, duration) in enumerate([(2, 6000), (3, 5000), (3, 4000), (4, 4000), (5, 4000)]):
        assets = ASSETS[index * 3:index * 3 + count]
        row = {"assets": assets, "target_asset": assets[index % count], "show_milliseconds": duration}
        row.update(metadata(index + 1, [-1.0, -1.0, 0.0, 0.0, 1.0][index], anchor=index == 3))
        memory.append(row)
    return {"act_2": shadows, "act_3": sorting, "act_4": patterns, "act_5": memory}


LETTER_SETS = [
    ("ක", ["ත", "ව", "ය", "ක"]), ("ග", ["ද", "න", "ග", "ර"]),
    ("ප", ["බ", "ම", "ය", "ප"]), ("ල", ["ව", "ර", "ල", "ස"]),
    ("න", ["ම", "න", "ත", "ද"]), ("ස", ["හ", "ව", "ස", "ර"]),
    ("ට", ["ඩ", "ත", "ට", "ප"]), ("බ", ["ප", "ම", "බ", "ද"]),
    ("ඉ", ["ඊ", "උ", "ඉ", "එ"]), ("උ", ["ඔ", "ඌ", "උ", "අ"]),
    ("එ", ["ඒ", "ඔ", "එ", "ඇ"]), ("හ", ["ස", "හ", "න", "ව"]),
    ("ච", ["ජ", "ට", "ච", "ක"]), ("ද", ["ත", "ධ", "ද", "න"]),
]

PAIR_SETS = [
    ["ත", "ව"], ["ය", "ර"], ["ප", "ස"], ["අ", "ඉ"], ["ක", "ග", "ම"],
    ["ට", "ඩ", "න"], ["ක", "ග", "ත", "ද"], ["ප", "බ", "ම", "ය"],
    ["ක", "ග", "ට", "ඩ", "ත"], ["ද", "න", "ප", "බ", "ම"],
    ["ර", "ල", "ව", "ස"], ["අ", "ආ", "ඉ", "ඊ"],
    ["බ", "ප", "ල"], ["උ", "එ", "ඔ"],
]

WORD_PARTS = [
    (["අ", "ත"], "අත"), (["ග", "ස"], "ගස"), (["ඉ", "ර"], "ඉර"),
    (["ම", "ල"], "මල"), (["කු", "ඩ", "ය"], "කුඩය"),
    (["ක", "ඩ", "ය"], "කඩය"),
    (["ත", "රු", "ව"], "තරුව"), (["පු", "ටු", "ව"], "පුටුව"),
    (["ප", "හ", "න"], "පහන"), (["ප", "නා", "ව"], "පනාව"),
    (["බ", "ල්", "ලා"], "බල්ලා"), (["අ", "ක්", "කා"], "අක්කා"),
    (["කු", "රු", "ල්", "ලා"], "කුරුල්ලා"), (["පා", "ස", "ල"], "පාසල"),
]

PICTURE_WORDS = [
    ("assets/images/activity_icons/animals/cat.png", "පූසා"),
    ("assets/images/activity_icons/animals/dog.png", "බල්ලා"),
    ("assets/images/activity_icons/animals/fish.png", "මාළුවා"),
    ("assets/images/activity_icons/animals/bird.png", "කුරුල්ලා"),
    ("assets/images/activity_icons/fruits_food/apple.png", "ඇපල්"),
    ("assets/images/activity_icons/fruits_food/banana.png", "කෙසෙල්"),
    ("assets/images/activity_icons/fruits_food/mango.png", "අඹ"),
    ("assets/images/activity_icons/everyday_objects/book.png", "පොත"),
    ("assets/images/activity_icons/everyday_objects/hat.png", "තොප්පිය"),
    ("assets/images/activity_icons/everyday_objects/clock.png", "ඔරලෝසුව"),
    ("assets/images/activity_icons/vehicles/train.png", "දුම්රිය"),
    ("assets/images/activity_icons/vehicles/boat.png", "ඔරුව"),
    ("assets/images/activity_icons/vehicles/bicycle.png", "බයිසිකලය"),
    ("assets/images/activity_icons/nature/moon.png", "හඳ"),
]

SENTENCES = [
    ("assets/images/games/boy_drawing.png", "මල්ලි චිත්‍රයක් අඳිනවා."),
    ("assets/images/games/boy_flying_kite.png", "මල්ලි සරුංගලයක් යවනවා."),
    ("assets/images/games/boy_feeding_dog.jpg", "මල්ලි බල්ලාට කෑම දෙනවා."),
    ("assets/images/games/children_playing_ball.jpg", "ළමයි බෝල සෙල්ලම් කරනවා."),
    ("assets/images/games/girl_reading_tree.jpg", "නංගි පොතක් කියවනවා."),
    ("assets/images/games/girl_going_to_school.png", "නංගි පාසල් යනවා."),
    ("assets/images/games/flower_blooming.png", "මල් පිපෙනවා."),
    ("assets/images/games/moon_shining.png", "හඳ පායනවා."),
    ("assets/images/games/mother_cooking.png", "අම්මා කෑම උයනවා."),
    ("assets/images/games/rowing_boat.png", "තාත්තා ඔරුව පදිනවා."),
]


def rotate(values: List[Any], start: int, count: int) -> List[Any]:
    return [copy.deepcopy(values[(start + offset) % len(values)]) for offset in range(count)]


def variant_content(skill: int, activity: int, round_index: int, variant: int, core: Dict[str, Any]) -> Dict[str, Any]:
    slot = (round_index - 1) * 2 + (variant - 1)
    option_count = len((core.get("content") or core).get("options") or [])

    if skill == 1 and activity == 1:
        target_count = int(core.get("target_count", 1))
        distractor_count = int(core.get("distractor_count", len(core.get("distractors", []))))
        target = ASSETS[(slot + 5) % len(ASSETS)]
        distractors = [asset for asset in rotate(ASSETS, slot + 11, distractor_count + 1) if asset != target][:distractor_count]
        name = ASSET_NAMES.get(target, "පින්තූරය")
        return {"targets": [target], "target_count": target_count, "distractors": distractors,
                "distractor_count": distractor_count, "instruction": f"{name} සොයන්න!"}

    if skill == 1 and activity == 2:
        count = len(core["target_assets"])
        return {"target_assets": rotate(ASSETS, 12 + slot * 3, count), "difficulty": core["difficulty"]}

    if skill == 1 and activity == 3:
        categories = list(core["categories"])
        shifted = {}
        source = {"animals": ASSETS[0:11], "fruits": ASSETS[11:18], "flowers": ASSETS[18:23], "vehicles": ASSETS[23:28]}
        for pos, category in enumerate(categories):
            count = len(core["categories"][category])
            shifted[category] = rotate(source[category], slot + pos + 2, count)
        return {**{key: copy.deepcopy(value) for key, value in core.items() if key not in {"categories", "adaptive_variants"}}, "categories": shifted}

    if skill == 1 and activity == 4:
        sequence = list(core["sequence"])
        unique = max(2, len({value for value in sequence if value is not None}))
        chosen = rotate(ASSETS, 10 + slot * 4, unique + len(core["options"]))
        old_values = []
        for value in sequence:
            if value is not None and value not in old_values:
                old_values.append(value)
        mapping = {value: chosen[pos] for pos, value in enumerate(old_values)}
        new_sequence = [mapping.get(value) if value is not None else None for value in sequence]
        correct = mapping[core["correct_answer"]]
        options = [correct]
        for value in chosen[unique:]:
            if value not in options:
                options.append(value)
            if len(options) == len(core["options"]):
                break
        return {"sequence": new_sequence, "missing_index": core["missing_index"], "correct_answer": correct,
                "options": options, "difficulty": core["difficulty"]}

    if skill == 1 and activity == 5:
        count = len(core["assets"])
        assets = rotate(ASSETS, 8 + slot * 3, count)
        return {"assets": assets, "target_asset": assets[(slot + 1) % count],
                "show_milliseconds": core["show_milliseconds"]}

    if skill == 2 and activity == 1:
        target, letters = LETTER_SETS[slot % len(LETTER_SETS)]
        source = core.get("content") or core
        count = len(source.get("items", []))
        target_count = sum(1 for item in source.get("items", []) if item.get("is_target")) or 1
        distractor = next(value for value in letters if value != target)
        items = [{"type": "letter", "value": distractor, "is_target": False} for _ in range(count - target_count)]
        items += [{"type": "letter", "value": target, "is_target": True} for _ in range(target_count)]
        return {"prompt": f"'{target}' අකුර සොයන්න.", "items": items}

    if skill == 2 and activity == 2:
        count = len((core.get("content") or core).get("letters", []))
        return {"letters": rotate(PAIR_SETS[slot % len(PAIR_SETS)], 0, count)}

    if skill == 2 and activity == 3:
        target, letters = LETTER_SETS[slot % len(LETTER_SETS)]
        count = option_count or (2 + min(round_index - 1, 3))
        options = rotate(letters, variant, count)
        if target not in options:
            options[-1] = target
        return {"prompt": "ශබ්දයට සවන් දී අකුර තෝරන්න", "audio_text": target,
                "options": options, "correctOption": target, "correct_index": options.index(target)}

    if skill == 2 and activity == 4:
        parts, word = WORD_PARTS[slot % len(WORD_PARTS)]
        choose_first = round_index not in {3, 4}
        if round_index == 5:
            targets = [parts[0], parts[-1]]
            options = rotate([*parts, "ම", "ය", "ව", "ස"], variant, max(6, option_count))
            for target in targets:
                if target not in options:
                    options[-targets.index(target) - 1] = target
            return {"prompt": f"'{word}' යන වචනයේ මුල් සහ අග අකුරු තෝරන්න", "options": options,
                    "correct_indices": [options.index(target) for target in targets]}
        target = parts[0] if choose_first else parts[-1]
        candidates = [target, "ම", "ය", "ව", "ස", "ත"]
        options = rotate(candidates, variant, max(2, option_count))
        if target not in options:
            options[-1] = target
        position = "මුල්" if choose_first else "අග"
        return {"prompt": f"'{word}' යන වචනයේ {position} අකුර කුමක්ද?", "options": options,
                "correctOption": target, "correct_index": options.index(target)}

    if skill == 2 and activity == 5:
        parts, _ = WORD_PARTS[slot % len(WORD_PARTS)]
        length = len((core.get("pattern") or []))
        pattern = rotate(parts, 0, length)
        distractor = next(value for value in ["ක", "ම", "ය", "ව", "ස"] if value not in pattern)
        return {"show_seconds": core.get("show_seconds", 5), "pattern": pattern, "options": [*pattern, distractor]}

    if skill == 3 and activity == 1:
        image, target = PICTURE_WORDS[slot % len(PICTURE_WORDS)]
        count = option_count or 3
        labels = [entry[1] for entry in rotate(PICTURE_WORDS, slot + 1, count - 1)]
        options = [target, *[label for label in labels if label != target]][:count]
        return {"prompt": "පින්තූරයට ගැලපෙන වචනය තෝරන්න", "image_url": image,
                "options": options, "correctOption": target, "correct_index": options.index(target)}

    if skill == 3 and activity == 2:
        parts, target = WORD_PARTS[slot % len(WORD_PARTS)]
        count = option_count or 3
        other_words = [word for _, word in rotate(WORD_PARTS, slot + 1, count) if word != target]
        options = [target, *other_words][:count]
        joined = " + ".join(f"'{part}'" for part in parts)
        return {"prompt": f"{joined} එකතු වූ විට හැදෙන වචනය කුමක්ද?", "options": options,
                "correctOption": target, "correct_index": options.index(target)}

    if skill == 3 and activity == 3:
        _, target = WORD_PARTS[slot % len(WORD_PARTS)]
        count = option_count or 3
        others = [word for _, word in rotate(WORD_PARTS, slot + 2, count) if word != target]
        options = [target, *others][:count]
        return {"prompt": "ශබ්දයට සවන් දී නිවැරදි වචනය තෝරන්න", "audio_text": target,
                "options": options, "correctOption": target, "correct_index": options.index(target)}

    if skill == 3 and activity == 4:
        parts, word = WORD_PARTS[slot % len(WORD_PARTS)]
        blank = slot % len(parts)
        target = parts[blank]
        sequence = list(parts)
        sequence[blank] = None
        count = option_count or 3
        candidates = [target, "ක", "ම", "ය", "ව", "ස"]
        options = rotate(candidates, variant, count)
        if target not in options:
            options[-1] = target
        return {"prompt": f"'{word}' වචනයේ අඩු අකුර තෝරන්න", "sequence": sequence,
                "options": options, "correctOption": target, "correct_index": options.index(target)}

    if skill == 3 and activity == 5:
        parts, word = WORD_PARTS[slot % len(WORD_PARTS)]
        return {"prompt": "අකුරු පිළිවෙළට සකසා වචනය හදන්න", "correct_word": word,
                "scrambled_letters": list(reversed(parts))}

    if skill == 4 and activity == 1:
        image, sentence = SENTENCES[slot % len(SENTENCES)]
        count = option_count or 3
        others = [value for _, value in rotate(SENTENCES, slot + 1, count) if value != sentence]
        options = [sentence, *others][:count]
        return {"prompt": "පින්තූරයට ගැලපෙන වාක්‍යය තෝරන්න", "image_url": image,
                "options": options, "correctOption": sentence, "correct_index": options.index(sentence)}

    if skill == 4 and activity == 2:
        image, sentence = SENTENCES[slot % len(SENTENCES)]
        words = sentence.rstrip(".").split()
        blank = 0 if round_index <= 2 else min(1, len(words) - 1)
        target = words[blank]
        sequence: List[Any] = list(words)
        sequence[blank] = None
        count = option_count or 3
        distractors = ["පොත", "මල්", "කෑම", "පාසල්", "බෝලය", "හඳ"]
        options = [target, *[word for word in rotate(distractors, slot, count) if word != target]][:count]
        return {"prompt": "හිස්තැනට සුදුසු වචනය තෝරන්න", "sequence": sequence, "image_url": image,
                "options": options, "correctOption": target, "correct_index": options.index(target)}

    if skill == 4 and activity == 3:
        _, sentence = SENTENCES[slot % len(SENTENCES)]
        words = sentence.rstrip(".").split()
        count = option_count or 3
        wrong = [" ".join(reversed(words)) + "."]
        if len(words) >= 3:
            wrong.append(" ".join([words[1], words[0], *words[2:]]) + ".")
            wrong.append(" ".join([*words[:-2], words[-1], words[-2]]) + ".")
        options = [sentence, *wrong]
        while len(options) < count:
            options.append(SENTENCES[(slot + len(options)) % len(SENTENCES)][1])
        options = options[:count]
        return {"prompt": "ශබ්දයට සවන් දී නිවැරදි වාක්‍ය තෝරන්න", "audio_text": sentence,
                "options": options, "correctOption": sentence, "correct_index": options.index(sentence)}

    if skill == 4 and activity == 4:
        desired = len((core.get("scrambled_words") or []))
        eligible = [
            entry for entry in SENTENCES
            if len(entry[1].rstrip(".").split()) >= desired
        ]
        image, sentence = eligible[slot % len(eligible)]
        words = sentence.rstrip(".").split()
        if desired and len(words) > desired:
            words = words[:desired - 1] + [" ".join(words[desired - 1:])]
        return {"prompt": "පින්තූරයට අදාළ වාක්‍යය සාදන්න", "image_url": image,
                "correct_sentence": " ".join(words) + ".", "scrambled_words": list(reversed(words))}

    raise ValueError(f"No variant generator for Skill {skill} Activity {activity}")


def build() -> None:
    skill1 = skill1_rounds()
    for skill in range(1, 5):
        path = CURRICULUM / f"skill_{skill}.json"
        decoded = json.loads(path.read_text(encoding="utf-8"))
        root = decoded[0] if isinstance(decoded, list) else decoded
        for activity in root["activities"]:
            activity_number = int(re.search(r"\d+", activity["id"]).group())
            if skill == 1 and activity["id"] in skill1:
                activity["rounds"] = skill1[activity["id"]]
                activity["file_path"] = ""
            rounds = activity.get("rounds") or activity.get("core_rounds") or []
            for round_index, round_data in enumerate(rounds, start=1):
                item_id = canonical(round_data.get("item_id") or f"S{skill}A{activity_number}R{round_index:02d}")
                round_data["item_id"] = item_id
                round_data["item_version"] = max(2, int(round_data.get("item_version", 1)))
                round_data["equivalent_group_id"] = item_id
                if round_data.get("difficulty_b") is None:
                    round_data["difficulty_b"] = round(
                        -1.0 + (2.0 * (round_index - 1) / max(1, len(rounds) - 1)),
                        2,
                    )
                if not round_data.get("difficulty_label"):
                    difficulty = float(round_data["difficulty_b"])
                    round_data["difficulty_label"] = (
                        "easy" if difficulty < -0.25 else
                        "hard" if difficulty > 0.75 else "medium"
                    )
                round_data.setdefault("is_anchor", round_index == 4)
                variants = []
                for variant_number, role in ((1, "REMEDIATION"), (2, "CONFIRMATION")):
                    content = variant_content(skill, activity_number, round_index, variant_number, round_data)
                    variants.append({
                        "variant_id": f"V{variant_number}",
                        "item_id": f"{item_id}V{variant_number}",
                        "item_version": 2,
                        "item_role": role,
                        "difficulty_b": round_data.get("difficulty_b"),
                        "difficulty_label": round_data.get("difficulty_label"),
                        "content": content,
                    })
                round_data["adaptive_variants"] = variants
        path.write_text(json.dumps(decoded, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    build()
