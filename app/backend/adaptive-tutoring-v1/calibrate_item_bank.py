"""Dry-run-first real-response calibration for Component 4 item difficulty."""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone

from pymongo import MongoClient

from services.rasch_calibration import fit_rasch


def _independent_responses(db) -> list[dict]:
    projection = {
        "student_id": 1,
        "event_id": 1,
        "item_id": 1,
        "is_correct": 1,
        "first_attempt_correct": 1,
        "scaffold_level_used": 1,
    }
    responses = []
    seen_event_ids = set()
    for event in db.telemetry_events.find({}, projection):
        event_id = event.get("event_id")
        if event_id and event_id in seen_event_ids:
            continue
        if event_id:
            seen_event_ids.add(event_id)
        first_attempt = event.get("first_attempt_correct")
        if isinstance(first_attempt, bool):
            correctness = first_attempt
        elif int(event.get("scaffold_level_used", 0) or 0) == 0:
            correctness = event.get("is_correct")
        else:
            continue
        responses.append({
            "student_id": event.get("student_id"),
            "item_id": event.get("item_id"),
            "is_correct": correctness,
        })
    return responses


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true",
                        help="Persist estimates. Default is a safe dry run.")
    parser.add_argument("--min-item-responses", type=int, default=30)
    args = parser.parse_args()

    mongo_url = os.getenv("MONGODB_URI") or os.getenv("MONGODB_URL")
    if not mongo_url:
        raise RuntimeError("Set MONGODB_URI before calibration.")
    client = MongoClient(mongo_url)
    db = client[os.getenv("MONGODB_DB", os.getenv("MONGODB_DB_NAME", "r26_se_031"))]
    try:
        result = fit_rasch(
            _independent_responses(db),
            min_item_responses=args.min_item_responses,
        )
        report = {
            "mode": "apply" if args.apply else "dry_run",
            "observations_used": result.observations_used,
            "eligible_items": len(result.item_difficulties),
            "log_loss": result.log_loss,
            "converged": result.converged,
            "epochs_run": result.epochs_run,
            "item_difficulties": result.item_difficulties,
            "item_sample_counts": result.item_sample_counts,
        }
        print(json.dumps(report, ensure_ascii=False, indent=2))

        if args.apply:
            calibrated_at = datetime.now(timezone.utc).isoformat()
            for item_id, estimate in result.item_difficulties.items():
                db.item_bank.update_one(
                    {"item_id": item_id},
                    {"$set": {
                        "difficulty_b": estimate,
                        "difficulty_source": "rasch_real_responses",
                        "calibration_status": "empirically_calibrated",
                        "calibration_sample_count":
                            result.item_sample_counts[item_id],
                        "calibrated_at": calibrated_at,
                        "calibration_model": "rasch_1pl_sgd_v1",
                    }},
                )
    finally:
        client.close()


if __name__ == "__main__":
    main()
