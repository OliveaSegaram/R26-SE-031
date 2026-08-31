from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime
from schemas.dashboards import (
    TherapistOverviewDTO,
    TherapistC1BehavioralDTO,
    KCPerformance,
    ErrorDistribution,
    BehavioralTrends,
    TherapistC2SpeechDTO,
    SpeechLatest,
    SpeechTrends,
    TherapistC3ProfileDTO,
    ShapExplanation,
    TherapistC4AdaptiveDTO,
    KnowledgeComponent,
    KnowledgeComponent,
    AdaptiveHistoryItem
)
import sys
from pathlib import Path as PathLib
sys.path.insert(0, str(PathLib(__file__).parent.parent.parent.parent))
from shared.database import get_db
from utils.research_report_generator import generate_research_pdf

router = APIRouter(
    prefix="/api/v1/therapist/students",
    tags=["Therapist Dashboard"]
)

def get_current_time_str() -> str:
    return datetime.utcnow().isoformat() + "Z"

@router.get("/{student_id}/overview", response_model=TherapistOverviewDTO)
async def get_therapist_overview(student_id: str = Path(...)):
    db = get_db()
    
    # Check data availability
    c1_count = await db.session_summaries.count_documents({"student_id": student_id})
    c2_count = await db.speech_features.count_documents({"student_id": student_id})
    c3_count = await db.learner_profiles.count_documents({"student_id": student_id})
    c4_count = await db.adaptive_decisions.count_documents({"student_id": student_id})
    
    c1_available = c1_count > 0
    c2_available = c2_count > 0
    c3_available = c3_count > 0
    c4_available = c4_count > 0

    sessions_list = await db.session_summaries.distinct("session_id", {"student_id": student_id})
    completed_sessions = len(sessions_list)

    latest_summary = await db.session_summaries.find_one({"student_id": student_id}, sort=[("completed_at", -1)])
    
    accuracy = 0.0
    fatigue_status = "N/A"
    last_active = get_current_time_str()
    feature_version = "c1-v2"
    attempted = 0
    
    if latest_summary:
        overall = latest_summary.get("overall", {})
        accuracy = overall.get("accuracy", 0.0)
        attempted = latest_summary.get("total_trials", 0)
        
        fatigue_val = latest_summary.get("behavioral_fatigue_proxy")
        if fatigue_val is None:
            fatigue_status = "N/A"
        elif fatigue_val < 0.35:
            fatigue_status = "Low"
        elif fatigue_val <= 0.65:
            fatigue_status = "Moderate"
        else:
            fatigue_status = "Elevated"
            
        last_active = latest_summary.get("completed_at", last_active)
        feature_version = latest_summary.get("feature_version", "c1-v2")
        
    latest_ks = await db.knowledge_states.find_one({"student_id": student_id}, sort=[("updated_at", -1)])
    mastery = 0.0
    if latest_ks and "knowledge_state" in latest_ks:
        kcs = latest_ks["knowledge_state"]
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
        
    latest_decision = await db.adaptive_decisions.find_one({"student_id": student_id}, sort=[("_id", -1)])
    recommendation = "No recommendation available yet."
    if latest_decision and "decision_reason" in latest_decision:
        recommendation = latest_decision["decision_reason"]
            
    return TherapistOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="V1",
        feature_version=feature_version,
        accuracy=accuracy,
        attempted_items=attempted,
        completed_sessions=completed_sessions,
        reading_fluency_status=status,
        overall_mastery=mastery,
        current_pattern=pattern,
        pattern_confidence=pattern_conf,
        fatigue_status=fatigue_status,
        last_active=last_active,
        c1_available=c1_available,
        c2_available=c2_available,
        c3_available=c3_available,
        c4_available=c4_available,
        latest_recommendation=recommendation
    )

