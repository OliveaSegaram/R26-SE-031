from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
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
    
    c4_mastery = c4.get("knowledge_state", {}) if c4 else {}
    if c4_mastery:
        overall_mastery = sum(c4_mastery.values()) / len(c4_mastery)
    else:
        overall_mastery = 0.0
        
    current_kc = "None"
    current_difficulty = 0.0
    c4_history_cursor = db["adaptive_decisions"].find({"student_id": student_id}).sort("_id", -1).limit(1)
    latest_decision_list = await c4_history_cursor.to_list(length=1)
    if latest_decision_list:
        decision = latest_decision_list[0]
        current_kc = decision.get("target_kc", "None")
        current_difficulty = decision.get("selected_difficulty", 0.0)
    
    return TherapistOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C3-v1",
        feature_version="F-v1",
        confidence=c3.get("learner_profile", {}).get("confidence", 0.85) if c3 else 0.85,
        accuracy=int(behavior.get("accuracy", 75)),
        median_latency_ms=int(behavior.get("median_latency_ms", 2100)),
        hesitation_rate=behavior.get("hesitation_rate", 0.18),
        misclick_rate=behavior.get("misclick_rate", 0.08),
        fatigue_score=c1.get("fatigue", {}).get("score", 0.32) if c1 else 0.32,
        primary_learning_pattern=c3.get("learner_profile", {}).get("primary_pattern", "Visual-Orthographic Learning Pattern") if c3 else "Visual-Orthographic Learning Pattern",
        overall_mastery=overall_mastery,
        current_kc=current_kc,
        current_difficulty=current_difficulty
    )

@router.get("/{student_id}/behavior", response_model=TherapistBehavioralDTO)
async def get_therapist_behavior(
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
        if limit is None: limit = 100
    elif limit is not None:
        reporting_period = f"Last {limit} Interactions"
    else:
        limit = 10

    c1_cursor = db["behavioral_features"].find(query).sort("_id", 1)
    if limit is not None:
        c1_cursor = c1_cursor.limit(limit)
    c1_history = await c1_cursor.to_list(length=limit or 100)
    
    accuracy_trend = []
    latency_trend = []
    fatigue_trend = []
    
    if not c1_history:
        accuracy_trend = [{"session": "S1", "accuracy": 50}, {"session": "S2", "accuracy": 60}, {"session": "S3", "accuracy": 75}]
        latency_trend = [{"session": "S1", "latency_ms": 3000}, {"session": "S2", "latency_ms": 2500}, {"session": "S3", "latency_ms": 2100}]
        fatigue_trend = [{"session": "S1", "fatigue": 0.4}, {"session": "S2", "fatigue": 0.35}, {"session": "S3", "fatigue": 0.32}]
        indices = {}
    else:
        for idx, doc in enumerate(c1_history):
            sess_name = f"S{idx+1}"
            beh = doc.get("behavior", {})
            fat = doc.get("fatigue", {})
            accuracy_trend.append({"session": sess_name, "accuracy": beh.get("accuracy", 0)})
            latency_trend.append({"session": sess_name, "latency_ms": beh.get("median_latency_ms", 0)})
            fatigue_trend.append({"session": sess_name, "fatigue": fat.get("score", 0.0)})
        indices = c1_history[-1].get("indices", {})
    
    error_composition={"correct": 0, "incorrect": 0, "misclick": 0}
    if c1_history:
        error_comp = c1_history[-1].get("behavior", {}).get("error_composition")
        if error_comp:
            error_composition = error_comp

    return TherapistBehavioralDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period=reporting_period,
        model_version="C1-v1",
        feature_version="F-v1",
        accuracy_trend=accuracy_trend,
        latency_trend=latency_trend,
        fatigue_trend=fatigue_trend,
        learner_indices={
            "visual_processing": indices.get("visual_processing_index", 68.0),
            "phonological_task": indices.get("phonological_task_index", 71.0),
            "motor_interaction": indices.get("motor_interaction_index", 82.0),
            "attention_stability": indices.get("attention_stability_index", 64.0)
        },
        error_composition=error_composition
    )

