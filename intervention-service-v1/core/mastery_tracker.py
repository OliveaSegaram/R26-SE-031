"""
C4 fine-grained mastery tracker — real BKT + SM-2 review scheduling.

This is Component 4's own BKT over (child_id, tag, specific_instance).
It is intentionally separate from Component 3's BKT (different skills,
different parameters). Do not unify the two systems.

`mastery` on stored records is P(knows) from BKT (p_know).
SM-2 interval / EF logic is unchanged and independent of the BKT math.
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Sequence, Union

from shared.database import get_db

from .reference_table import instance_key
from .sm2_scheduler import MIN_EF, INITIAL_EF

# ── C4 BKT parameters (planning values; distinct from C3) ─────────────────
P_INIT = 0.10   # P(L0) — prior that the child already knows this instance
P_LEARN = 0.20  # P(T)  — learn transition after one practice observation
P_SLIP = 0.10   # P(S)  — incorrect despite knowing (careless slip)
P_GUESS = 0.15  # P(G)  — correct despite not knowing (lucky guess)

# Backward-compatible alias: new records initialize at P_INIT
DEFAULT_MASTERY = P_INIT

# Migration note:
# Existing Mongo `c4_tag_mastery.mastery` values from the old flat
# +0.15/−0.05 scale are treated as approximate p_know seeds (same 0–1
# range). We do NOT bulk-reset to P_INIT so early demo data is not wiped.
# Brand-new (child, tag, instance) rows still start at P_INIT.


def bkt_update(p_know_prior: float, correct: bool) -> float:
    """
    Standard BKT posterior update.

    p_know_prior: current P(knows this tag/instance) before this observation
    correct: whether the observed response was correct
    Returns: updated P(knows) after evidence + learning transition, in [0, 1]
    """
    p = min(1.0, max(0.0, float(p_know_prior)))
    if correct:
        numerator = p * (1 - P_SLIP)
        denominator = (p * (1 - P_SLIP)) + ((1 - p) * P_GUESS)
    else:
        numerator = p * P_SLIP
        denominator = (p * P_SLIP) + ((1 - p) * (1 - P_GUESS))

    posterior = numerator / denominator if denominator > 0 else p

    # Learning transition: may learn even if they did not know yet
    p_know_after = posterior + (1 - posterior) * P_LEARN
    return min(1.0, max(0.0, p_know_after))


def update_mastery(current_mastery: float, progress_check_passed: bool) -> float:
    """Update p_know from a Progress Check (or any correct/incorrect observation)."""
    return bkt_update(current_mastery, bool(progress_check_passed))


def get_level(mastery: float) -> int:
    """Map p_know → content level. Same bands as before; revisit if trajectories feel off."""
    if mastery < 0.35:
        return 1
    if mastery < 0.6:
        return 2
    if mastery < 0.85:
        return 3
    return 4


def _quality_from_pass(passed: bool) -> int:
    return 4 if passed else 1


class InstanceMasteryState:
    def __init__(
        self,
        child_id: str,
        tag: str,
        specific_instance: Union[str, List[str]],
        mastery: float = DEFAULT_MASTERY,
        interval: int = 1,
        repetitions: int = 0,
        easiness_factor: float = INITIAL_EF,
        next_review_date: Optional[str] = None,
    ):
        self.child_id = child_id
        self.tag = tag
        self.specific_instance = specific_instance
        self.instance_id = instance_key(specific_instance)
        # `mastery` stores BKT p_know
        self.mastery = mastery
        self.interval = interval
        self.repetitions = repetitions
        self.easiness_factor = easiness_factor
        self.next_review_date = next_review_date or date.today().isoformat()

    @property
    def p_know(self) -> float:
        return self.mastery

    @property
    def level(self) -> int:
        return get_level(self.mastery)

    def apply_progress_check(self, passed: bool) -> Dict[str, Any]:
        before = self.mastery
        self.mastery = bkt_update(self.mastery, passed)
        # SM-2 scheduling — unchanged, independent of BKT math
        quality = _quality_from_pass(passed)
        if quality >= 3:
            if self.repetitions == 0:
                self.interval = 1
            elif self.repetitions == 1:
                self.interval = 6
            else:
                self.interval = max(1, round(self.interval * self.easiness_factor))
            self.repetitions += 1
        else:
            self.repetitions = 0
            self.interval = 1
        ef_delta = 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
        self.easiness_factor = max(MIN_EF, self.easiness_factor + ef_delta)
        self.next_review_date = (date.today() + timedelta(days=self.interval)).isoformat()
        return {
            "mastery_before": round(before, 4),
            "mastery_after": round(self.mastery, 4),
            "p_know_before": round(before, 4),
            "p_know_after": round(self.mastery, 4),
            "level_after": self.level,
            "next_review_due": self.next_review_date,
        }


class MasteryTracker:
    """Per-(child, tag, instance) BKT + SM-2 store for C4."""

    def __init__(self):
        self._cache: Dict[str, InstanceMasteryState] = {}

    def _cache_key(self, child_id: str, tag: str, specific_instance) -> str:
        return f"{child_id}::{tag}::{instance_key(specific_instance)}"

    async def get(
        self,
        child_id: str,
        tag: str,
        specific_instance: Union[str, Sequence[str]],
    ) -> InstanceMasteryState:
        key = self._cache_key(child_id, tag, specific_instance)
        if key not in self._cache:
            self._cache[key] = await self._load(child_id, tag, specific_instance)
        return self._cache[key]

    async def update_after_cycle(
        self,
        child_id: str,
        tag: str,
        specific_instance: Union[str, Sequence[str]],
        progress_check_passed: bool,
    ) -> Dict[str, Any]:
        state = await self.get(child_id, tag, specific_instance)
        summary = state.apply_progress_check(progress_check_passed)
        await self._save(state)
        return summary

    async def get_map(self, child_id: str) -> List[Dict[str, Any]]:
        db = get_db()
        cursor = db.c4_tag_mastery.find({"child_id": child_id})
        rows = []
        if hasattr(cursor, "to_list"):
            docs = await cursor.to_list(length=500)
        else:
            docs = []
            coll = getattr(db, "c4_tag_mastery", None)
            if coll is not None and hasattr(coll, "data"):
                docs = [d for d in coll.data.values() if d.get("child_id") == child_id]
        for row in docs:
            mastery = float(row.get("mastery", DEFAULT_MASTERY))
            rows.append({
                "child_id": child_id,
                "tag": row.get("tag"),
                "specific_instance": row.get("specific_instance"),
                "mastery": round(mastery, 4),
                "p_know": round(mastery, 4),
                "level": get_level(mastery),
                "next_review_due": row.get("next_review_date"),
            })
        return rows

    async def get_macro_stage(self, child_id: str, c3_base_url: str) -> Optional[dict]:
        """Optional secondary read from C3 — logging/context only, never task selection."""
        try:
            import httpx
            async with httpx.AsyncClient(timeout=3.0) as client:
                resp = await client.get(f"{c3_base_url}/api/v1/mastery/{child_id}")
                if resp.status_code == 200:
                    return resp.json()
        except Exception:
            return None
        return None

    async def _load(self, child_id: str, tag: str, specific_instance) -> InstanceMasteryState:
        db = get_db()
        iid = instance_key(specific_instance)
        row = await db.c4_tag_mastery.find_one({
            "child_id": child_id,
            "tag": tag,
            "instance_id": iid,
        })
        if row:
            # Seed from existing flat-scale value as approximate p_know
            return InstanceMasteryState(
                child_id=child_id,
                tag=tag,
                specific_instance=row.get("specific_instance", specific_instance),
                mastery=float(row.get("mastery", DEFAULT_MASTERY)),
                interval=int(row.get("interval", 1)),
                repetitions=int(row.get("repetitions", 0)),
                easiness_factor=float(row.get("easiness_factor", INITIAL_EF)),
                next_review_date=row.get("next_review_date"),
            )
        return InstanceMasteryState(
            child_id,
            tag,
            list(specific_instance) if isinstance(specific_instance, (list, tuple)) else specific_instance,
            mastery=P_INIT,
        )

    async def _save(self, state: InstanceMasteryState) -> None:
        db = get_db()
        await db.c4_tag_mastery.update_one(
            {
                "child_id": state.child_id,
                "tag": state.tag,
                "instance_id": state.instance_id,
            },
            {"$set": {
                "specific_instance": state.specific_instance,
                "mastery": state.mastery,  # BKT p_know
                "level": state.level,
                "interval": state.interval,
                "repetitions": state.repetitions,
                "easiness_factor": state.easiness_factor,
                "next_review_date": state.next_review_date,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }},
            upsert=True,
        )
        self._cache[self._cache_key(state.child_id, state.tag, state.specific_instance)] = state
