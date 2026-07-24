"""
Shared 5-stage intervention cycle for Grade-1 mobile activities.

ENTRY -> TEACH -> GUIDED_PRACTICE -> INDEPENDENT_ACTIVITY -> REINFORCEMENT
      -> PROGRESS_CHECK -> EXIT

Short (fatigue) mode: TEACH -> PROGRESS_CHECK only.
Child responds via buttons/choices — never open speech scoring.
"""

from __future__ import annotations

import random
import time
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional


HINTS = [
    {"id": "hint_listen_again", "en": "Let's listen one more time.", "si_audio_key": "hint_listen_again"},
    {"id": "hint_ending", "en": "Listen carefully to the ending.", "si_audio_key": "hint_ending"},
    {"id": "hint_difference", "en": "Can you hear the difference?", "si_audio_key": "hint_difference"},
    {"id": "hint_slow", "en": "Let's slow it down.", "si_audio_key": "hint_slow"},
    {"id": "hint_try_again", "en": "Great effort! Try once more.", "si_audio_key": "hint_try_again"},
]

REINFORCEMENT = [
    {"id": "re_great", "en": "Great listening!", "si_audio_key": "re_great"},
    {"id": "re_wonderful", "en": "Wonderful! You're getting it!", "si_audio_key": "re_wonderful"},
    {"id": "re_nice", "en": "Nice work, let's keep going!", "si_audio_key": "re_nice"},
]


class Stage(str, Enum):
    ENTRY = "ENTRY"
    TEACH = "TEACH"
    GUIDED_PRACTICE = "GUIDED_PRACTICE"
    INDEPENDENT_ACTIVITY = "INDEPENDENT_ACTIVITY"
    REINFORCEMENT = "REINFORCEMENT"
    PROGRESS_CHECK = "PROGRESS_CHECK"
    EXIT = "EXIT"


@dataclass
class CycleState:
    cycle_id: str
    child_id: str
    tag: str
    specific_instance: Any
    level: int
    cycle_mode: str  # full | short
    engine_name: str
    stage: Stage = Stage.ENTRY
    guided_attempts: int = 0
    guided_result: Optional[str] = None
    template_used_guided: Optional[str] = None
    template_used_progress_check: Optional[str] = None
    progress_check_result: Optional[str] = None
    last_hint_id: Optional[str] = None
    last_template_id: Optional[str] = None
    started_ms: int = field(default_factory=lambda: int(time.time() * 1000))
    meta: Dict[str, Any] = field(default_factory=dict)
    localization_zone: Optional[str] = None
    localization_confidence: Optional[float] = None
    error_pattern_flags: List[str] = field(default_factory=list)
    mastery_before: float = 0.3


MAX_GUIDED_ATTEMPTS = 3


def pick_hint(last_id: Optional[str] = None) -> dict:
    choices = [h for h in HINTS if h["id"] != last_id] or HINTS
    return random.choice(choices)


def pick_reinforcement() -> dict:
    return random.choice(REINFORCEMENT)


