"""Idempotently seed the research item bank from the app curriculum."""

from item_bank_builder import build_items, validation_summary


def seed(db) -> dict:
    items = build_items()
    for item in items:
        db.item_bank.update_one(
            {"item_id": item["item_id"]},
            {"$set": item},
            upsert=True,
        )
    return validation_summary(items)


if __name__ == "__main__":
    import argparse
    import os
    from pymongo import MongoClient

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="write validated item records to MongoDB (default: validate only)",
    )
    args = parser.parse_args()

    items = build_items()
    summary = validation_summary(items)
    if not args.apply:
        print({**summary, "mode": "validation_only"})
    else:
        mongo_url = os.getenv("MONGODB_URI") or os.getenv("MONGODB_URL")
        if not mongo_url:
            raise RuntimeError("Set MONGODB_URI before using --apply")
        database = MongoClient(mongo_url)[
            os.getenv("MONGODB_DB", os.getenv("MONGODB_DB_NAME", "r26_se_031"))
        ]
        print({**seed(database), "mode": "applied"})
