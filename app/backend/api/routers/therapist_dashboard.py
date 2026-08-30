from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime
from schemas.dashboards import (
    TherapistOverviewDTO,
    TherapistC1BehavioralDTO,
    BehavioralIndices,
    BehavioralTrends,
    TherapistC2SpeechDTO,
    SpeechLatest,
    SpeechTrends,
    TherapistC3ProfileDTO,
    ShapExplanation,
    TherapistC4AdaptiveDTO,
    KnowledgeComponent,
    AdaptiveHistoryItem
)
import sys
from pathlib import Path as PathLib
sys.path.insert(0, str(PathLib(__file__).parent.parent.parent.parent))
from shared.database import get_db

router = APIRouter(
    prefix="/api/v1/therapist/students",
    tags=["Therapist Dashboard"]
)

def get_current_time_str() -> str:
    return datetime.utcnow().isoformat() + "Z"

@router.get("/{student_id}/overview", response_model=TherapistOverviewDTO)
async def get_therapist_overview(student_id: str = Path(...)):
    db = get_db()
    
    pipeline = [
        {"$match": {"student_id": student_id}},
        {"$group": {"_id": None, "correct": {"$sum": {"$cond": ["$is_correct", 1, 0]}}, "total": {"$sum": 1}}}
    ]
    cursor = db.telemetry_events.aggregate(pipeline)
    result = await cursor.to_list(length=1)
    
    accuracy = 0.0
    attempted = 0
    if result and result[0]["total"] > 0:
        accuracy = float(result[0]["correct"]) / result[0]["total"]
        attempted = result[0]["total"]
        
    latest_ks = await db.knowledge_states.find_one({"student_id": student_id}, sort=[("updated_at", -1)])
    mastery = 0.0
    if latest_ks and "knowledge_components" in latest_ks:
        kcs = latest_ks["knowledge_components"]
        if kcs:
            mastery = sum(kcs.values()) / len(kcs)
            
    status = "Developing"
    if mastery >= 0.8: status = "Advanced"
    elif mastery < 0.5: status = "Needs Support"
    
    latest_lp = await db.learner_profiles.find_one({"student_id": student_id}, sort=[("_id", -1)])
    pattern = "Unknown"
    pattern_conf = 0.0
    if latest_lp and "learner_profile" in latest_lp:
        pattern = latest_lp["learner_profile"].get("primary_pattern", "Unknown")
        pattern_conf = latest_lp["learner_profile"].get("confidence", 0.0)
        
    return TherapistOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="V1",
        feature_version="V1",
        accuracy=accuracy,
        attempted_items=attempted,
        completed_sessions=8,
        reading_fluency_status=status,
        overall_mastery=mastery,
        current_pattern=pattern,
        pattern_confidence=pattern_conf,
        fatigue_status="Low",
        last_active=get_current_time_str()
    )

@router.get("/{student_id}/c1-behavioral", response_model=TherapistC1BehavioralDTO)
async def get_therapist_c1_behavioral(student_id: str = Path(...)):
    db = get_db()
    
    pipeline = [
        {"$match": {"student_id": student_id}},
        {"$group": {"_id": None, "correct": {"$sum": {"$cond": ["$is_correct", 1, 0]}}, "total": {"$sum": 1}}}
    ]
    cursor = db.telemetry_events.aggregate(pipeline)
    result = await cursor.to_list(length=1)
    
    accuracy = 0.0
    if result and result[0]["total"] > 0:
        accuracy = float(result[0]["correct"]) / result[0]["total"]
        
    return TherapistC1BehavioralDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C1-v1",
        feature_version="F-v1",
        accuracy=accuracy,
        median_latency_ms=1200.0,
        latency_variability=200.0,
        latency_drift=-50.0,
        error_rate=1.0 - accuracy,
        error_drift=0.05,
        hesitation_rate=0.1,
        misclick_rate=0.02,
        audio_replay_rate=0.05,
        fatigue_score=0.2,
        indices=BehavioralIndices(
            visual_processing=0.8,
            phonological_tasks=0.7,
            motor_interaction=0.9,
            attention_stability=0.85
        ),
        trends=BehavioralTrends(
            accuracy=[],
            latency=[],
            fatigue=[]
        )
    )

