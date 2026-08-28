from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import httpx
import uuid
from datetime import datetime

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
    response: InteractionResponseModel
    telemetry: TelemetryModel
    speech: Optional[Any] = None

@router.post("/interaction")
async def process_interaction(payload: InteractionPayload):
    """
    The unified C1-C4 pipeline API Gateway.
    Raw learner interaction -> C1/C2/C3/C4 -> persisted results -> dashboard APIs
    """
    # 1. Prepare Telemetry Event for C1-C3 microservice
    event_id = str(uuid.uuid4())
    telemetry_event = {
        "event_id": event_id,
        "item_id": payload.item_id,
        "activity_name": payload.activity_id,
        "round_number": 1,
        "is_correct": payload.response.is_correct,
        "first_touch_latency_ms": payload.telemetry.first_touch_latency_ms,
        "total_round_latency_ms": payload.telemetry.total_round_latency_ms,
        "hesitation_count": payload.telemetry.hesitation_count,
        "misclick_count": payload.telemetry.misclick_count,
        "target_stimulus": None, # Should be fetched from item bank
        "selected_stimulus": payload.response.selected_character,
        "touch_path": payload.telemetry.touch_stream
    }
    
    session_submit = {
        "student_id": payload.student_id,
        "session_id": payload.session_id,
        "skill_id": payload.activity_id,
        "activity_id": payload.activity_id,
        "session_duration_seconds": payload.telemetry.total_round_latency_ms // 1000,
        "events": [telemetry_event]
    }

    c1_c3_result = {}
    c2_result = {}
    c3_result = {}
    c4_result = {}
    
    async with httpx.AsyncClient() as client:
        # 1 & 2. Call Telemetry Analytics (C1 and C2)
        try:
            c1_resp = await client.post(
                "http://localhost:8025/api/v1/c1/session", 
                json=session_submit,
                timeout=10.0
            )
            if c1_resp.status_code == 201:
                c1_c3_result = c1_resp.json()
                
            # TODO: Add specific C2 call when the endpoint is exposed, mocking for now as requested
            c2_result = {
                "oci": 0.67,
                "path_efficiency": 0.63,
                "normalized_jerk": 3.82
            }
        except Exception as e:
            print(f"C1/C2 pipeline error: {e}")

        # 3 & 4. Call Diagnostic Fusion (C3)
        if c1_c3_result:
            try:
                c3_payload = {
                    "student_id": payload.student_id,
                    "student_age_months": 72,
                    "c1_audio_vector": {
                        "acoustic_latency_ms": 500,
                        "peak_count_delta": 0,
                        "intra_word_silence_ratio": 0.1
                    },
                    "c2_kinematic_vector": {
                        "time_to_first_touch_ms": c1_c3_result.get("behavior", {}).get("mean_first_touch_latency_ms", 1000),
                        "orthographic_confusion_index": c2_result["oci"],
                        "path_efficiency_ratio": c2_result["path_efficiency"],
                        "dimensionless_jerk": c2_result["normalized_jerk"],
                        "mean_dwell_time_ms": 200
                    }
                }
                c3_resp = await client.post(
                    "http://localhost:8016/diagnose",
                    json=c3_payload,
                    timeout=10.0
                )
                if c3_resp.status_code == 200:
                    c3_result = c3_resp.json()
            except Exception as e:
                print(f"C3 pipeline error: {e}")

        # 5. Call Adaptive Tutoring (C4)
        kc_id = "KC_LETTER_IDENTITY"
        try:
            adaptive_submit = {
                "student_id": payload.student_id,
                "knowledge_component_id": kc_id,
                "is_correct": payload.response.is_correct,
                "current_session_duration_sec": payload.telemetry.total_round_latency_ms // 1000,
                "fatigue_score": c1_c3_result.get("fatigue", {}).get("score", 0.0)
            }
            c4_resp = await client.post(
                "http://localhost:8017/update_interaction",
                json=adaptive_submit,
                timeout=10.0
            )
            if c4_resp.status_code == 200:
                c4_result = c4_resp.json()
        except Exception as e:
            print(f"C4 pipeline error: {e}")

    # Format unified response
    behavior = c1_c3_result.get("behavior", {})
    fatigue = c1_c3_result.get("fatigue", {})
    
    response = {
        "result": {
            "is_correct": payload.response.is_correct
        },
        "c1": {
            "accuracy": behavior.get("accuracy", 0 if not payload.response.is_correct else 100),
            "latency_ms": behavior.get("mean_latency_ms", payload.telemetry.total_round_latency_ms),
            "fatigue_score": fatigue.get("score", 0.0)
        },
        "c2": {
            "oci": c2_result.get("oci", 0.0),
            "path_efficiency": c2_result.get("path_efficiency", 1.0),
            "normalized_jerk": c2_result.get("normalized_jerk", 0.0)
        },
        "c3": {
            "profile": c3_result.get("clinical_subtype", "Unknown"),
            "probability": c3_result.get("risk_score", 0.0),
            "confidence": 0.85
        },
        "c4": {
            "mastery": c4_result.get("updated_knowledge_state", {}).get(kc_id, 0.5),
            "next_item_id": c4_result.get("next_action", {}).get("next_kc_id", "S2A1R04"),
            "difficulty": 0.45,
            "scaffold_level": c4_result.get("next_action", {}).get("scaffold_level", 0),
            "session_decision": "TERMINATE" if c4_result.get("next_action", {}).get("terminate_session", False) else "CONTINUE"
        }
    }
    
    return response
