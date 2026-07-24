"""
C4 end-to-end pipeline: trigger → segment → localize → tag → mastery → fatigue → dispatch → cycle.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Sequence, Union

import numpy as np

from shared.database import get_db

from .dispatcher import Dispatcher
from .intervention_cycle import CycleState, InterventionCycle, Stage, new_cycle_id
from .localization import localize_struggle
from .mastery_tracker import MasteryTracker
from .reference_table import (
    get_grade1_table,
    lookup_akshara,
    resolve_specific_instance,
    validate_content,
)
from .sinhala_segmenter import analyze_word

FATIGUE_THRESHOLD = 0.70
PSI_TRIGGER = 0.45


class InterventionPipeline:
    def __init__(self):
        self.table = get_grade1_table()
        self.dispatcher = Dispatcher()
        self.mastery = MasteryTracker()
        self._active_engine = None
        self.cycle_runner = InterventionCycle(self._build_content)

    def _build_content(self, cycle: CycleState, stage: Stage) -> Dict[str, Any]:
        engine = self.dispatcher.engine_for_tag(cycle.tag)
        return engine.build_stage_content(cycle, stage)

    async def trigger(
        self,
        child_id: str,
        word: str,
        *,
        phonological_strain_index: float = 0.0,
        session_fatigue_index: float = 0.0,
        error_pattern_vector: Union[Sequence[int], dict, None] = None,
        audio_samples: Optional[np.ndarray] = None,
        sample_rate: int = 16000,
        zone_hint: Optional[str] = None,
        audio_clip_ref: Optional[str] = None,
        reading_position: Optional[dict] = None,
    ) -> Dict[str, Any]:
        """
        Pipeline A–D (+ E/F prep): struggle trigger through tag resolution.
        Stage 1 conceptually fires when PSI >= 0.45.
        """
        if phonological_strain_index < PSI_TRIGGER and zone_hint is None and audio_samples is None:
            return {
                "triggered": False,
                "reason": "below_strain_threshold",
                "phonological_strain_index": phonological_strain_index,
            }

        units = analyze_word(word, self.table)
        if not units:
            return {"triggered": False, "reason": "empty_segmentation", "word": word}

        # Prefer in-scope content; still allow localization on the word
        loc = localize_struggle(
            units,
            audio_samples=audio_samples,
            sample_rate=sample_rate,
            zone_hint=zone_hint or (reading_position or {}).get("zone"),
            error_pattern_vector=error_pattern_vector,
        )
        idx = min(max(loc.akshara_index, 0), len(units) - 1)
        target = units[idx]
        lookup_akshara(target, self.table)

        tag = self.dispatcher.resolve_tag(target.tags, loc.tags_boosted)
        if not tag:
            # Default to blend if tagged empty but has pillam, else visual if confusable
            tag = "blend_required" if target.vowel_form not in ("a", "hal_kirima", "independent_vowel") else "hal_kirima"

        specific = resolve_specific_instance(tag, target, self.table)
        state = await self.mastery.get(child_id, tag, specific)
        cycle_mode = "short" if session_fatigue_index > FATIGUE_THRESHOLD else "full"

        # Scope note for Flutter — never invent out-of-scope drill glyphs later
        in_scope = validate_content([target], self.table, allow_unknown=True)

        route = self.dispatcher.route(tag, child_id, specific, state.level, cycle_mode)

        flags: List[str] = []
        if isinstance(error_pattern_vector, (list, tuple)) and len(error_pattern_vector) >= 4:
            names = ["reversal", "omission", "substitution", "hesitation"]
            flags = [names[i] for i, v in enumerate(error_pattern_vector[:4]) if int(v)]

        return {
            "triggered": True,
            "child_id": child_id,
            "word": word,
            "aksharas": [
                {
                    "text": u.text,
                    "base_consonant": u.base_consonant,
                    "vowel_form": u.vowel_form,
                    "tags": u.tags,
                    "in_grade1_scope": u.in_grade1_scope,
                    "position": u.position,
                }
                for u in units
            ],
            "localization_zone": loc.zone,
            "localization_confidence": loc.confidence,
            "target_akshara": target.text,
            "tag": tag,
            "engine": route["engine"],
            "specific_instance": specific,
            "level": state.level,
            "mastery": state.mastery,
            "cycle_mode": cycle_mode,
            "in_grade1_scope": in_scope,
            "error_pattern_flags": flags,
            "audio_clip_ref": audio_clip_ref,
        }

    async def start_cycle(
        self,
        child_id: str,
        tag: str,
        specific_instance: Any,
        *,
        word: Optional[str] = None,
        cycle_mode: Optional[str] = None,
        session_fatigue_index: float = 0.0,
        localization_zone: Optional[str] = None,
        localization_confidence: Optional[float] = None,
        error_pattern_flags: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        state = await self.mastery.get(child_id, tag, specific_instance)
        mode = cycle_mode or ("short" if session_fatigue_index > FATIGUE_THRESHOLD else "full")
        engine = self.dispatcher.engine_for_tag(tag)

        cycle = CycleState(
            cycle_id=new_cycle_id(),
            child_id=child_id,
            tag=tag,
            specific_instance=specific_instance,
            level=state.level,
            cycle_mode=mode,
            engine_name=engine.name,
            localization_zone=localization_zone,
            localization_confidence=localization_confidence,
            error_pattern_flags=error_pattern_flags or [],
            mastery_before=state.mastery,
            meta={"word": word},
        )
        return self.cycle_runner.start(cycle)

    async def respond_cycle(
        self,
        cycle_id: str,
        stage: str,
        response: Dict[str, Any],
    ) -> Dict[str, Any]:
        result = self.cycle_runner.respond(cycle_id, stage, response)
        if not result.get("exit"):
            return result

        cycle = self.cycle_runner.get(cycle_id)
        if not cycle:
            return result

        passed = cycle.progress_check_result == "pass"
        mastery_summary = await self.mastery.update_after_cycle(
            cycle.child_id, cycle.tag, cycle.specific_instance, passed
        )

        log = {
            "child_id": cycle.child_id,
            "tag": cycle.tag,
            "specific_instance": cycle.specific_instance,
            "level": cycle.level,
            "cycle_mode": cycle.cycle_mode,
            "localization_zone": cycle.localization_zone,
            "localization_confidence": cycle.localization_confidence,
            "error_pattern_flags": cycle.error_pattern_flags,
            "template_used_guided": cycle.template_used_guided,
            "guided_attempts": cycle.guided_attempts,
            "guided_result": cycle.guided_result,
            "template_used_progress_check": cycle.template_used_progress_check,
            "progress_check_result": cycle.progress_check_result,
            "mastery_before": mastery_summary["mastery_before"],
            "mastery_after": mastery_summary["mastery_after"],
            "level_after": mastery_summary["level_after"],
            "next_review_due": mastery_summary["next_review_due"],
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "duration_seconds": result.get("summary", {}).get("duration_seconds"),
        }
        await self._write_log(log)
        result["mastery_update"] = mastery_summary
        result["log"] = log
        return result

    async def _write_log(self, log: dict) -> None:
        try:
            db = get_db()
            await db.c4_intervention_logs.insert_one(dict(log))
        except Exception:
            pass