class InterventionCycle:
    """State machine. Engines supply content via build_stage_content()."""

    def __init__(self, content_builder):
        """
        content_builder(cycle: CycleState, stage: Stage) -> dict
        Must return Flutter-ready payload for that stage.
        """
        self.content_builder = content_builder
        self._cycles: Dict[str, CycleState] = {}

    def start(self, cycle: CycleState) -> Dict[str, Any]:
        cycle.stage = Stage.TEACH
        self._cycles[cycle.cycle_id] = cycle
        return self._stage_payload(cycle)

    def get(self, cycle_id: str) -> Optional[CycleState]:
        return self._cycles.get(cycle_id)

    def respond(self, cycle_id: str, stage: str, response: Dict[str, Any]) -> Dict[str, Any]:
        cycle = self._cycles.get(cycle_id)
        if not cycle:
            return {"error": "unknown_cycle", "exit": True}

        current = Stage(stage) if stage else cycle.stage
        if current != cycle.stage:
            # tolerate client sending current stage name
            current = cycle.stage

        if cycle.stage == Stage.TEACH:
            return self._advance_after_teach(cycle)

        if cycle.stage == Stage.GUIDED_PRACTICE:
            return self._handle_guided(cycle, response)

        if cycle.stage == Stage.INDEPENDENT_ACTIVITY:
            cycle.stage = Stage.REINFORCEMENT
            return self._stage_payload(cycle)

        if cycle.stage == Stage.REINFORCEMENT:
            cycle.stage = Stage.PROGRESS_CHECK
            return self._stage_payload(cycle)

        if cycle.stage == Stage.PROGRESS_CHECK:
            return self._handle_progress(cycle, response)

        return {"stage": Stage.EXIT.value, "exit": True, "cycle_id": cycle.cycle_id}

    def _advance_after_teach(self, cycle: CycleState) -> Dict[str, Any]:
        if cycle.cycle_mode == "short":
            cycle.stage = Stage.PROGRESS_CHECK
        else:
            cycle.stage = Stage.GUIDED_PRACTICE
        return self._stage_payload(cycle)

    def _handle_guided(self, cycle: CycleState, response: Dict[str, Any]) -> Dict[str, Any]:
        correct = bool(response.get("correct", response.get("is_correct", False)))
        cycle.guided_attempts += 1

        if correct:
            cycle.guided_result = f"correct_on_attempt_{cycle.guided_attempts}"
            cycle.stage = Stage.INDEPENDENT_ACTIVITY
            return self._stage_payload(cycle)

        if cycle.guided_attempts >= MAX_GUIDED_ATTEMPTS:
            cycle.guided_result = "max_attempts_reached"
            cycle.stage = Stage.INDEPENDENT_ACTIVITY
            return self._stage_payload(cycle)

        hint = pick_hint(cycle.last_hint_id)
        cycle.last_hint_id = hint["id"]
        payload = self._stage_payload(cycle)
        payload["hint"] = hint
        payload["retry"] = True
        payload["child_prompt_en"] = hint["en"]
        return payload

    def _handle_progress(self, cycle: CycleState, response: Dict[str, Any]) -> Dict[str, Any]:
        # Echo / progressive reveal: attempted (voice activity) counts as pass signal
        if "attempted" in response and "correct" not in response and "is_correct" not in response:
            passed = bool(response.get("attempted"))
        else:
            passed = bool(response.get("correct", response.get("is_correct", False)))

        cycle.progress_check_result = "pass" if passed else "fail"

        if not passed and cycle.cycle_mode != "short":
            # Loop back to guided with new example — do NOT replay TEACH
            cycle.guided_attempts = 0
            cycle.guided_result = None
            cycle.stage = Stage.GUIDED_PRACTICE
            cycle.meta["progress_fail_loop"] = cycle.meta.get("progress_fail_loop", 0) + 1
            # Avoid infinite loops: after 2 fail-loops, exit as fail
            if cycle.meta["progress_fail_loop"] > 2:
                return self._exit_payload(cycle)
            return self._stage_payload(cycle)

        return self._exit_payload(cycle)

    def _stage_payload(self, cycle: CycleState) -> Dict[str, Any]:
        content = self.content_builder(cycle, cycle.stage)
        if cycle.stage == Stage.GUIDED_PRACTICE:
            cycle.template_used_guided = content.get("template_id") or cycle.template_used_guided
        if cycle.stage == Stage.PROGRESS_CHECK:
            cycle.template_used_progress_check = content.get("template_id") or cycle.template_used_progress_check
        if cycle.stage == Stage.REINFORCEMENT and "reinforcement" not in content:
            content["reinforcement"] = pick_reinforcement()

        return {
            "cycle_id": cycle.cycle_id,
            "child_id": cycle.child_id,
            "tag": cycle.tag,
            "specific_instance": cycle.specific_instance,
            "level": cycle.level,
            "cycle_mode": cycle.cycle_mode,
            "engine": cycle.engine_name,
            "stage": cycle.stage.value,
            "exit": False,
            "ui": {
                # Grade-1 mobile: large buttons, audio-first, minimal text
                "interaction": content.get("interaction", "listen"),
                "large_buttons": True,
                "show_text_labels": content.get("show_text_labels", True),
                "auto_play_audio": True,
            },
            "content": content,
        }

    def _exit_payload(self, cycle: CycleState) -> Dict[str, Any]:
        cycle.stage = Stage.EXIT
        duration = (int(time.time() * 1000) - cycle.started_ms) / 1000.0
        return {
            "cycle_id": cycle.cycle_id,
            "child_id": cycle.child_id,
            "tag": cycle.tag,
            "specific_instance": cycle.specific_instance,
            "level": cycle.level,
            "cycle_mode": cycle.cycle_mode,
            "engine": cycle.engine_name,
            "stage": Stage.EXIT.value,
            "exit": True,
            "summary": {
                "guided_attempts": cycle.guided_attempts,
                "guided_result": cycle.guided_result,
                "template_used_guided": cycle.template_used_guided,
                "template_used_progress_check": cycle.template_used_progress_check,
                "progress_check_result": cycle.progress_check_result,
                "localization_zone": cycle.localization_zone,
                "localization_confidence": cycle.localization_confidence,
                "error_pattern_flags": cycle.error_pattern_flags,
                "mastery_before": cycle.mastery_before,
                "duration_seconds": round(duration, 1),
            },
        }


def new_cycle_id() -> str:
    return str(uuid.uuid4())