@router.get("/{student_id}/c1-behavioral", response_model=TherapistC1BehavioralDTO)
async def get_therapist_c1_behavioral(student_id: str = Path(...)):
    db = get_db()
    # Presentation mapping only: features are derived once by C1 ingestion.
    cursor = db.session_summaries.find({"student_id": student_id}).sort("completed_at", -1).limit(10)
    history = await cursor.to_list(length=10)
    latest = history[0] if history else {}
    kcs = latest.get("knowledge_components") or {}
    overall = latest.get("overall") or {}
    errors = latest.get("error_profile") or {}
    fatigue = latest.get("behavioral_fatigue_proxy")
    kc_ids = (
        "KC_AKSHARA_IDENTITY", "KC_PHONEME_GRAPHEME",
        "KC_WORD_RECOGNITION", "KC_SPELLING_SEQUENCE",
        "KC_SENTENCE_LANGUAGE", "KC_READING_COMPREHENSION",
        "KC_VISUAL_SUPPORT",
    )
    error_keys = {
        "visual_confusion": "visual_confusion_rate",
        "phonological_confusion": "phonological_confusion_rate",
        "sequence_error": "sequence_error_rate",
        "unknown_error": "unknown_error_rate",
    }
    # Without incorrect observations the error composition is undefined.
    has_errors = overall.get("error_rate") is not None and overall["error_rate"] > 0

    def trend(field, *, fatigue_field=False):
        result = []
        for state in reversed(history):
            value = state.get("behavioral_fatigue_proxy") if fatigue_field else (
                (state.get("overall") or {}).get(field)
                if state.get("knowledge_state") else None
            )
            result.append({"session": state["session_id"], "value": value})
        return result

    return TherapistC1BehavioralDTO(
        updated_at=latest.get("completed_at", get_current_time_str()),
        student_id=student_id,
        session_id=latest.get("session_id"),
        reporting_period="Latest session",
        model_version="descriptive",
        feature_version=latest.get("feature_version", "c1-v2"),
        last_data_at=latest.get("completed_at"),
        first_attempt_accuracy=overall.get("accuracy"),
        median_response_latency_ms=overall.get("median_response_latency_ms"),
        retry_rate=overall.get("retry_rate"),
        mean_attempts_per_round=overall.get("mean_attempts_per_round"),
        median_time_to_correct_ms=overall.get("median_time_to_correct_ms"),
        correction_rate=overall.get("correction_rate"),
        behavioral_fatigue_proxy=fatigue,
        kc_performance=KCPerformance(**{kc: (kcs.get(kc) or {}).get("accuracy") for kc in kc_ids}),
        error_distribution=ErrorDistribution(**{name: errors.get(key) if has_errors else None for name, key in error_keys.items()}),
        trends=BehavioralTrends(
            accuracy=trend("accuracy"),
            latency=trend("median_response_latency_ms"),
            fatigue=trend("", fatigue_field=True),
        ),
    )

@router.get("/{student_id}/c2-speech", response_model=TherapistC2SpeechDTO)
async def get_therapist_c2_speech(student_id: str = Path(...)):
    db = get_db()
    
    latest_speech = await db.speech_features.find_one({"student_id": student_id}, sort=[("_id", -1)])
    latest_speech = latest_speech or {}
    
    expected = latest_speech.get("expected_text", "")
    recognized = latest_speech.get("recognized_text", "")
    wer = latest_speech.get("word_error_rate", 0.0)
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
    wer_trend = []
    
    for idx, t in enumerate(trends_res):
        sess_label = t.get("session_id") or f"S{idx+1}"
        lat_trend.append({"session": sess_label, "value": t.get("acoustic_latency_ms", 0)})
        sil_trend.append({"session": sess_label, "value": t.get("intra_word_silence_ratio", 0.0)})
        peak_trend.append({"session": sess_label, "value": t.get("syllabic_event_mismatch", 0)})
        wer_trend.append({"session": sess_label, "value": t.get("word_error_rate", 0.0)})
        
    latest_obj = SpeechLatest(
        expected_text=expected,
        transcription=recognized,
        wer=wer or 0.0,
        stt_confidence=stt_conf,
        acoustic_latency_ms=latest_speech.get("acoustic_latency_ms", 0.0),
        voice_onset_ms=latest_speech.get("voice_onset_ms", 0.0),
        peak_delta=latest_speech.get("syllabic_event_mismatch", 0),
        silence_ratio=latest_speech.get("intra_word_silence_ratio", 0.0),
        jitter=latest_speech.get("local_jitter", 0.0),
        shimmer=latest_speech.get("local_shimmer", 0.0),
        recording_quality=latest_speech.get("recording_quality", "Unknown")
    )
    
    trends_obj = SpeechTrends(
        accuracy=[], # Optional placeholder
        wer=wer_trend,
        latency=lat_trend,
        silence_ratio=sil_trend,
        peak_delta=peak_trend
    )
    
    created_at_str = latest_speech.get("created_at")
    if isinstance(created_at_str, datetime):
        created_at_str = created_at_str.isoformat() + "Z"
    else:
        created_at_str = str(created_at_str) if created_at_str else None
        
    return TherapistC2SpeechDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="V1",
        feature_version="V1",
        last_data_at=created_at_str,
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
        try:
            val_str = str(feature.get("shap_impact", "0.0")).replace("+", "")
            impact = abs(float(val_str))
        except ValueError:
            impact = 0.0
            
        shap_list.append(ShapExplanation(
            feature=feature.get("feature_name", ""),
            contribution=impact,
            observed_value=feature.get("observed_value"),
            direction=feature.get("direction")
        ))
        
    created_at_str = latest_c3.get("created_at") if latest_c3 else latest_c3.get("timestamp") if latest_c3 else None
    if isinstance(created_at_str, datetime):
        created_at_str = created_at_str.isoformat() + "Z"
    else:
        created_at_str = str(created_at_str) if created_at_str else None
        
    return TherapistC3ProfileDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C3-v1.0",
        feature_version="F-v1",
        last_data_at=created_at_str,
        primary_pattern=pattern,
        probabilities=probs,
        confidence=conf,
        modalities_used=mods,
        shap_explanations=shap_list,
        llm_summary=latest_c3.get("llm_summary") if latest_c3 else None,
        llm_recommendations=latest_c3.get("llm_recommendations") if latest_c3 else None
    )