@router.get("/{student_id}/c2-speech", response_model=TherapistC2SpeechDTO)
async def get_therapist_c2_speech(student_id: str = Path(...)):
    db = get_db()
    
    latest_speech = await db.speech_features.find_one({"student_id": student_id}, sort=[("_id", -1)])
    s_data = latest_speech.get("speech_data", {}) if latest_speech else {}
    
    expected = s_data.get("expected_text", "")
    recognized = s_data.get("transcription", "")
    wer = s_data.get("word_error_rate", 0.0)
    stt_conf = 1.0 - wer if wer is not None else 0.0
    
    pipeline_trends = [
        {"$match": {"student_id": student_id}},
        {"$sort": {"_id": 1}},
        {"$limit": 10}
    ]
    cursor_trends = db.speech_features.aggregate(pipeline_trends)
    trends_res = await cursor_trends.to_list(length=10)
    
    lat_trend = []
    sil_trend = []
    peak_trend = []
    
    for idx, t in enumerate(trends_res):
        td = t.get("speech_data", {})
        lat_trend.append({"session": f"S{idx+1}", "value": td.get("Acoustic_Latency_ms", 0)})
        sil_trend.append({"session": f"S{idx+1}", "value": td.get("Intra_Word_Silence_Ratio", 0.0)})
        peak_trend.append({"session": f"S{idx+1}", "value": td.get("Peak_Count_Delta", 0)})
        
    latest_obj = SpeechLatest(
        expected_text=expected,
        transcription=recognized,
        wer=wer or 0.0,
        stt_confidence=stt_conf,
        acoustic_latency_ms=s_data.get("Acoustic_Latency_ms", 0.0),
        voice_onset_ms=s_data.get("Voice_Onset_ms", 0.0),
        peak_delta=s_data.get("Peak_Count_Delta", 0),
        silence_ratio=s_data.get("Intra_Word_Silence_Ratio", 0.0),
        jitter=s_data.get("Local_Jitter", 0.0),
        shimmer=s_data.get("Local_Shimmer", 0.0),
        recording_quality=s_data.get("recording_quality", "Unknown")
    )
    
    trends_obj = SpeechTrends(
        accuracy=[],
        wer=[],
        latency=lat_trend,
        silence_ratio=sil_trend,
        peak_delta=peak_trend
    )
    
    return TherapistC2SpeechDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="V1",
        feature_version="V1",
        latest=latest_obj,
        trends=trends_obj
    )

@router.get("/{student_id}/c3-profile", response_model=TherapistC3ProfileDTO)
async def get_therapist_c3_profile(student_id: str = Path(...)):
    db = get_db()
    latest_c3 = await db.learner_profiles.find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    c3_data = latest_c3.get("learner_profile", {}) if latest_c3 else {}
    probs = c3_data.get("class_probabilities", {})
    pattern = c3_data.get("primary_pattern", "Unknown")
    conf = c3_data.get("confidence", 0.7)
    mods = c3_data.get("modalities_used", ["speech", "behavior", "kinematics"])
    
    shap_data = latest_c3.get("shap_explanations", {}) if latest_c3 else {}
    top_features = shap_data.get("top_contributing_features", [])
    
    shap_list = []
    for feature in top_features:
        shap_list.append(ShapExplanation(
            feature=feature.get("feature_name", ""),
            contribution=feature.get("value", 0.0)
        ))
        
    return TherapistC3ProfileDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C3-v1.0",
        feature_version="F-v1",
        primary_pattern=pattern,
        probabilities=probs,
        confidence=conf,
        modalities_used=mods,
        shap_explanations=shap_list
    )

@router.get("/{student_id}/c4-adaptive", response_model=TherapistC4AdaptiveDTO)
async def get_therapist_c4_adaptive(student_id: str = Path(...)):
    db = get_db()
    
    latest_ks = await db.knowledge_states.find_one({"student_id": student_id}, sort=[("updated_at", -1)])
    kcs_raw = latest_ks.get("knowledge_components", {}) if latest_ks else {}
    theta = latest_ks.get("theta", 0.0) if latest_ks else 0.0
    theta_se = latest_ks.get("theta_se", 0.0) if latest_ks else 0.0
    updated_at = str(latest_ks.get("updated_at", get_current_time_str())) if latest_ks else get_current_time_str()
    
    kc_list = []
    for k, v in kcs_raw.items():
        kc_list.append(KnowledgeComponent(id=f"KC_{k.upper().replace(' ', '_')}", name=k, mastery=v))
        
    cursor = db.adaptive_decisions.find({"student_id": student_id}).sort("_id", 1).limit(20)
    history = await cursor.to_list(length=20)
    
    timeline = []
    for dec in history:
        timeline.append(AdaptiveHistoryItem(
            timestamp=str(dec.get("timestamp", get_current_time_str())),
            mastery_before=dec.get("mastery_before", 0.0),
            mastery_after=dec.get("mastery_after", 0.0),
            fatigue=dec.get("fatigue_score", 0.0),
            previous_difficulty=dec.get("previous_difficulty", 0.0),
            selected_difficulty=dec.get("selected_difficulty", 0.0),
            scaffold_level=dec.get("scaffold_level", 0),
            next_activity=dec.get("selected_activity", ""),
            decision=dec.get("decision_reason", ""),
            reason=dec.get("decision_reason", "")
        ))
        
    return TherapistC4AdaptiveDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C4-v2",
        feature_version="F-v2",
        knowledge_components=kc_list,
        theta=theta,
        theta_se=theta_se,
        updated_at_state=updated_at,
        history=timeline
    )
