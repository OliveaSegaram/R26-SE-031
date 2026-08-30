from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from schemas.dashboards import (
    ParentOverviewDTO,
    ParentReadingFluencyDTO,
    ParentReadingProgressDTO,
    ParentLearningPatternDTO,
    ParentActivityHistoryDTO,
    ActivityHistoryItem
)
import sys
from pathlib import Path as PathLib
sys.path.insert(0, str(PathLib(__file__).parent.parent.parent.parent))
from shared.database import get_db
from utils.pdf_generator import generate_parent_report

router = APIRouter(
    prefix="/api/v1/parent/students",
    tags=["Parent Dashboard"]
)

def get_current_time_str() -> str:
    return datetime.utcnow().isoformat() + "Z"

@router.get("/{student_id}/overview", response_model=ParentOverviewDTO)
async def get_parent_overview(student_id: str = Path(...)):
    db = get_db()
    
    # 1. Sessions Completed (Unique session_ids)
    sessions = await db.telemetry_events.distinct("session_id", {"student_id": student_id})
    sessions_completed = len(sessions)
    
    # 2. Practice Time (Sum of total_round_latency_ms)
    pipeline = [
        {"$match": {"student_id": student_id}},
        {"$group": {"_id": None, "total_ms": {"$sum": "$total_round_latency_ms"}, "correct_count": {"$sum": {"$cond": ["$is_correct", 1, 0]}}, "total_count": {"$sum": 1}}}
    ]
    cursor = db.telemetry_events.aggregate(pipeline)
    result = await cursor.to_list(length=1)
    
    if result and result[0]["total_count"] > 0:
        practice_time_minutes = int(result[0]["total_ms"] / 60000)
        accuracy = int((result[0]["correct_count"] / result[0]["total_count"]) * 100)
    else:
        practice_time_minutes = 0
        accuracy = 0
        
    # Query latest adaptive decision for overall mastery to map to progress
    latest_c4 = await db.adaptive_decisions.find_one({"student_id": student_id}, sort=[("_id", -1)])
    mastery = latest_c4.get("mastery_after", 0.0) if latest_c4 else 0.0
    
    if mastery >= 0.8:
        progress = "Advanced"
    elif mastery >= 0.5:
        progress = "Developing"
    else:
        progress = "Needs Support"

    return ParentOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="All Time",
        accuracy=accuracy,
        practice_time_minutes=practice_time_minutes,
        sessions_completed=sessions_completed,
        reading_progress=progress
    )

@router.get("/{student_id}/fluency", response_model=ParentReadingFluencyDTO)
async def get_parent_fluency(student_id: str = Path(...)):
    db = get_db()
    latest_c4 = await db.adaptive_decisions.find_one({"student_id": student_id}, sort=[("_id", -1)])
    mastery = latest_c4.get("mastery_after", 0.0) if latest_c4 else 0.0
    
    status = "Developing"
    if mastery >= 0.8: status = "Advanced"
    elif mastery < 0.5: status = "Needs Support"
    
    return ParentReadingFluencyDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        fluency_status=status,
        fluency_score=mastery
    )

@router.get("/{student_id}/progress", response_model=ParentReadingProgressDTO)
async def get_parent_progress(student_id: str = Path(...)):
    db = get_db()
    
    # Calculate accuracy per session
    pipeline = [
        {"$match": {"student_id": student_id}},
        {"$group": {
            "_id": "$session_id",
            "correct": {"$sum": {"$cond": ["$is_correct", 1, 0]}},
            "total": {"$sum": 1},
            "timestamp": {"$min": "$timestamp"}
        }},
        {"$sort": {"timestamp": 1}},
        {"$limit": 10}
    ]
    cursor = db.telemetry_events.aggregate(pipeline)
    results = await cursor.to_list(length=10)
    
    trend = []
    for idx, r in enumerate(results):
        acc = int((r["correct"] / r["total"]) * 100) if r["total"] > 0 else 0
        trend.append({"session": f"S{idx+1}", "accuracy": acc})
        
    if not trend:
        # Fallback if no data
        trend = [{"session": "S1", "accuracy": 0}]

    return ParentReadingProgressDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 10 Sessions",
        accuracy_trend=trend
    )

@router.get("/{student_id}/learning-pattern", response_model=ParentLearningPatternDTO)
async def get_parent_learning_pattern(student_id: str = Path(...)):
    db = get_db()
    latest_c3 = await db.learner_profiles.find_one({"student_id": student_id}, sort=[("_id", -1)])
    pattern = latest_c3.get("learner_profile", {}).get("primary_pattern", "Typical") if latest_c3 else "Typical"
    
    if pattern == "Phonological":
        obs = "Your child occasionally hesitates on complex vowel sounds."
        rec = ["Practice reading short sentences aloud", "Play rhyming word games"]
    elif pattern == "Visual-Orthographic":
        obs = "Your child is confusing visually similar Sinhala letters."
        rec = ["Letter tracing exercises", "Identify letters in storybooks"]
    else:
        obs = "Your child is showing steady reading development."
        rec = ["Continue daily reading practice", "Introduce new storybooks"]

    return ParentLearningPatternDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        observation=obs,
        recommended_practices=rec
    )

@router.get("/{student_id}/activity-history", response_model=ParentActivityHistoryDTO)
async def get_parent_activity_history(student_id: str = Path(...)):
    db = get_db()
    pipeline = [
        {"$match": {"student_id": student_id}},
        {"$group": {
            "_id": {"session": "$session_id", "activity": "$activity_id"},
            "correct": {"$sum": {"$cond": ["$is_correct", 1, 0]}},
            "total": {"$sum": 1},
            "duration": {"$sum": "$total_round_latency_ms"},
            "timestamp": {"$max": "$timestamp"}
        }},
        {"$sort": {"timestamp": -1}},
        {"$limit": 5}
    ]
    cursor = db.telemetry_events.aggregate(pipeline)
    results = await cursor.to_list(length=5)
    
    history = []
    for r in results:
        ts = r["timestamp"]
        try:
            date_str = datetime.fromisoformat(ts).strftime("%b %d")
        except:
            date_str = ts[:10]
            
        acc = int((r["correct"] / r["total"]) * 100) if r["total"] > 0 else 0
        dur_mins = max(1, int(r["duration"] / 60000))
        
        history.append(ActivityHistoryItem(
            session_date=date_str,
            activity_name=r["_id"]["activity"],
            accuracy=acc,
            duration_minutes=dur_mins
        ))

    return ParentActivityHistoryDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Recent",
        history=history
    )

@router.get("/{student_id}/report")
async def download_parent_report(student_id: str = Path(...)):
    pdf_bytes = b"MOCK PDF DATA"
    headers = {
        'Content-Disposition': f'attachment; filename="sipsara_report_{student_id}.pdf"'
    }
    return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)
