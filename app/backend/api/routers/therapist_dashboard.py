from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime
from schemas.dashboards import (
    TherapistOverviewDTO,
    TherapistBehavioralDTO,
    TherapistSpeechAnalysisDTO,
    TherapistMultimodalEvidenceDTO,
    TherapistProfileDTO,
    TherapistKnowledgeDTO,
    TherapistAdaptiveDTO,
    SpeechComparisonItem,
    ShapExplanation,
    AdaptiveTimelineEvent
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
    
    if result and result[0]["total"] > 0:
        accuracy = int((result[0]["correct"] / result[0]["total"]) * 100)
        attempted = result[0]["total"]
    else:
        accuracy = 0
        attempted = 0
        
    latest_c4 = await db.adaptive_decisions.find_one({"student_id": student_id}, sort=[("_id", -1)])
    mastery = latest_c4.get("mastery_after", 0.0) if latest_c4 else 0.0
    
    status = "Developing"
    if mastery >= 0.8: status = "Advanced"
    elif mastery < 0.5: status = "Needs Support"

    return TherapistOverviewDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="All Time",
        model_version="C1-v1, C2-v1, C3-v1, C4-v1",
        feature_version="F-v1",
        accuracy=accuracy,
        attempted_items=attempted,
        fluency_status=status,
        overall_mastery=mastery
    )

@router.get("/{student_id}/reading-performance", response_model=TherapistBehavioralDTO)
async def get_therapist_reading_performance(student_id: str = Path(...)):
    db = get_db()
    pipeline = [
        {"$match": {"student_id": student_id}},
        {"$group": {"_id": None, "correct": {"$sum": {"$cond": ["$is_correct", 1, 0]}}, "total": {"$sum": 1}}}
    ]
    cursor = db.telemetry_events.aggregate(pipeline)
    result = await cursor.to_list(length=1)
    
    if result and result[0]["total"] > 0:
        accuracy = int((result[0]["correct"] / result[0]["total"]) * 100)
        attempted = result[0]["total"]
        correct = result[0]["correct"]
        incorrect = attempted - correct
        comp_rate = float(correct) / attempted
    else:
        accuracy = 0
        attempted = 0
        correct = 0
        incorrect = 0
        comp_rate = 0.0
        
    # Trend
    pipeline_trend = [
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
    cursor_trend = db.telemetry_events.aggregate(pipeline_trend)
    results_trend = await cursor_trend.to_list(length=10)
    
    trend = []
    for idx, r in enumerate(results_trend):
        acc = int((r["correct"] / r["total"]) * 100) if r["total"] > 0 else 0
        trend.append({"session": f"S{idx+1}", "accuracy": acc})

    return TherapistBehavioralDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C1-v1",
        feature_version="F-v1",
        accuracy=accuracy,
        attempted=attempted,
        correct=correct,
        incorrect=incorrect,
        completion_rate=comp_rate,
        accuracy_trend=trend
    )

@router.get("/{student_id}/speech", response_model=TherapistSpeechAnalysisDTO)
async def get_therapist_speech(student_id: str = Path(...)):
    db = get_db()
    latest_speech = await db.speech_features.find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    if not latest_speech:
        return TherapistSpeechAnalysisDTO(
            updated_at=get_current_time_str(),
            student_id=student_id,
            reporting_period="Current",
            model_version="STT-v2.1, AC-v1.4",
            feature_version="F-v2",
            stt_results=[],
            wer=0.0,
            stt_confidence=0.0,
            voice_onset_time=0.0,
            acoustic_latency=0.0,
            detected_peaks=0,
            expected_syllables=0,
            peak_count_delta=0,
            intra_word_silence_ratio=0.0,
            jitter=0.0,
            shimmer=0.0,
            recording_quality="N/A",
            acoustic_confidence=0.0,
            latency_trend=[],
            silence_trend=[]
        )
        
    s_data = latest_speech.get("speech_data", {})
    expected = s_data.get("expected_text", "")
    transcription = s_data.get("transcription", "")
    wer = s_data.get("word_error_rate", 0.0)
    if wer is None: wer = 0.0
    
    # Simple word by word match for UI
    stt_res = []
    if expected and transcription:
        exp_w = expected.split()
        rec_w = transcription.split()
        for i, ew in enumerate(exp_w):
            rw = rec_w[i] if i < len(rec_w) else "-"
            stt_res.append(SpeechComparisonItem(expected=ew, recognized=rw, result="✓" if ew == rw else "⚠"))
    
    # Trends (mocking trend calculation for simplicity, can expand later)
    latency_trend = [{"session": "Latest", "latency": s_data.get("Acoustic_Latency_ms", 0)}]
    silence_trend = [{"session": "Latest", "silence": s_data.get("Intra_Word_Silence_Ratio", 0.0)}]

    return TherapistSpeechAnalysisDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="STT-v2.1, AC-v1.4",
        feature_version="F-v2",
        stt_results=stt_res,
        wer=wer,
        stt_confidence=1.0 - wer,
        voice_onset_time=s_data.get("Voice_Onset_ms", 0) / 1000.0,
        acoustic_latency=s_data.get("Acoustic_Latency_ms", 0) / 1000.0,
        detected_peaks=s_data.get("Detected_Peaks", 0),
        expected_syllables=s_data.get("Expected_Syllables", 0),
        peak_count_delta=s_data.get("Peak_Count_Delta", 0),
        intra_word_silence_ratio=s_data.get("Intra_Word_Silence_Ratio", 0.0),
        jitter=s_data.get("Local_Jitter", 0.0),
        shimmer=s_data.get("Local_Shimmer", 0.0),
        recording_quality=s_data.get("recording_quality", "Unknown"),
        acoustic_confidence=1.0 if s_data.get("recording_quality") == "good" else 0.5,
        latency_trend=latency_trend,
        silence_trend=silence_trend
    )

