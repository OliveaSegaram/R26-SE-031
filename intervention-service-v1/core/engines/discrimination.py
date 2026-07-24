"""
Discrimination Engine — visual_confusion + pillam_subtle.

Templates (button choice only — Grade-1 friendly):
  A) Same or Different?
  B) Touch/Pick the Sound

Independent Activity: same templates, level = guided_level + 1
(see independent_activity_stepup_spec.md).
"""

from __future__ import annotations

import random
from typing import Any, Dict, Optional, Tuple

from ..intervention_cycle import Stage, CycleState
from ..question_content import (
    Grade1WordList,
    get_candidates,
    get_independent_activity_content,
)
from ..reference_table import find_confusable_partner, get_grade1_table, validate_content


class QuestionTemplateRegistry:
    def __init__(self):
        self._templates = {
            "same_or_different": self._same_or_different,
            "touch_the_sound": self._touch_the_sound,
        }
        self._order = list(self._templates.keys())

    def pick(self, last_id: Optional[str] = None) -> str:
        choices = [t for t in self._order if t != last_id] or self._order
        return random.choice(choices)

    def build(
        self,
        template_id: str,
        sound_a: str,
        sound_b: str,
        target: str,
        *,
        picture_ref: Optional[str] = None,
        level: Optional[int] = None,
        content_instance: Optional[dict] = None,
    ) -> Dict[str, Any]:
        payload = self._templates[template_id](sound_a, sound_b, target)
        if picture_ref:
            payload["picture_ref"] = picture_ref  # passive visual context only
        if level is not None:
            payload["content_level"] = level
        if content_instance is not None:
            payload["content_instance_id"] = content_instance.get("id")
            if content_instance.get("word"):
                payload["word"] = content_instance["word"]
        return payload

    def _same_or_different(self, sound_a: str, sound_b: str, target: str) -> Dict[str, Any]:
        same = sound_a == sound_b
        return {
            "template_id": "same_or_different",
            "interaction": "choice",
            "play_sequence": [
                {"text": sound_a, "audio_key": f"glyph_{sound_a}"},
                {"text": sound_b, "audio_key": f"glyph_{sound_b}"},
            ],
            "prompt_en": "Same or different?",
            "prompt_si_audio_key": "prompt_same_or_different",
            "choices": [
                {"id": "same", "label_en": "Same", "label_si": "එකම", "is_correct": same},
                {"id": "different", "label_en": "Different", "label_si": "වෙනස්", "is_correct": not same},
            ],
            "correct_choice_id": "same" if same else "different",
            "show_text_labels": True,
        }

    def _touch_the_sound(self, sound_a: str, sound_b: str, target: str) -> Dict[str, Any]:
        options = [sound_a, sound_b]
        random.shuffle(options)
        return {
            "template_id": "touch_the_sound",
            "interaction": "choice",
            "play_sequence": [
                {"text": target, "audio_key": f"glyph_{target}"},
            ],
            "prompt_en": "Which one did I say?",
            "prompt_si_audio_key": "prompt_which_one",
            "choices": [
                {
                    "id": f"opt_{i}",
                    "label_en": opt,
                    "label_si": opt,
                    "display_glyph": opt,
                    "is_correct": opt == target,
                }
                for i, opt in enumerate(options)
            ],
            "correct_choice_id": next(
                f"opt_{i}" for i, opt in enumerate(options) if opt == target
            ),
            "show_text_labels": True,
        }


