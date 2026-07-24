"""
Echo Engine — hal_kirima.

Non-scoring: capture child response only, log voice-activity yes/no.
Independent Activity: same echo template, level = guided_level + 1.
"""

from __future__ import annotations

import random
from typing import Any, Dict, Optional

from ..intervention_cycle import Stage, CycleState, pick_reinforcement
from ..question_content import Grade1WordList, get_candidates, get_independent_activity_content
from ..reference_table import get_grade1_table


class EchoEngine:
    name = "EchoEngine"

    def __init__(self):
        self.table = get_grade1_table()
        self.word_list = Grade1WordList()

    def _default_target(self, cycle: CycleState) -> str:
        inst = cycle.specific_instance
        if isinstance(inst, str) and len(inst) == 1:
            return inst + "\u0DCA"  # consonant + virama
        if isinstance(inst, str):
            return inst
        return "ක්"

    def _pick_guided_content(self, cycle: CycleState) -> dict:
        cands = get_candidates(
            cycle.tag,
            cycle.level,
            self.table,
            self.word_list,
            cycle.specific_instance,
        )
        if not cands:
            t = self._default_target(cycle)
            return {
                "id": f"L{cycle.level}:glyph:{t}",
                "level": cycle.level,
                "display": t,
                "pair": None,
                "word": None,
                "picture_ref": None,
            }
        return random.choice(cands)

    def _echo_payload(
        self,
        cycle: CycleState,
        stage: Stage,
        content: dict,
        level: int,
        picture_ref: Optional[str] = None,
    ) -> Dict[str, Any]:
        target = content.get("display") or self._default_target(cycle)
        payload: Dict[str, Any] = {
            "template_id": "echo_hal",
            "interaction": "record_only",
            "play_sequence": [
                {"text": target, "audio_key": f"glyph_{target}", "effect": "freeze_clip"},
            ],
            "display_glyphs": [target],
            "prompt_en": "Say it after me.",
            "prompt_si_audio_key": "prompt_echo",
            "scoring": "voice_activity_only",
            "no_hints": stage == Stage.PROGRESS_CHECK,
            "correct_signal": "attempted",
            "content_level": level,
            "content_instance_id": content.get("id"),
        }
        if content.get("word"):
            payload["context_word"] = content["word"]
        if picture_ref:
            payload["picture_ref"] = picture_ref
        return payload

    def build_stage_content(self, cycle: CycleState, stage: Stage) -> Dict[str, Any]:
        if stage == Stage.TEACH:
            target = self._default_target(cycle)
            return {
                "template_id": "hal_freeze_demo",
                "interaction": "listen",
                "play_sequence": [
                    {"text": target.replace("\u0DCA", ""), "audio_key": f"glyph_{target[0]}", "effect": "full_vowel"},
                    {"text": target, "audio_key": f"glyph_{target}", "effect": "freeze_clip"},
                ],
                "display_glyphs": [target],
                "prompt_en": "Listen — the sound freezes.",
                "prompt_si_audio_key": "teach_hal_freeze",
                "auto_advance_ms": 3000,
                "content_level": cycle.level,
            }

        if stage == Stage.GUIDED_PRACTICE:
            content = self._pick_guided_content(cycle)
            cycle.meta["guided_content_instance"] = content
            cycle.meta["guided_level"] = cycle.level
            return self._echo_payload(cycle, stage, content, cycle.level)

        if stage == Stage.INDEPENDENT_ACTIVITY:
            guided_level = int(cycle.meta.get("guided_level", cycle.level))
            step = get_independent_activity_content(
                tag=cycle.tag,
                specific_instance=cycle.specific_instance,
                guided_level=guided_level,
                exclude_instance=cycle.meta.get("guided_content_instance"),
                table=self.table,
                word_list=self.word_list,
            )
            content = step["content_instance"]
            cycle.meta["independent_content_instance"] = content
            cycle.meta["independent_level"] = step["level"]
            return self._echo_payload(
                cycle, stage, content, step["level"], picture_ref=step["picture_ref"]
            )

        if stage == Stage.PROGRESS_CHECK:
            content = self._pick_guided_content(cycle)
            return self._echo_payload(cycle, stage, content, cycle.level)

        if stage == Stage.REINFORCEMENT:
            return {
                "template_id": "reinforcement",
                "interaction": "listen",
                "reinforcement": pick_reinforcement(),
                "auto_advance_ms": 1500,
            }

        return {"template_id": "noop", "interaction": "none"}