@router.get("/{student_id}/kinematics", response_model=TherapistKinematicsDTO)
async def get_therapist_kinematics(
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
        if limit is None: limit = 100
    elif limit is not None:
        reporting_period = f"Last {limit} Interactions"
    else:
        limit = 10

    c2_cursor = db["kinematic_features"].find(query).sort("_id", 1)
    if limit is not None:
        c2_cursor = c2_cursor.limit(limit)
    c2_history = await c2_cursor.to_list(length=limit or 100)
    
    oci_trend = []
    path_efficiency_trend = []
    
    if not c2_history:
        oci_trend = [{"session": "S1", "oci": 0.4}, {"session": "S2", "oci": 0.5}, {"session": "S3", "oci": 0.67}]
        path_efficiency_trend = [{"session": "S1", "efficiency": 0.8}, {"session": "S2", "efficiency": 0.75}, {"session": "S3", "efficiency": 0.63}]
        feature_comparison = {
            "path_efficiency": 0.63,
            "oci": 0.67,
            "dwell_time_s": 0.21,
            "normalized_jerk": 3.82
        }
    else:
        for idx, doc in enumerate(c2_history):
            sess_name = f"S{idx+1}"
            oci_trend.append({"session": sess_name, "oci": doc.get("orthographic_confusion_index", 0.0)})
            path_efficiency_trend.append({"session": sess_name, "efficiency": doc.get("path_efficiency", 0.0)})
        latest_c2 = c2_history[-1]
        feature_comparison = {
            "path_efficiency": latest_c2.get("path_efficiency", 0.0),
            "oci": latest_c2.get("orthographic_confusion_index", 0.0),
            "dwell_time_s": latest_c2.get("mean_dwell_time_ms", 0.0) / 1000.0,
            "normalized_jerk": latest_c2.get("normalized_jerk", 0.0)
        }

    touch_trajectories = []
    top_confusion_pairs = []
    if c2_history:
        latest_c2 = c2_history[-1]
        trajs = latest_c2.get("touch_trajectories", [])
        if trajs:
            touch_trajectories = trajs
        conf_pairs = latest_c2.get("top_confusion_pairs", [])
        if conf_pairs:
            for cp in conf_pairs:
                top_confusion_pairs.append(ConfusionPair(
                    target=cp.get("target", "?"), 
                    selected=cp.get("selected", "?"), 
                    count=cp.get("count", 0)
                ))

    return TherapistKinematicsDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period=reporting_period,
        model_version="C2-v1",
        feature_version="F-v1",
        touch_trajectories=touch_trajectories,
        oci_trend=oci_trend,
        path_efficiency_trend=path_efficiency_trend,
        top_confusion_pairs=top_confusion_pairs,
        feature_comparison=feature_comparison
    )

@router.get("/{student_id}/profile", response_model=TherapistProfileDTO)
async def get_therapist_profile(student_id: str = Path(...)):
    db = get_db()
    c3 = await db["learner_profiles"].find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    # Map raw SHAP explanations to DTO
    shap_vals = []
    top_feats = []
    if c3 and "shap_explanations" in c3:
        exps = c3["shap_explanations"].get("top_contributing_features", [])
        for exp in exps:
            contrib = float(exp.get("shap_impact", "0.0").replace("+", ""))
            shap_vals.append(ShapExplanation(feature=exp["feature_name"], contribution=contrib))
            top_feats.append(exp["feature_name"])
    
    if not shap_vals:
        shap_vals = [
            ShapExplanation(feature="OCI", contribution=0.31),
            ShapExplanation(feature="Response Latency", contribution=0.14)
        ]
        top_feats = ["OCI", "Response Latency"]

    probabilities = {"Typical": 0.0, "Visual-Orthographic": 0.0, "Phonological": 0.0, "Combined": 0.0}
    if c3:
        probs = c3.get("learner_profile", {}).get("probabilities")
        if probs:
            probabilities = probs

    return TherapistProfileDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C3-v1",
        feature_version="F-v1",
        confidence=c3.get("learner_profile", {}).get("confidence", 0.71) if c3 else 0.71,
        selected_pattern=c3.get("learner_profile", {}).get("primary_pattern", "Visual-Orthographic Learning Pattern") if c3 else "Visual-Orthographic Learning Pattern",
        probabilities=probabilities,
        shap_values=shap_vals,
        top_shap_features=top_feats
    )

@router.get("/{student_id}/knowledge", response_model=TherapistKnowledgeDTO)
async def get_therapist_knowledge(
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
        if limit is None: limit = 100
    elif limit is not None:
        reporting_period = f"Last {limit} Interactions"
    else:
        limit = 10

    c4_cursor = db["knowledge_states"].find(query).sort("_id", 1)
    if limit is not None:
        c4_cursor = c4_cursor.limit(limit)
    c4_history = await c4_cursor.to_list(length=limit or 100)
    
    mastery_trend = []
    if not c4_history:
        mastery_trend = [
            {"attempt": 1, "mastery": 0.3},
            {"attempt": 2, "mastery": 0.45},
            {"attempt": 3, "mastery": 0.48},
            {"attempt": 4, "mastery": 0.54}
        ]
        kcs = {
            "Letter Identity": 0.72,
            "Visual Discrimination": 0.84,
            "Audio Recognition": 0.49,
            "Word Formation": 0.21,
            "Sentence Construction": 0.18
        }
    else:
        for idx, doc in enumerate(c4_history):
            mastery = doc.get("knowledge_state", {}).get("KC_LETTER_IDENTITY", 0.5)
            mastery_trend.append({"attempt": idx + 1, "mastery": mastery})
        kcs = c4_history[-1].get("knowledge_state", {})

    return TherapistKnowledgeDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period=reporting_period,
        model_version="C4-v1",
        feature_version="F-v1",
        knowledge_components=kcs,
        mastery_trend=mastery_trend
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

    learner_ability = 0.0
    item_difficulty = 0.0
    if timeline:
        last_event = timeline[-1]
        learner_ability = last_event.mastery
        item_difficulty = last_event.difficulty

    return TherapistAdaptiveDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Last 7 Days",
        model_version="C4-v1",
        feature_version="F-v1",
        learner_ability=learner_ability,
        item_difficulty=item_difficulty,
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
