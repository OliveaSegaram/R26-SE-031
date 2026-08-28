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
        "touch_stream": payload.telemetry.touch_stream
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
    async with httpx.AsyncClient() as client:
        try:
            # Send to telemetry-analytics-v1 (C1-C3 pipeline)
            # This microservice natively saves telemetry_events, behavioral_features (C1), learner_profiles (C3)
            c1_resp = await client.post(
                "http://localhost:8025/api/v1/c1/session", 
                json=session_submit,
                timeout=10.0
            )
            if c1_resp.status_code == 201:
                c1_c3_result = c1_resp.json()
        except Exception as e:
            print(f"C1 pipeline error: {e}")

    # 2. Prepare Adaptive Tutoring Request (C4)
    # The BKT/IRT engine expects knowledge_component_id. We map item_id to KC.
    kc_id = "KC_LETTER_IDENTITY"  # simplified mapping for demo
    
    adaptive_submit = {
        "student_id": payload.student_id,
        "knowledge_component_id": kc_id,
        "is_correct": payload.response.is_correct,
        "current_session_duration_sec": payload.telemetry.total_round_latency_ms // 1000
    }

    c4_result = {}
    async with httpx.AsyncClient() as client:
        try:
            # Send to adaptive-tutoring-v1 (C4 pipeline)
            # This microservice natively saves knowledge_states and adaptive_decisions
            c4_resp = await client.post(
                "http://localhost:8017/update_interaction",
                json=adaptive_submit,
                timeout=10.0
            )
            if c4_resp.status_code == 200:
                c4_result = c4_resp.json()
        except Exception as e:
            print(f"C4 pipeline error: {e}")

    # 3. Format unified response
    
    # Safely extract values
    behavior = c1_c3_result.get("behavior", {})
    fatigue = c1_c3_result.get("fatigue", {})
    model_metadata = c1_c3_result.get("model", {})
    
    # Mocking C2 OCI extraction since it requires kinematic processor
    # In a full system, C2 would be extracted by diagnostic-fusion-v1
    
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
            "oci": 0.67,  # Placeholder until kinematic pipeline is attached
            "path_efficiency": 0.63,
            "normalized_jerk": 3.82
        },
        "c3": {
            "profile": model_metadata.get("pattern", "VISUAL_ORTHOGRAPHIC"),
            "probability": model_metadata.get("confidence", 0.71),
            "confidence": model_metadata.get("confidence", 0.71)
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
