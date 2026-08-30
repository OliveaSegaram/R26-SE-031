from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
import httpx
import uuid
import asyncio
from datetime import datetime
import sys
from pathlib import Path as PathLib
sys.path.insert(0, str(PathLib(__file__).parent.parent.parent.parent))
from shared.database import get_db

router = APIRouter(prefix="/api/v1/learning", tags=["Unified Learning"])

class InteractionResponseModel(BaseModel):
    selected_character: str
    is_correct: bool

class TelemetryModel(BaseModel):
    first_touch_latency_ms: int
    total_round_latency_ms: int
    hesitation_count: int
    misclick_count: int
    touch_stream: List[Any] = []

class InteractionPayload(BaseModel):
    student_id: str
    session_id: str
    activity_id: str
    item_id: str
    knowledge_component_id: str = "KC_LETTER_IDENTITY"
    response: InteractionResponseModel
    telemetry: TelemetryModel
    speech: Optional[Any] = None

async def run_background_pipeline(payload: InteractionPayload, c4_result: dict, event_id: str):
    db = get_db()
    
    # 1. Save Telemetry
    telemetry_doc = {
        "event_id": event_id,
        "student_id": payload.student_id,
        "session_id": payload.session_id,
        "activity_id": payload.activity_id,
        "item_id": payload.item_id,
        "timestamp": datetime.utcnow().isoformat(),
        "is_correct": payload.response.is_correct,
        "first_touch_latency_ms": payload.telemetry.first_touch_latency_ms,
        "total_round_latency_ms": payload.telemetry.total_round_latency_ms,
        "hesitation_count": payload.telemetry.hesitation_count,
        "misclick_count": payload.telemetry.misclick_count,
        "audio_replay_count": 0
    }
    await db.telemetry_events.insert_one(telemetry_doc)

    # 2. Call C1 (Behavioral)
    # 3. Call C2 (Kinematics)
    # 4. Call C3 (XAI Fusion)
    # We mock the external ML API calls here to simulate the processing and save the structured data.
    
    # Save C1
    c1_doc = {
        "event_id": event_id,
        "student_id": payload.student_id,
        "session_id": payload.session_id,
        "timestamp": datetime.utcnow().isoformat(),
        "behavior": {
            "accuracy": 100 if payload.response.is_correct else 0,
            "median_latency_ms": payload.telemetry.total_round_latency_ms,
            "latency_std": 100,
            "latency_drift": 0.05,
            "error_rate": 0 if payload.response.is_correct else 1,
            "hesitation_rate": payload.telemetry.hesitation_count / max(1, payload.telemetry.total_round_latency_ms / 1000),
            "misclick_rate": payload.telemetry.misclick_count / max(1, payload.telemetry.total_round_latency_ms / 1000)
        },
        "fatigue": {
            "score": 0.1 # mock
        },
        "indices": {
            "visual_processing_index": 80.0,
            "phonological_task_index": 70.0,
            "motor_interaction_index": 85.0,
            "attention_stability_index": 75.0
        },
        "feature_version": "v1.0"
    }
    await db.behavioral_features.insert_one(c1_doc)
    
    # Save C2
    c2_doc = {
        "event_id": event_id,
        "student_id": payload.student_id,
        "session_id": payload.session_id,
        "timestamp": datetime.utcnow().isoformat(),
        "time_to_first_touch_ms": payload.telemetry.first_touch_latency_ms,
        "path_length": 500.0,
        "straight_line_distance": 450.0,
        "path_efficiency": 0.9,
        "mean_velocity": 200.0,
        "velocity_variance": 50.0,
        "mean_dwell_time_ms": 100.0,
        "normalized_jerk": 2.5,
        "orthographic_confusion_index": 0.2 if payload.response.is_correct else 0.8,
        "feature_version": "v1.0"
    }
    await db.kinematic_features.insert_one(c2_doc)
    
    # Save C3
    c3_doc = {
        "event_id": event_id,
        "student_id": payload.student_id,
        "session_id": payload.session_id,
        "timestamp": datetime.utcnow().isoformat(),
        "learner_profile": {
            "class_probabilities": {"Typical": 0.8, "Visual-Orthographic": 0.1, "Phonological": 0.05, "Combined": 0.05},
            "primary_pattern": "Typical",
            "confidence": 0.8,
            "modalities_used": ["C1_Acoustic", "C2_Kinematic"]
        },
        "shap_explanations": {
            "top_contributing_features": [{"feature_name": "OCI", "value": 0.2, "shap_impact": "-0.1"}]
        },
        "model_version": "C3-v1.0"
    }
    await db.learner_profiles.insert_one(c3_doc)
    
    # Save C4 Decision
    c4_doc = {
        "event_id": event_id,
        "student_id": payload.student_id,
        "session_id": payload.session_id,
        "timestamp": datetime.utcnow().isoformat(),
        "mastery_after": c4_result.get("updated_knowledge_state", {}).get(payload.knowledge_component_id, 0.5),
        "selected_difficulty": c4_result.get("next_action", {}).get("difficulty", 0.5),
        "selected_activity": c4_result.get("next_action", {}).get("next_activity", "Skill_2"),
        "scaffold_level": c4_result.get("next_action", {}).get("scaffold_level", 0),
        "decision_reason": c4_result.get("next_action", {}).get("decision", "CONTINUE"),
        "policy_version": "Policy-v1.0"
    }
    await db.adaptive_decisions.insert_one(c4_doc)
    
    # Save Speech Features and Transcriptions separately as requested
    if payload.speech:
        speech_trans_doc = {
            "speech_event_id": event_id,
            "student_id": payload.student_id,
            "session_id": payload.session_id,
            "activity_id": payload.activity_id,
            "item_id": payload.item_id,
            "expected_text": payload.speech.get("expected_text", ""),
            "transcription": payload.speech.get("transcription", ""),
            "wer": payload.speech.get("word_error_rate", 0.0),
            "stt_confidence": 1.0 - (payload.speech.get("word_error_rate") or 0.0),
            "model_version": "whisper-si-v1",
            "timestamp": datetime.utcnow().isoformat()
        }
        await db.speech_transcriptions.insert_one(speech_trans_doc)
        
        speech_feat_doc = {
            "speech_event_id": event_id,
            "student_id": payload.student_id,
            "session_id": payload.session_id,
            "activity_id": payload.activity_id,
            "item_id": payload.item_id,
            "acoustic_latency_ms": payload.speech.get("Acoustic_Latency_ms", 0),
            "voice_onset_ms": payload.speech.get("Voice_Onset_ms", 0),
            "detected_peaks": payload.speech.get("Detected_Peaks", 0),
            "expected_syllables": payload.speech.get("Expected_Syllables", 0),
            "peak_count_delta": payload.speech.get("Peak_Count_Delta", 0),
            "intra_word_silence_ratio": payload.speech.get("Intra_Word_Silence_Ratio", 0.0),
            "jitter": payload.speech.get("Local_Jitter", 0.0),
            "shimmer": payload.speech.get("Local_Shimmer", 0.0),
            "recording_quality": payload.speech.get("recording_quality", "good"),
            "analysis_confidence": 0.88 if payload.speech.get("recording_quality", "good") == "good" else 0.5,
            "feature_version": "speech-v1",
            "speech_data": payload.speech, # Kept for backward compatibility in other endpoints
            "timestamp": datetime.utcnow().isoformat()
        }
        await db.speech_features.insert_one(speech_feat_doc)


