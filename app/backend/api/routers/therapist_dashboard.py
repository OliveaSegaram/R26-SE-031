from fastapi import APIRouter, Depends, HTTPException, Path, Response
from typing import List, Dict, Any
from datetime import datetime
from schemas.dashboards import (
    TherapistOverviewDTO,
    TherapistBehavioralDTO,
    TherapistKinematicsDTO,
    TherapistProfileDTO,
    TherapistKnowledgeDTO,
    TherapistAdaptiveDTO,
    ConfusionPair,
    ShapExplanation,
    AdaptiveTimelineEvent
)
import sys
from pathlib import Path as PathLib
sys.path.insert(0, str(PathLib(__file__).parent.parent.parent.parent))
from shared.database import get_db
from utils.pdf_generator import generate_therapist_report

router = APIRouter(
    prefix="/api/v1/therapist/students",
    tags=["Therapist Dashboard"]
)

def get_current_time_str() -> str:
    return datetime.utcnow().isoformat() + "Z"

@router.get("/{student_id}/overview", response_model=TherapistOverviewDTO)
async def get_therapist_overview(student_id: str = Path(...)):
    db = get_db()
    c1 = await db["behavioral_features"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    c3 = await db["learner_profiles"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    c4 = await db["knowledge_states"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    behavior = c1.get("behavior", {}) if c1 else {}
    indices = c1.get("indices", {}) if c1 else {}
    
    return TherapistOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C3-v1",
        feature_version="F-v1",
        confidence=c3.get("model", {}).get("confidence", 0.85) if c3 else 0.85,
        accuracy=int(behavior.get("accuracy", 75)),
        median_latency_ms=int(behavior.get("median_latency_ms", 2100)),
        hesitation_rate=behavior.get("hesitation_rate", 0.18),
        misclick_rate=behavior.get("misclick_rate", 0.08),
        fatigue_score=c1.get("fatigue", {}).get("score", 0.32) if c1 else 0.32,
        primary_learning_pattern=c3.get("model", {}).get("pattern", "Visual-Orthographic") if c3 else "Visual-Orthographic",
        overall_mastery=0.68,
        current_kc="Letter Identity",
        current_difficulty=0.7
    )

@router.get("/{student_id}/behavior", response_model=TherapistBehavioralDTO)
async def get_therapist_behavior(student_id: str = Path(...)):
    db = get_db()
    c1 = await db["behavioral_features"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    indices = c1.get("indices", {}) if c1 else {}
    
    return TherapistBehavioralDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C1-v1",
        feature_version="F-v1",
        accuracy_trend=[{"session": "S1", "accuracy": 50}, {"session": "S2", "accuracy": 60}, {"session": "S3", "accuracy": 75}],
        latency_trend=[{"session": "S1", "latency_ms": 3000}, {"session": "S2", "latency_ms": 2500}, {"session": "S3", "latency_ms": 2100}],
        fatigue_trend=[{"session": "S1", "fatigue": 0.4}, {"session": "S2", "fatigue": 0.35}, {"session": "S3", "fatigue": 0.32}],
        learner_indices={
            "visual_processing": indices.get("visual_processing_index", 68.0),
            "phonological_task": indices.get("phonological_task_index", 71.0),
            "motor_interaction": indices.get("motor_interaction_index", 82.0),
            "attention_stability": indices.get("attention_stability_index", 64.0)
        },
        error_composition={"correct": 75, "incorrect": 17, "misclick": 8}
    )

@router.get("/{student_id}/kinematics", response_model=TherapistKinematicsDTO)
async def get_therapist_kinematics(student_id: str = Path(...)):
    # Connect to kinematic_features once C2 is ready
    return TherapistKinematicsDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C2-v1",
        feature_version="F-v1",
        touch_trajectories=[
            {"target": "අ", "selected": "ආ", "path": [{"x": 10, "y": 20}, {"x": 50, "y": 80}, {"x": 90, "y": 100}]}
        ],
        oci_trend=[{"session": "S1", "oci": 0.4}, {"session": "S2", "oci": 0.5}, {"session": "S3", "oci": 0.67}],
        path_efficiency_trend=[{"session": "S1", "efficiency": 0.8}, {"session": "S2", "efficiency": 0.75}, {"session": "S3", "efficiency": 0.63}],
        top_confusion_pairs=[
            ConfusionPair(target="අ", selected="ආ", count=5),
            ConfusionPair(target="ක", selected="ග", count=3),
            ConfusionPair(target="ප", selected="බ", count=2)
        ],
        feature_comparison={
            "path_efficiency": 0.63,
            "oci": 0.67,
            "dwell_time_s": 0.21,
            "normalized_jerk": 3.82
        }
    )

@router.get("/{student_id}/profile", response_model=TherapistProfileDTO)
async def get_therapist_profile(student_id: str = Path(...)):
    db = get_db()
    c3 = await db["learner_profiles"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    return TherapistProfileDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C3-v1",
        feature_version="F-v1",
        confidence=c3.get("model", {}).get("confidence", 0.71) if c3 else 0.71,
        selected_pattern=c3.get("model", {}).get("pattern", "Visual-Orthographic") if c3 else "Visual-Orthographic",
        probabilities={
            "Typical": 0.08,
            "Visual-Orthographic": 0.71,
            "Phonological": 0.12,
            "Combined": 0.09
        },
        shap_values=[
            ShapExplanation(feature="OCI", contribution=0.31),
            ShapExplanation(feature="Response Latency", contribution=0.14),
            ShapExplanation(feature="Path Efficiency", contribution=0.11),
            ShapExplanation(feature="Hesitation", contribution=0.07),
        ],
        top_shap_features=["OCI", "Response Latency", "Path Efficiency"]
    )

@router.get("/{student_id}/knowledge", response_model=TherapistKnowledgeDTO)
async def get_therapist_knowledge(student_id: str = Path(...)):
    db = get_db()
    c4 = await db["knowledge_states"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    kcs = c4.get("knowledge_state", {
        "Letter Identity": 0.72,
        "Visual Discrimination": 0.84,
        "Audio Recognition": 0.49,
        "Word Formation": 0.21,
        "Sentence Construction": 0.18
    }) if c4 else {
        "Letter Identity": 0.72,
        "Visual Discrimination": 0.84,
        "Audio Recognition": 0.49,
        "Word Formation": 0.21,
        "Sentence Construction": 0.18
    }

    return TherapistKnowledgeDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C4-v1",
        feature_version="F-v1",
        knowledge_components=kcs,
        mastery_trend=[
            {"attempt": 1, "mastery": 0.3},
            {"attempt": 2, "mastery": 0.45},
            {"attempt": 3, "mastery": 0.48},
            {"attempt": 4, "mastery": 0.54}
        ]
    )

@router.get("/{student_id}/adaptive-history", response_model=TherapistAdaptiveDTO)
async def get_therapist_adaptive(student_id: str = Path(...)):
    db = get_db()
    c4_history_cursor = db["adaptive_decisions"].find({"student_id": student_id}).sort("_id", -1).limit(4)
    c4_history = await c4_history_cursor.to_list(length=4)
    
    if not c4_history:
        timeline = [
            AdaptiveTimelineEvent(attempt=1, mastery=0.30, difficulty=0.40, scaffold_level=0, scaffold_desc="None"),
            AdaptiveTimelineEvent(attempt=2, mastery=0.45, difficulty=0.50, scaffold_level=0, scaffold_desc="None"),
            AdaptiveTimelineEvent(attempt=3, mastery=0.48, difficulty=0.70, scaffold_level=0, scaffold_desc="None"),
            AdaptiveTimelineEvent(attempt=4, mastery=0.54, difficulty=0.45, scaffold_level=1, scaffold_desc="Visual Hint ON"),
        ]
    else:
        timeline = []
        for idx, decision in enumerate(c4_history):
            timeline.append(AdaptiveTimelineEvent(
                attempt=idx+1,
                mastery=decision.get("mastery_after", 0.0),
                difficulty=decision.get("selected_difficulty", 0.0),
                scaffold_level=decision.get("scaffold_level", 0),
                scaffold_desc=decision.get("decision_reason", "None")
            ))

    return TherapistAdaptiveDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C4-v1",
        feature_version="F-v1",
        learner_ability=0.55,
        item_difficulty=0.45,
        timeline=timeline
    )

@router.get("/{student_id}/report")
async def download_therapist_report(student_id: str = Path(...)):
    # Re-use existing getters to fetch the latest data
    overview = await get_therapist_overview(student_id)
    behavior = await get_therapist_behavior(student_id)
    kinematics = await get_therapist_kinematics(student_id)
    
    pdf_bytes = generate_therapist_report(
        student_id=student_id,
        overview=overview.dict(),
        behavior=behavior.dict(),
        kinematics=kinematics.dict()
    )
    
    headers = {
        'Content-Disposition': f'attachment; filename="sipsara_clinical_report_{student_id}.pdf"'
    }
    return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)
