import math
from typing import List, Dict, Any, Optional

class ItemSelector:
    def select_next_item(
        self,
        current_item_id: str,
        current_activity: str,
        target_difficulty: float,
        candidates: List[Dict[str, Any]],
        confirmation_required: bool = False,
        forced_item_id: Optional[str] = None,
        excluded_item_ids: Optional[List[str]] = None,
        knowledge_component_id: Optional[str] = None,
        equivalent_group_id: Optional[str] = None,
        exposure_counts: Optional[Dict[str, int]] = None,
    ) -> Dict[str, Any]:
        """
        Adaptive item selection using provisional IRT difficulty parameters,
        difficulty buckets, and confirmation preference.
        """
        if forced_item_id:
            forced = next(
                (candidate for candidate in candidates
                 if candidate.get("item_id") == forced_item_id),
                None,
            )
            selected_difficulty = (
                forced.get("difficulty_b", target_difficulty)
                if forced is not None else target_difficulty
            )
            return {
                "selected_item": forced_item_id,
                "selected_difficulty": selected_difficulty,
                "target_difficulty": target_difficulty,
                "selection_reason": "AUTHORED_EQUIVALENT_FLOW_OVERRIDE",
                "selection_strategy": "bounded_authored_state_machine",
                "candidate_count": 1 if forced is not None else 0,
                "constraints": {
                    "activity_id": current_activity,
                    "knowledge_component_id": knowledge_component_id,
                    "equivalent_group_id": equivalent_group_id,
                    "unseen_required": True,
                },
            }
            
        if not candidates:
            return {
                "selected_item": current_item_id if current_item_id else "act_1_round1", # Safe fallback
                "selected_difficulty": 0.0,
                "target_difficulty": target_difficulty,
                "selection_reason": "NO_CANDIDATE_FALLBACK"
            }
            
        # 1. Filter valid candidates. Ordinary IRT selection must not cycle
        # through items already completed in this activity. Explicit state-
        # machine overrides may still repeat an item for confirmation.
        valid_candidates = [
            c for c in candidates
            if c.get("activity_id") == current_activity
            and c.get("is_active", True) is not False
            and (
                not knowledge_component_id
                or c.get("knowledge_component_id") == knowledge_component_id
            )
        ]
        excluded = set(excluded_item_ids or [])
        unseen_candidates = [
            candidate for candidate in valid_candidates
            if candidate.get("item_id") not in excluded
        ]
        if unseen_candidates:
            valid_candidates = unseen_candidates
        elif valid_candidates and excluded:
            return {
                "selected_item": "COMPLETE",
                "selected_difficulty": 0.0,
                "target_difficulty": target_difficulty,
                "selection_reason": "ALL_ACTIVE_ITEMS_ADMINISTERED",
            }
        
        if not valid_candidates:
            return {
                "selected_item": current_item_id if current_item_id else "act_1_round1",
                "selected_difficulty": 0.0,
                "target_difficulty": target_difficulty,
                "selection_reason": "NO_CANDIDATE_FALLBACK_FOR_ACTIVITY"
            }

        def get_bucket(diff: float) -> str:
            if diff <= -1.0: return "VERY_EASY"
            elif diff <= -0.25: return "EASY"
            elif diff <= 0.25: return "MEDIUM"
            elif diff <= 1.0: return "HARD"
            return "VERY_HARD"

        # If confirmation is required, prioritize items with role='CONFIRMATION' in the same bucket
        if confirmation_required:
            target_bucket = get_bucket(target_difficulty)
            conf_candidates = [
                c for c in valid_candidates
                if c.get("item_role") == "CONFIRMATION"
                and get_bucket(c.get("difficulty_b", 0.0)) == target_bucket
                and (
                    not equivalent_group_id
                    or c.get("equivalent_group_id") == equivalent_group_id
                )
            ]
            
            if conf_candidates:
                # Exclude current item if alternatives exist
                if len(conf_candidates) > 1:
                    conf_candidates = [c for c in conf_candidates if c.get("item_id") != current_item_id]
                best = sorted(conf_candidates, key=lambda c: abs(c.get("difficulty_b", 0.0) - target_difficulty))[0]
                return {
                    "selected_item": best.get("item_id"),
                    "selected_difficulty": best.get("difficulty_b", 0.0),
                    "target_difficulty": target_difficulty,
                    "selection_reason": "CONSTRAINED_CONFIRMATION_ITEM_SELECTED",
                    "selection_strategy": "same_kc_same_bucket_unseen",
                    "candidate_count": len(conf_candidates),
                }

        # Normal selection
        if len(valid_candidates) > 1:
            # Filter out current item, and if normal progression, prefer is_core=True
            filtered_candidates = [c for c in valid_candidates if c.get("item_id") != current_item_id]
            core_only = [c for c in filtered_candidates if c.get("is_core", True)]
            if core_only:
                filtered_candidates = core_only
            if filtered_candidates:
                valid_candidates = filtered_candidates
            
        exposure_counts = exposure_counts or {}

        def candidate_evidence(c: Dict[str, Any]) -> Dict[str, Any]:
            difficulty = float(c.get("difficulty_b", 0.0) or 0.0)
            distance = abs(difficulty - target_difficulty)
            # At the target ability, a Rasch item is most informative near
            # p=.5. This metric is reported for auditability; authored round
            # order remains the final tie-breaker for curriculum coherence.
            probability = 1.0 / (1.0 + math.exp(
                -max(-30.0, min(30.0, target_difficulty - difficulty))
            ))
            information = probability * (1.0 - probability)
            exposure = int(exposure_counts.get(str(c.get("item_id")), 0) or 0)
            return {
                "item_id": c.get("item_id"),
                "difficulty_distance": round(distance, 6),
                "rasch_information": round(information, 6),
                "prior_exposure_count": exposure,
                "round": int(c.get("round", 0) or 0),
            }

        scored = [(candidate_evidence(candidate), candidate) for candidate in valid_candidates]

        def sort_key(pair):
            evidence, _ = pair
            return (
                evidence["difficulty_distance"],
                evidence["prior_exposure_count"],
                -evidence["rasch_information"],
                evidence["round"],
                str(evidence["item_id"]),
            )
            
        sorted_candidates = sorted(scored, key=sort_key)
        best_evidence, best_candidate = sorted_candidates[0]
        
        reason = "IRT_DIFFICULTY_MATCH"
        if best_candidate.get("item_id") == current_item_id:
            reason = "BEST_MATCH_BUT_REPEATED_DUE_TO_NO_ALTERNATIVES"
        elif confirmation_required:
            reason = "CONFIRMATION_REQUIRED_BUT_NO_CONFIRMATION_ITEMS_FOUND_FALLBACK"
            
        return {
            "selected_item": best_candidate.get("item_id"),
            "selected_difficulty": best_candidate.get("difficulty_b", 0.0),
            "target_difficulty": target_difficulty,
            "selection_reason": reason,
            "selection_strategy": "constrained_irt_information_exposure_ranking",
            "candidate_count": len(sorted_candidates),
            "selected_candidate_evidence": best_evidence,
            "top_candidate_scores": [
                evidence for evidence, _ in sorted_candidates[:5]
            ],
        }

item_selector = ItemSelector()
