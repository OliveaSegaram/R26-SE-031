"""Read-only Component 4 research database audit."""

from __future__ import annotations

import json
import os

from pymongo import MongoClient


def main() -> None:
    uri = os.getenv("MONGODB_URI") or os.getenv("MONGODB_URL")
    if not uri:
        raise RuntimeError("Set MONGODB_URI or MONGODB_URL.")
    db_name = os.getenv("MONGODB_DB", os.getenv("MONGODB_DB_NAME", "r26_se_031"))
    client = MongoClient(uri, serverSelectionTimeoutMS=10000)
    db = client[db_name]
    try:
        origins = list(db.telemetry_events.aggregate([
            {"$group": {"_id": {"$ifNull": ["$data_origin", "missing"]}, "count": {"$sum": 1}}},
            {"$sort": {"_id": 1}},
        ]))
        report = {
            "database": db_name,
            "active_skill_1_4_items": db.item_bank.count_documents({
                "skill_id": {"$in": ["skill_1", "skill_2", "skill_3", "skill_4"]},
                "is_active": {"$ne": False},
            }),
            "telemetry_events": db.telemetry_events.count_documents({}),
            "telemetry_origins": {row["_id"]: row["count"] for row in origins},
            "events_missing_dataset_id": db.telemetry_events.count_documents({
                "$or": [{"dataset_id": {"$exists": False}}, {"dataset_id": None}],
            }),
            "approved_calibration_completions": db.telemetry_events.count_documents({
                "data_origin": "observed",
                "calibration_eligible": True,
                "validation_status": {"$in": ["pilot_approved", "validated_observed"]},
                "phase": "COMPLETE",
                "research_eligible": True,
            }),
            "invalid_nonobserved_calibration_rows": db.telemetry_events.count_documents({
                "calibration_eligible": True,
                "data_origin": {"$ne": "observed"},
            }),
            "adaptive_decisions": db.adaptive_decisions.count_documents({}),
            "policy_decisions": db.policy_decisions.count_documents({}),
            "policy_decisions_with_proximal_outcomes": db.policy_decisions.count_documents({
                "proximal_outcome_observed": True,
            }),
            "policy_decisions_with_linked_outcomes": db.policy_decisions.count_documents({
                "outcome_observed": True,
            }),
            "observed_kinematic_sessions": db.kinematic_features.count_documents({
                "data_origin": "observed",
                "measurement_status": "available",
            }),
            "active_unapproved_bkt_models": db.model_registry.count_documents({
                "model_type": "BKT",
                "status": "active",
                "$or": [
                    {"data_origin": {"$ne": "observed"}},
                    {"validation_status": {"$nin": ["pilot_approved", "validated_observed"]}},
                ],
            }),
        }
        report["blocking_integrity_errors"] = (
            report["invalid_nonobserved_calibration_rows"]
        )
        print(json.dumps(report, indent=2, ensure_ascii=False))
    finally:
        client.close()


if __name__ == "__main__":
    main()