@router.get("/{student_id}/c4-adaptive", response_model=TherapistC4AdaptiveDTO)
async def get_therapist_c4_adaptive(student_id: str = Path(...)):
    db = get_db()
    
    latest_ks = await db.knowledge_states.find_one({"student_id": student_id}, sort=[("updated_at", -1)])
    kcs_raw = latest_ks.get("knowledge_state", {}) if latest_ks else {}
    theta = latest_ks.get("theta_estimate", 0.0) if latest_ks else 0.0
    theta_se = latest_ks.get("theta_se", 0.0) if latest_ks else 0.0
    updated_at = str(latest_ks.get("updated_at", get_current_time_str())) if latest_ks else get_current_time_str()
    
    kc_list = []
    
    # Mapping for raw KC IDs to human readable names
    kc_name_map = {
        "KC_AKSHARA_IDENTITY": "Akshara Identity",
        "KC_PHONEME_GRAPHEME": "Phoneme-Grapheme Mapping",
        "KC_WORD_RECOGNITION": "Word Recognition",
        "KC_SPELLING_SEQUENCE": "Spelling Sequence",
        "KC_SENTENCE_LANGUAGE": "Sentence & Language",
        "KC_READING_COMPREHENSION": "Reading Comprehension",
        "KC_VISUAL_SUPPORT": "Visual Support"
    }
    
    for k, v in kcs_raw.items():
        # Fallback to Title Cased string if not in map
        mapped_name = kc_name_map.get(k.upper().replace(' ', '_'), k.title())
        kc_list.append(KnowledgeComponent(id=f"{k.upper().replace(' ', '_')}", name=mapped_name, mastery=v))
        
    cursor = db.adaptive_decisions.find({"student_id": student_id}).sort("_id", 1).limit(20)
    history = await cursor.to_list(length=20)
    
    timeline = []
    for dec in history:
        timeline.append(AdaptiveHistoryItem(
            timestamp=str(dec.get("created_at", get_current_time_str())),
            mastery_before=dec.get("mastery_before", 0.0),
            mastery_after=dec.get("mastery_after", 0.0),
            fatigue=dec.get("behavioral_fatigue_indicator", 0.0),
            previous_difficulty=dec.get("previous_difficulty", 0.0),
            selected_difficulty=dec.get("selected_difficulty", 0.0),
            scaffold_level=dec.get("scaffold_level", 0),
            next_activity=dec.get("next_activity", ""),
            decision=dec.get("decision", ""),
            reason=dec.get("decision_reason", "")
        ))
        
    return TherapistC4AdaptiveDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C4-v2",
        feature_version="F-v2",
        last_data_at=updated_at,
        knowledge_components=kc_list,
        theta=theta,
        theta_se=theta_se,
        updated_at_state=updated_at,
        history=timeline
    )

@router.get("/{student_id}/research-summary")
async def get_therapist_research_summary(student_id: str = Path(...)):
    """Aggregation endpoint for Therapist Dashboard that fetches all 4 components."""
    # Run all 4 endpoint functions internally
    c1 = await get_therapist_c1_behavioral(student_id)
    c2 = await get_therapist_c2_speech(student_id)
    c3 = await get_therapist_c3_profile(student_id)
    c4 = await get_therapist_c4_adaptive(student_id)
    
    return {
        "student_id": student_id,
        "c1_behavioral": c1.dict(),
        "c2_speech": c2.dict(),
        "c3_profile": c3.dict(),
        "c4_adaptive": c4.dict(),
        "generated_at": get_current_time_str()
    }

@router.get("/{student_id}/report/pdf")
async def get_therapist_research_pdf(student_id: str = Path(...)):
    """Generates a downloadable PDF report incorporating C1-C4 data."""
    try:
        c1 = await get_therapist_c1_behavioral(student_id)
        c2 = await get_therapist_c2_speech(student_id)
        c3 = await get_therapist_c3_profile(student_id)
        c4 = await get_therapist_c4_adaptive(student_id)
        
        pdf_bytes = generate_research_pdf(
            student_id, 
            c1.dict(), 
            c2.dict(), 
            c3.dict(), 
            c4.dict()
        )
        
        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename=Sipsara_Report_{student_id}.pdf"
            }
        )
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

