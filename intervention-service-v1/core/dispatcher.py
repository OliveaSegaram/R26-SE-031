"""
Tag → engine dispatcher for C4.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

from .engines import DiscriminationEngine, EchoEngine, ProgressiveRevealEngine
from .reference_table import TAG_PRIORITY, pick_primary_tag

TAG_TO_ENGINE = {
    "visual_confusion": "DiscriminationEngine",
    "pillam_subtle": "DiscriminationEngine",
    "hal_kirima": "EchoEngine",
    "blend_required": "ProgressiveRevealEngine",
}


class Dispatcher:
    def __init__(self):
        self.discrimination = DiscriminationEngine()
        self.echo = EchoEngine()
        self.progressive = ProgressiveRevealEngine()

    def engine_for_tag(self, tag: str):
        name = TAG_TO_ENGINE.get(tag, "DiscriminationEngine")
        if name == "EchoEngine":
            return self.echo
        if name == "ProgressiveRevealEngine":
            return self.progressive
        return self.discrimination

    def resolve_tag(self, tags, boosted_tags=None) -> Optional[str]:
        pool = list(tags or [])
        if boosted_tags:
            # Prefer boosted tags when present on the akshara
            for t in TAG_PRIORITY:
                if t in boosted_tags and t in pool:
                    return t
            for t in TAG_PRIORITY:
                if t in boosted_tags:
                    return t
        return pick_primary_tag(pool)

    def route(
        self,
        tag: str,
        child_id: str,
        specific_instance: Any,
        level: int,
        cycle_mode: str,
    ) -> Dict[str, Any]:
        engine = self.engine_for_tag(tag)
        return {
            "tag": tag,
            "engine": engine.name,
            "specific_instance": specific_instance,
            "level": level,
            "cycle_mode": cycle_mode,
            "child_id": child_id,
            "engine_obj": engine,
        }