@router.post("/interaction")
async def process_interaction(payload: InteractionPayload, background_tasks: BackgroundTasks):
    db = get_db()
    event_id = str(uuid.uuid4())
    
    # Fetch latest fatigue from C1 and learner profile from C3 to inform C4
    c1 = await db.behavioral_features.find_one({"student_id": payload.student_id}, sort=[("_id", -1)])
    c3 = await db.learner_profiles.find_one({"student_id": payload.student_id}, sort=[("_id", -1)])
    
    fatigue_score = c1.get("fatigue", {}).get("score", 0.0) if c1 else 0.0
    learner_profile_dict = c3.get("learner_profile", {}).get("class_probabilities", {}) if c3 else {}
    
    c4_result = {}
    async with httpx.AsyncClient() as client:
        # Call Adaptive Tutoring (C4) synchronously
        try:
            adaptive_submit = {
                "student_id": payload.student_id,
                "session_id": payload.session_id,
                "activity_id": payload.activity_id,
                "knowledge_component_id": payload.knowledge_component_id,
                "item_id": payload.item_id,
                "is_correct": payload.response.is_correct,
                "current_session_duration_sec": payload.telemetry.total_round_latency_ms // 1000,
                "fatigue_score": fatigue_score,
                "learner_profile": learner_profile_dict
            }
            c4_resp = await client.post(
                "http://localhost:9017/update_interaction",
                json=adaptive_submit,
                timeout=5.0
            )
            if c4_resp.status_code == 200:
                c4_result = c4_resp.json()
        except Exception as e:
            print(f"C4 pipeline error: {e}")
            # Fallback
            c4_result = {
                "updated_knowledge_state": {payload.knowledge_component_id: 0.5},
                "next_action": {
                    "next_activity": payload.activity_id,
                    "next_item": payload.item_id,
                    "difficulty": 0.5,
                    "scaffold_level": 0,
                    "decision": "CONTINUE"
                }
            }

    # Dispatch background tasks for ML processing and persistence
    background_tasks.add_task(run_background_pipeline, payload, c4_result, event_id)
    
    # Return immediately to unblock learner
    return {
        "result": {
            "is_correct": payload.response.is_correct
        },
        "next_action": c4_result.get("next_action", {})
    }
