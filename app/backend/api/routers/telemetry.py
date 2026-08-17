"""
routers/telemetry.py
====================
Telemetry ingestion and ML-powered cognitive analytics endpoints.

Endpoints:
  POST /api/v1/auth/telemetry          — Ingest an enriched telemetry session
  GET  /api/v1/auth/telemetry/{sid}    — Retrieve raw telemetry history
  GET  /api/v1/auth/telemetry/{sid}/analytics  — ML cognitive profile + risk report
"""

from fastapi import APIRouter, HTTPException, status, Depends
from bson.objectid import ObjectId
from datetime import datetime, timezone

from shared.database import get_db
from dependencies import get_current_user
from schemas.telemetry import TelemetrySessionSubmit
from services.ml_pipeline import run_pipeline
from services.ml_engine import CognitiveLoadClassifier

router = APIRouter(prefix="/api/v1/auth", tags=["Telemetry"])


# ---------------------------------------------------------------------------
# POST /telemetry  — Ingest enriched telemetry session
# ---------------------------------------------------------------------------

@router.post("/telemetry", status_code=status.HTTP_201_CREATED)
async def submit_telemetry(
    req: TelemetrySessionSubmit,
    current_user: dict = Depends(get_current_user),
):
    """
    Ingest a telemetry session payload after activity completion.

    The parent JWT is used to verify ownership of the student_id before
    storing any data — full data isolation is maintained.
    """
    db = get_db()

    try:
        student_oid = ObjectId(req.student_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid student ID format.",
        )

    # Ownership check — parent can only submit for their own students
    student = await db.students.find_one(
        {"_id": student_oid, "parent_id": current_user["_id"]}
    )
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found or does not belong to your account.",
        )

    # Persist to dedicated telemetry_events collection (not the students collection)
    session_doc = req.model_dump()
    session_doc["student_id"] = str(student_oid)
    session_doc["submitted_at"] = datetime.now(timezone.utc).isoformat()

    await db.telemetry_events.insert_one(session_doc)
    
    # Assess real-time cognitive load
    events_list = session_doc.get("events", [])
    cognitive_load = CognitiveLoadClassifier.classify(events_list)

    return {
        "message": "Telemetry session logged successfully.",
        "cognitive_load": cognitive_load
    }


# ---------------------------------------------------------------------------
# GET /telemetry/{student_id}  — Raw telemetry history
# ---------------------------------------------------------------------------

@router.get("/telemetry/{student_id}")
async def get_telemetry(
    student_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Retrieve raw telemetry session history for a student.

    Access is granted to: (a) the owning parent, or (b) a connected specialist.
    """
    db = get_db()

    try:
        student_oid = ObjectId(student_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid student ID format.",
        )

    if current_user.get("role") == "specialist":
        connection = await db.connections.find_one({
            "student_id": student_id,
            "specialist_id": str(current_user["_id"]),
        })
        if not connection:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not connected to this student.",
            )
    else:
        student = await db.students.find_one(
            {"_id": student_oid, "parent_id": current_user["_id"]}
        )
        if not student:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Student not found.",
            )

    cursor = db.telemetry_events.find(
        {"student_id": student_id}
    ).sort("submitted_at", -1).limit(200)

    sessions = await cursor.to_list(length=200)
    for s in sessions:
        s["id"] = str(s["_id"])
        del s["_id"]

    return sessions


# ---------------------------------------------------------------------------
# GET /telemetry/{student_id}/analytics  — ML Cognitive Profile
# ---------------------------------------------------------------------------

@router.get("/telemetry/{student_id}/analytics")
async def get_cognitive_analytics(
    student_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Run the ML Analytics Pipeline over all telemetry sessions for a student
    and return a structured cognitive profile including:
      - 4 cognitive index scores (0-100)
      - Dyslexia subtype risk classification
      - Personalized intervention recommendations

    Access is granted to: (a) the owning parent, or (b) a connected specialist.
    """
    db = get_db()

    try:
        student_oid = ObjectId(student_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid student ID format.",
        )

    # Permission check
    if current_user.get("role") == "specialist":
        connection = await db.connections.find_one({
            "student_id": student_id,
            "specialist_id": str(current_user["_id"]),
        })
        if not connection:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not connected to this student.",
            )
    else:
        student = await db.students.find_one(
            {"_id": student_oid, "parent_id": current_user["_id"]}
        )
        if not student:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Student not found.",
            )

    # Retrieve up to 500 most recent sessions for the pipeline
    cursor = db.telemetry_events.find(
        {"student_id": student_id}
    ).sort("submitted_at", -1).limit(500)
    sessions = await cursor.to_list(length=500)

    if not sessions:
        return {
            "student_id": student_id,
            "status": "insufficient_data",
            "message": "Complete at least one activity to generate a cognitive profile.",
            "data_points": 0,
        }

    # Fetch assessment_risk_score
    comp_results = student.get("comprehensive_assessment_results", {})
    total_yes = sum(sum(1 for a in ans if a is True) for ans in comp_results.values() if isinstance(ans, list))
    total_q = sum(len(ans) for ans in comp_results.values() if isinstance(ans, list))
    assessment_risk_score = total_yes / max(total_q, 1)

    # Run ML pipeline
    profile = run_pipeline(sessions, assessment_risk_score=assessment_risk_score)

    # Persist / upsert the latest cognitive profile for this student
    await db.cognitive_profiles.update_one(
        {"student_id": student_id},
        {
            "$set": {
                **profile,
                "student_id": student_id,
                "last_updated": datetime.now(timezone.utc).isoformat(),
            }
        },
        upsert=True,
    )

    return {
        "student_id": student_id,
        "status": "ok",
        **profile,
    }
