"""
Progressive Reveal Engine — blend_required.

Play growing akshara stages; child repeats after each (capture only).
Independent Activity: same template, level = guided_level + 1 (word step-up).
"""

from __future__ import annotations

import random
from typing import Any, Dict, List, Optional

from ..intervention_cycle import Stage, CycleState, pick_reinforcement
from ..question_content import Grade1WordList, get_candidates, get_independent_activity_content
from ..reference_table import get_grade1_table
from ..sinhala_segmenter import segment_word


class ProgressiveRevealEngine:
    name = "ProgressiveRevealEngine"

    def __init__(self):
        self.table = get_grade1_table()
        self.word_list = Grade1WordList()

    def _fallback_word(self, cycle: CycleState) -> str:
        word = cycle.meta.get("word") or (
            cycle.specific_instance if isinstance(cycle.specific_instance, str) else ""
        )
        return word or "කා"

    def _pick_guided_content(self, cycle: CycleState) -> dict:
        cands = get_candidates(
            cycle.tag,
            cycle.level,
            self.table,
            self.word_list,
            cycle.specific_instance,
        )
        if not cands:
            w = self._fallback_word(cycle)
            return {
                "id": f"L{cycle.level}:word:{w}",
                "level": cycle.level,
                "display": w,
                "pair": None,
                "word": w,
                "picture_ref": None,
            }
        return random.choice(cands)

    def _units_for(self, word: str) -> List[str]:
        if not word:
            return ["ක", "කා"]
        parts = [u.text for u in segment_word(word)]
        return parts or [word]

    def _stages(self, units: List[str]) -> List[str]:
        out = []
        acc = ""
        for u in units:
            acc += u
            out.append(acc)
        return out

    def _progressive_payload(
        self,
        cycle: CycleState,
        stage: Stage,
        content: dict,
        level: int,
        picture_ref: Optional[str] = None,
    ) -> Dict[str, Any]:
        word = content.get("word") or content.get("display") or self._fallback_word(cycle)
        grow = self._stages(self._units_for(word))
        payload: Dict[str, Any] = {
            "template_id": "progressive_echo",
            "interaction": "record_only",
            "steps": [
                {
                    "text": g,
                    "audio_key": f"seq_{g}",
                    "prompt_en": "Now you say it.",
                }
                for g in grow
            ],
            "display_glyphs": grow,
            "scoring": "voice_activity_only",
            "no_hints": stage == Stage.PROGRESS_CHECK,
            "correct_signal": "attempted",
            "content_level": level,
            "content_instance_id": content.get("id"),
            "context_word": word,
        }
        if picture_ref:
            payload["picture_ref"] = picture_ref
        return payload

    def build_stage_content(self, cycle: CycleState, stage: Stage) -> Dict[str, Any]:
        if stage == Stage.TEACH:
            word = self._fallback_word(cycle)
            # Prefer a short blend word for teach when available
            teach_cands = get_candidates(
                cycle.tag, max(1, cycle.level), self.table, self.word_list, cycle.specific_instance
            )
            if teach_cands:
                word = teach_cands[0].get("word") or teach_cands[0].get("display") or word
            grow = self._stages(self._units_for(word))
            return {
                "template_id": "progressive_teach",
                "interaction": "listen",
                "play_sequence": [
                    {"text": g, "audio_key": f"seq_{g}"} for g in grow
                ],
                "display_glyphs": grow,
                "prompt_en": "Listen as the word grows.",
                "prompt_si_audio_key": "teach_blend_grow",
                "auto_advance_ms": 3500,
                "content_level": cycle.level,
            }

        if stage == Stage.GUIDED_PRACTICE:
            content = self._pick_guided_content(cycle)
            cycle.meta["guided_content_instance"] = content
            cycle.meta["guided_level"] = cycle.level
            cycle.meta["word"] = content.get("word") or content.get("display")
            return self._progressive_payload(cycle, stage, content, cycle.level)

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
            cycle.meta["word"] = content.get("word") or content.get("display")
            return self._progressive_payload(
                cycle, stage, content, step["level"], picture_ref=step["picture_ref"]
            )

        if stage == Stage.PROGRESS_CHECK:
            content = self._pick_guided_content(cycle)
            cycle.meta["word"] = content.get("word") or content.get("display")
            return self._progressive_payload(cycle, stage, content, cycle.level)

        if stage == Stage.REINFORCEMENT:
            return {
                "template_id": "reinforcement",
                "interaction": "listen",
                "reinforcement": pick_reinforcement(),
                "auto_advance_ms": 1500,
            }

        return {"template_id": "noop", "interaction": "none"}
