from fastapi import APIRouter, Depends, HTTPException, Path
from typing import List, Dict, Any
from datetime import datetime
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
    practice_time_minutes = (sessions_completed * 2) # simplified mock calculation for now
    
    current_skill = sessions[0].get("activity_name", "Letter Recognition") if sessions else "Letter Recognition"

    return ParentOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        accuracy=int(accuracy),
        practice_time_minutes=practice_time_minutes,
        sessions_completed=sessions_completed,
        current_skill=current_skill,
        fatigue_status=fatigue_status,
        response_speed_status="Developing"
    )

@router.get("/{student_id}/skills", response_model=ParentSkillsDTO)
async def get_parent_skills(student_id: str = Path(...)):
    db = get_db()
    
    # Get latest C4 knowledge states
    state = await db["knowledge_states"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    kcs = state.get("knowledge_state", {}) if state else {}
    
    def get_mastery(kc_key, default_val):
        return int(kcs.get(kc_key, default_val) * 100) if kcs else default_val

    skills_data = [
        SkillProgress(skill_id="S1", skill_name="Picture Recognition", mastery_percentage=get_mastery("KC_PICTURE_RECOGNITION", 85), status="Mastered"),
        SkillProgress(skill_id="S2", skill_name="Letter Recognition", mastery_percentage=get_mastery("KC_LETTER_IDENTITY", 72), status="Developing"),
        SkillProgress(skill_id="S3", skill_name="Simple Words", mastery_percentage=get_mastery("KC_WORD_FORMATION", 48), status="Progressing"),
        SkillProgress(skill_id="S4", skill_name="Sentence Construction", mastery_percentage=get_mastery("KC_SENTENCE", 31), status="Developing"),
        SkillProgress(skill_id="S5", skill_name="Comprehension", mastery_percentage=get_mastery("KC_COMPREHENSION", 22), status="Developing"),
        SkillProgress(skill_id="S6", skill_name="Reading Book", mastery_percentage=get_mastery("KC_READING", 0), status="Locked"),
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
        pattern = c3.get("model", {}).get("pattern", pattern)
        conf_val = c3.get("model", {}).get("confidence", 0.5)
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
async def get_parent_activity_history(student_id: str = Path(...)):
    db = get_db()
    
    history_cursor = db["telemetry_events"].find({"student_id": student_id}).sort("_id", -1).limit(5)
    events = await history_cursor.to_list(length=5)
    
    history_data = []
    for evt in events:
        history_data.append(ActivityHistoryItem(
            session_date=datetime.utcnow().strftime("%Y-%m-%d"),
            activity_name=evt.get("activity_name", "Letter Recognition"),
            skill_name="Letters",
            accuracy=100 if evt.get("is_correct") else 0,
            duration_minutes=int(evt.get("total_round_latency_ms", 120000) / 60000)
        ))
        
    if not history_data:
        history_data = [
            ActivityHistoryItem(session_date="2026-08-28", activity_name="Letter Recognition", skill_name="Letters", accuracy=80, duration_minutes=8)
        ]
        
    return ParentActivityHistoryDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        history=history_data
    )

@router.get("/{student_id}/report")
async def download_parent_report(student_id: str = Path(...)):
    return {"message": "PDF Generation endpoint placeholder"}