@router.get("/{student_id}/multimodal-evidence", response_model=TherapistMultimodalEvidenceDTO)
async def get_multimodal_evidence(student_id: str = Path(...)):
    db = get_db()
    latest_speech = await db.speech_features.find_one({"student_id": student_id}, sort=[("_id", -1)])
    latest_c4 = await db.adaptive_decisions.find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    s_data = latest_speech.get("speech_data", {}) if latest_speech else {}
    mastery = latest_c4.get("mastery_after", 0.0) if latest_c4 else 0.0
    
    status = "Developing"
    if mastery >= 0.8: status = "Advanced"
    elif mastery < 0.5: status = "Needs Support"
    
    wer = s_data.get("word_error_rate", 0.0)
    if wer is None: wer = 0.0

    return TherapistMultimodalEvidenceDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Latest Reading Event",
        model_version="Fusion-v1",
        feature_version="F-v1",
        expected_text=s_data.get("expected_text", "N/A"),
        stt_text=s_data.get("transcription", "N/A"),
        wer=wer,
        stt_confidence=1.0 - wer,
        latency=s_data.get("Acoustic_Latency_ms", 0) / 1000.0,
        silence_ratio=s_data.get("Intra_Word_Silence_Ratio", 0.0),
        peak_delta=s_data.get("Peak_Count_Delta", 0),
        jitter=s_data.get("Local_Jitter", 0.0),
        shimmer=s_data.get("Local_Shimmer", 0.0),
        quality=s_data.get("recording_quality", "N/A"),
        combined_fluency=status,
        evidence_quality="Good" if s_data.get("recording_quality") == "good" else "Poor",
        interpretation="Analysis based on latest reading event telemetry."
    )

@router.get("/{student_id}/profile", response_model=TherapistProfileDTO)
async def get_therapist_profile(student_id: str = Path(...)):
    db = get_db()
    latest_c3 = await db.learner_profiles.find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    c3_data = latest_c3.get("learner_profile", {}) if latest_c3 else {}
    probs = c3_data.get("class_probabilities", {"Typical": 0.5, "Visual-Orthographic": 0.2, "Phonological": 0.2, "Combined": 0.1})
    pattern = c3_data.get("primary_pattern", "Typical")
    
    return TherapistProfileDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C3-v2",
        feature_version="F-v2",
        selected_pattern=pattern,
        probabilities=probs,
        shap_values=[
            ShapExplanation(feature="WER", contribution=0.24),
            ShapExplanation(feature="Intra-word silence", contribution=0.18),
            ShapExplanation(feature="Acoustic latency", contribution=0.14)
        ],
        interpretation=f"Current predicted learning pattern is {pattern}."
    )

@router.get("/{student_id}/knowledge", response_model=TherapistKnowledgeDTO)
async def get_therapist_knowledge(student_id: str = Path(...)):
    return TherapistKnowledgeDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="BKT-v1",
        feature_version="F-v1",
        knowledge_components={
            "Reading Fluency": 0.54,
            "Word Recognition": 0.68,
            "Sentence Reading": 0.42
        },
        mastery_trend=[]
    )

@router.get("/{student_id}/adaptive-history", response_model=TherapistAdaptiveDTO)
async def get_therapist_adaptive_history(student_id: str = Path(...)):
    db = get_db()
    latest_c4 = await db.adaptive_decisions.find_one({"student_id": student_id}, sort=[("_id", -1)])
    
    return TherapistAdaptiveDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Current",
        model_version="C4-v2",
        feature_version="F-v2",
        learner_ability=0.5,
        item_difficulty=latest_c4.get("selected_difficulty", 0.5) if latest_c4 else 0.5,
        fatigue=0.2,
        decision_timeline=[
            {"step": "Selected Activity", "value": latest_c4.get("selected_activity", "Unknown") if latest_c4 else "Unknown"},
            {"step": "Decision", "value": latest_c4.get("decision_reason", "CONTINUE") if latest_c4 else "CONTINUE"}
        ]
    )