class DiscriminationEngine:
    name = "DiscriminationEngine"

    def __init__(self):
        self.registry = QuestionTemplateRegistry()
        self.table = get_grade1_table()
        self.word_list = Grade1WordList()

    def resolve_pair(self, tag: str, specific_instance) -> Tuple[str, str]:
        if tag == "visual_confusion":
            if isinstance(specific_instance, (list, tuple)) and len(specific_instance) >= 2:
                a, b = specific_instance[0], specific_instance[1]
            else:
                a = specific_instance if isinstance(specific_instance, str) else "ට"
                b = find_confusable_partner(a, self.table) or "ඨ"
            return a, b

        if isinstance(specific_instance, str) and ":" in specific_instance:
            base, form = specific_instance.split(":", 1)
            cells = self.table.get("consonants", {}).get(base, {}).get("cells", {})
            pairs = {
                "ae": "aae", "i": "ii", "e": "ee", "o": "oo",
                "aae": "ae", "ii": "i", "ee": "e", "oo": "o",
            }
            other = pairs.get(form, "aa")
            a = cells.get(form, {}).get("form") or base
            b = cells.get(other, {}).get("form") or base
            return a, b

        return "කැ", "කෑ"

    def _sounds_from_instance(
        self,
        tag: str,
        specific_instance,
        content_instance: Optional[dict],
        level: int,
    ) -> Tuple[str, str, str]:
        """Return (sound_a, sound_b, target) for a template."""
        if content_instance and content_instance.get("word"):
            # Level 3-4: play/compare using pair letters, but show word as context
            pair = content_instance.get("pair") or list(
                self.resolve_pair(tag, specific_instance)
            )
            a, b = pair[0], pair[1] if len(pair) > 1 else pair[0]
            target = random.choice([a, b])
            return a, b, target

        if content_instance and content_instance.get("display"):
            a, b = self.resolve_pair(tag, specific_instance)
            # Prefer display as one side when it's a pillam form
            disp = content_instance["display"]
            if disp in (a, b):
                target = disp
            else:
                # Level 2 pillam form — pair with confusable/partner form
                partner = b if disp == a else (a if disp == b else b)
                a, b = disp, partner
                target = disp
            return a, b, target

        a, b = self.resolve_pair(tag, specific_instance)
        for g in (a, b):
            if not validate_content(g, self.table, allow_unknown=True):
                return (("ට", "ඨ", "ට") if tag == "visual_confusion" else ("කැ", "කෑ", "කැ"))
        return a, b, random.choice([a, b])

    def _pick_guided_content(self, cycle: CycleState) -> dict:
        cands = get_candidates(
            cycle.tag,
            cycle.level,
            self.table,
            self.word_list,
            cycle.specific_instance,
        )
        if not cands:
            a, b = self.resolve_pair(cycle.tag, cycle.specific_instance)
            return {
                "id": f"L{cycle.level}:glyph:{a}",
                "level": cycle.level,
                "display": a,
                "pair": [a, b],
                "word": None,
                "picture_ref": None,
            }
        return random.choice(cands)

    def _build_choice_payload(
        self,
        cycle: CycleState,
        stage: Stage,
        content_instance: dict,
        level: int,
        picture_ref: Optional[str] = None,
    ) -> Dict[str, Any]:
        avoid = (
            cycle.last_template_id
            if stage == Stage.PROGRESS_CHECK
            else cycle.template_used_guided
        )
        template_id = self.registry.pick(avoid)
        cycle.last_template_id = template_id

        a, b, target = self._sounds_from_instance(
            cycle.tag, cycle.specific_instance, content_instance, level
        )

        if template_id == "same_or_different":
            if random.random() < 0.5:
                sound_a, sound_b, target = a, a, a
            else:
                sound_a, sound_b, target = a, b, a
        else:
            sound_a, sound_b, target = a, b, random.choice([a, b])

        payload = self.registry.build(
            template_id,
            sound_a,
            sound_b,
            target,
            picture_ref=picture_ref,
            level=level,
            content_instance=content_instance,
        )
        # Passive Levels 3-4, include word in display context (passive)
        if content_instance.get("word"):
            payload["display_glyphs"] = [content_instance["word"]]
            payload["context_word"] = content_instance["word"]
        else:
            payload["display_glyphs"] = [sound_a, sound_b]

        if stage == Stage.PROGRESS_CHECK:
            payload["no_hints"] = True
            payload["no_replay_on_wrong"] = True
        return payload

    def build_stage_content(self, cycle: CycleState, stage: Stage) -> Dict[str, Any]:
        if stage == Stage.TEACH:
            a, b = self.resolve_pair(cycle.tag, cycle.specific_instance)
            return {
                "template_id": "teach_pair",
                "interaction": "listen",
                "play_sequence": [
                    {"text": a, "audio_key": f"glyph_{a}"},
                    {"text": b, "audio_key": f"glyph_{b}"},
                ],
                "display_glyphs": [a, b],
                "prompt_en": "Listen to these two sounds.",
                "prompt_si_audio_key": "teach_listen_pair",
                "auto_advance_ms": 2500,
                "content_level": cycle.level,
            }

        if stage == Stage.GUIDED_PRACTICE:
            content = self._pick_guided_content(cycle)
            cycle.meta["guided_content_instance"] = content
            cycle.meta["guided_level"] = cycle.level
            return self._build_choice_payload(
                cycle, stage, content, cycle.level, picture_ref=None
            )

        if stage == Stage.INDEPENDENT_ACTIVITY:
            guided_level = int(cycle.meta.get("guided_level", cycle.level))
            exclude = cycle.meta.get("guided_content_instance")
            step = get_independent_activity_content(
                tag=cycle.tag,
                specific_instance=cycle.specific_instance,
                guided_level=guided_level,
                exclude_instance=exclude,
                table=self.table,
                word_list=self.word_list,
            )
            content = step["content_instance"]
            picture_ref = step["picture_ref"]
            level = step["level"]
            cycle.meta["independent_content_instance"] = content
            cycle.meta["independent_level"] = level
            # Same templates / response handling as Guided — only level/content change
            return self._build_choice_payload(
                cycle, stage, content, level, picture_ref=picture_ref
            )

        if stage == Stage.PROGRESS_CHECK:
            content = self._pick_guided_content(cycle)
            return self._build_choice_payload(
                cycle, stage, content, cycle.level, picture_ref=None
            )

        if stage == Stage.REINFORCEMENT:
            return {
                "template_id": "reinforcement",
                "interaction": "listen",
                "reinforcement": {
                    "id": "re_great",
                    "en": "Great listening!",
                    "si_audio_key": "re_great",
                },
                "auto_advance_ms": 1500,
            }

        return {"template_id": "noop", "interaction": "none"}
