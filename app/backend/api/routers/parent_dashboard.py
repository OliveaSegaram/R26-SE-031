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
    
    pipeline = [
        {"$match": {"student_id": student_id}},
        {"$group": {"_id": None, "total_sec": {"$sum": "$session_duration_seconds"}}}
    ]
    cursor = db.telemetry_events.aggregate(pipeline)
    result = await cursor.to_list(length=1)
    practice_time_minutes = int(result[0]["total_sec"] / 60) if result and result[0].get("total_sec") else 0

    latest_summary = await db.session_summaries.find_one({"student_id": student_id}, sort=[("completed_at", -1)])
    accuracy = 0
    if latest_summary and latest_summary.get("overall"):
        acc_float = latest_summary["overall"].get("accuracy", 0.0)
        accuracy = int(acc_float * 100)
        
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
    
    cursor = db.session_summaries.find({"student_id": student_id}).sort("completed_at", 1).limit(10)
    results = await cursor.to_list(length=10)
    
    trend = []
    for idx, r in enumerate(results):
        overall = r.get("overall", {})
        acc_float = overall.get("accuracy", 0.0)
        trend.append({"session": f"S{idx+1}", "accuracy": int(acc_float * 100)})
        
    if not trend:
        # Fallback if no data
        trend = [{"session": "S1", "accuracy": 0}]

    return ParentReadingProgressDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 10 Sessions",
        accuracy_trend=trend
    )

@router.get("/{student_id}/skills")
async def get_parent_skills(student_id: str = Path(...)):
    db = get_db()
    latest_ks = await db.knowledge_states.find_one({"student_id": student_id}, sort=[("updated_at", -1)])
    
    skills = []
    if latest_ks and "knowledge_state" in latest_ks:
        for kc, mastery in latest_ks["knowledge_state"].items():
            status = "Mastered" if mastery >= 0.8 else ("Progressing" if mastery >= 0.4 else "Needs Support")
            skills.append({
                "skill_name": kc.replace("_", " ").title(),
                "mastery_percentage": int(mastery * 100),
                "status": status
            })
            
    if not skills:
        # Fallback to general skills if empty
        skills = [
            {"skill_name": "Visual Recognition", "mastery_percentage": 0, "status": "Not Started"},
            {"skill_name": "Basic Letter Recognition", "mastery_percentage": 0, "status": "Not Started"},
            {"skill_name": "Form Simple Words", "mastery_percentage": 0, "status": "Not Started"},
            {"skill_name": "Form Simple Sentences", "mastery_percentage": 0, "status": "Not Started"},
            {"skill_name": "Reading Comprehension", "mastery_percentage": 0, "status": "Not Started"}
        ]
        
    return {
        "updated_at": get_current_time_str(),
        "student_id": student_id,
        "skills": skills
    }

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
    cursor = db.session_summaries.find({"student_id": student_id}).sort("completed_at", -1).limit(5)
    results = await cursor.to_list(length=5)
    
    history = []
    for r in results:
        ts = r.get("completed_at", get_current_time_str())
        try:
            date_str = datetime.fromisoformat(ts).strftime("%b %d")
        except:
            date_str = ts[:10]
            
        activity_breakdown = r.get("activity_breakdown", {})
        for act_id, metrics in activity_breakdown.items():
            acc_float = metrics.get("accuracy", 0.0)
            trials = metrics.get("trials", 1)
            med_lat = metrics.get("median_response_latency_ms") or 5000
            dur_mins = max(1, int((trials * med_lat) / 60000))
            
            history.append(ActivityHistoryItem(
                session_date=date_str,
                activity_name=act_id,
                accuracy=int(acc_float * 100),
                duration_minutes=dur_mins
            ))
            
            if len(history) >= 5:
                break
        if len(history) >= 5:
            break

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
