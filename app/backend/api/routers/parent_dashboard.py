from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from schemas.dashboards import (
    ParentOverviewDTO,
    ParentSkillsDTO,
    ParentLearningPatternDTO,
    ParentActivityHistoryDTO,
    SkillProgress,
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
    
    # 1. Accuracy and Fatigue from latest C1 behavioral_features
    c1 = await db["behavioral_features"].find_one(
        {"student_id": student_id},
        sort=[("_id", -1)]
    )
    accuracy = c1.get("behavior", {}).get("accuracy", 0) if c1 else 75
    fatigue_status = c1.get("fatigue", {}).get("state", "Optimal") if c1 else "Optimal"
    
    # 2. Practice time and sessions
    sessions_cursor = db["telemetry_events"].find({"student_id": student_id})
    sessions = await sessions_cursor.to_list(length=100)
    sessions_completed = len(sessions)
    
    practice_time_ms = sum(s.get("total_round_latency_ms", 0) for s in sessions)
    practice_time_minutes = int(practice_time_ms / 60000) if sessions else 0
    
    current_skill = sessions[-1].get("activity_id", "Letter Recognition") if sessions else "Letter Recognition"

    median_latency = c1.get("behavior", {}).get("median_latency_ms", 0) if c1 else 0
    if median_latency == 0:
        response_speed_status = "N/A"
    elif median_latency < 2000:
        response_speed_status = "Fast"
    elif median_latency < 4000:
        response_speed_status = "Normal"
    else:
        response_speed_status = "Developing"

    return ParentOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        accuracy=int(accuracy),
        practice_time_minutes=practice_time_minutes,
        sessions_completed=sessions_completed,
        current_skill=current_skill,
        fatigue_status=fatigue_status,
        response_speed_status=response_speed_status
    )

@router.get("/{student_id}/skills", response_model=ParentSkillsDTO)
async def get_parent_skills(student_id: str = Path(...)):
    db = get_db()
    
    # Get latest C4 knowledge states
    state = await db["knowledge_states"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    kcs = state.get("knowledge_state", {}) if state else {}
    
    def get_mastery(kc_key, default_val=0):
        return int(kcs.get(kc_key, default_val) * 100) if kcs else default_val

    def get_status(mastery):
        if mastery >= 80: return "Mastered"
        if mastery >= 60: return "Progressing"
        if mastery > 0: return "Developing"
        return "Locked"

    skills_data = [
        SkillProgress(skill_id="S1", skill_name="Picture Recognition", mastery_percentage=get_mastery("KC_PICTURE_RECOGNITION"), status=get_status(get_mastery("KC_PICTURE_RECOGNITION"))),
        SkillProgress(skill_id="S2", skill_name="Letter Recognition", mastery_percentage=get_mastery("KC_LETTER_IDENTITY"), status=get_status(get_mastery("KC_LETTER_IDENTITY"))),
        SkillProgress(skill_id="S3", skill_name="Simple Words", mastery_percentage=get_mastery("KC_WORD_FORMATION"), status=get_status(get_mastery("KC_WORD_FORMATION"))),
        SkillProgress(skill_id="S4", skill_name="Sentence Construction", mastery_percentage=get_mastery("KC_SENTENCE"), status=get_status(get_mastery("KC_SENTENCE"))),
        SkillProgress(skill_id="S5", skill_name="Comprehension", mastery_percentage=get_mastery("KC_COMPREHENSION"), status=get_status(get_mastery("KC_COMPREHENSION"))),
        SkillProgress(skill_id="S6", skill_name="Reading Book", mastery_percentage=get_mastery("KC_READING"), status=get_status(get_mastery("KC_READING"))),
    ]
    return ParentSkillsDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        skills=skills_data
    )

@router.get("/{student_id}/learning-pattern", response_model=ParentLearningPatternDTO)
async def get_parent_learning_pattern(student_id: str = Path(...)):
    db = get_db()
    c3 = await db["learner_profiles"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    pattern = "Visual-Letter Learning Pattern"
    confidence = "Moderate"
    observations = [
        "Repeated similar-letter errors",
        "Longer response times on these activities"
    ]
    recommended = "Practice similar-letter recognition."

    if c3:
        pattern = c3.get("learner_profile", {}).get("primary_pattern", pattern)
        conf_val = c3.get("learner_profile", {}).get("confidence", 0.5)
        if conf_val > 0.8: confidence = "High"
        elif conf_val < 0.4: confidence = "Low"

    return ParentLearningPatternDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        primary_learning_pattern=pattern,
        confidence_level=confidence,
        supporting_observations=observations,
        recommended_practice=recommended
    )

@router.get("/{student_id}/activity-history", response_model=ParentActivityHistoryDTO)
async def get_parent_activity_history(
    student_id: str = Path(...),
    limit: Optional[int] = Query(None, description="Number of interactions to return"),
    days: Optional[int] = Query(None, description="Number of days to look back")
):
    db = get_db()
    
    query = {"student_id": student_id}
    reporting_period = "Last 10 Interactions"
    
    if days is not None:
        cutoff = datetime.utcnow() - timedelta(days=days)
        query["timestamp"] = {"$gte": cutoff.isoformat()}
        reporting_period = f"Last {days} Days"
        if limit is None:
            limit = 100 # safe bound
    elif limit is not None:
        reporting_period = f"Last {limit} Interactions"
    else:
        limit = 10
        
    history_cursor = db["telemetry_events"].find(query).sort("_id", 1)
    if limit is not None:
        history_cursor = history_cursor.limit(limit)
        
    events = await history_cursor.to_list(length=limit or 100)
    
    history_data = []
    if not events:
        history_data = [
            ActivityHistoryItem(session_date="2026-08-28", activity_name="Letter Recognition", skill_name="Letters", accuracy=80, duration_minutes=8)
        ]
    else:
        for evt in events:
            timestamp = evt.get("timestamp", datetime.utcnow().isoformat())
            # Parse only date part, fallback to today
            session_date = timestamp[:10] if isinstance(timestamp, str) else datetime.utcnow().strftime("%Y-%m-%d")
            
            history_data.append(ActivityHistoryItem(
                session_date=session_date,
                activity_name=evt.get("activity_id", "Letter Recognition"),
                skill_name="Letters",
                accuracy=100 if evt.get("is_correct") else 0,
                duration_minutes=max(1, evt.get("total_round_latency_ms", 60000) // 60000)
            ))
        
    return ParentActivityHistoryDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period=reporting_period,
        history=history_data
    )

@router.get("/{student_id}/report")
async def download_parent_report(student_id: str = Path(...)):
    # Re-use existing getters to fetch the latest data
    overview = await get_parent_overview(student_id)
    skills = await get_parent_skills(student_id)
    pattern = await get_parent_learning_pattern(student_id)
    
    pdf_bytes = generate_parent_report(
        student_id=student_id,
        overview=overview.dict(),
        skills=skills.dict(),
        pattern=pattern.dict()
    )
    
    headers = {
        'Content-Disposition': f'attachment; filename="sipsara_report_{student_id}.pdf"'
    }
    return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)
