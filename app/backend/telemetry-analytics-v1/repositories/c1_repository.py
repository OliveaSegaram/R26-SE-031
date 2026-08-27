from database import get_db

async def save_c1_state(state_data: dict) -> None:
    """Upsert the processed C1 result for a specific session."""
    db = get_db()
    
    # We upsert based on session_id to ensure idempotency.
    await db.c1_learner_states.update_one(
        {"session_id": state_data.get("session_id")},
        {"$set": state_data},
        upsert=True
    )

async def get_recent_states(student_id: str, limit: int = 5) -> list[dict]:
    """Retrieve the most recent C1 states for a student to calculate rolling metrics."""
    db = get_db()
    cursor = db.c1_learner_states.find({"student_id": student_id}).sort("_id", -1).limit(limit)
    return await cursor.to_list(length=limit)

async def get_c1_state_by_session(session_id: str) -> dict | None:
    """Retrieve the exact C1 processing result for a specific session."""
    db = get_db()
    return await db.c1_learner_states.find_one({"session_id": session_id})
