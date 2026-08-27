from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from dependencies import get_current_user
from schemas.telemetry import TelemetrySessionSubmit
from schemas.c1 import C1Result
from services.c1.processor import process_session
from services.ml.inference import predict_c1_pattern
from repositories import telemetry_repository, c1_repository

router = APIRouter(prefix="/api/v1/c1", tags=["C1 Analytics"])

@router.post("/session", response_model=C1Result, status_code=status.HTTP_201_CREATED)
async def process_c1_session(
    payload: TelemetrySessionSubmit,
    current_user: dict = Depends(get_current_user)
):
    """
    Component 1 Canonical Pipeline:
    1. Ingest telemetry session
    2. Save raw telemetry
    3. Extract behavioral features
    4. Calculate Learner-State & Fatigue
    5. Predict Pattern (ML)
    6. Store C1 State
    """
    
    # 1. Validation & Storage
    session_data = payload.model_dump()
    events_data = session_data.pop("events", [])
    
    # Inject session_id into events for tracking
    for e in events_data:
        e["session_id"] = payload.session_id
        e["student_id"] = payload.student_id
        
    await telemetry_repository.save_session(session_data)
    await telemetry_repository.save_events(events_data)
    
    # 2. C1 Processor (Features, Indices, Quality)
    c1_partial = process_session(payload.session_id, payload.student_id, events_data)
    
    # 3. ML Inference
    model_metadata = predict_c1_pattern(c1_partial["behavior"])
    c1_partial["model"] = model_metadata
    
    # 4. Save C1 State
    await c1_repository.save_c1_state(c1_partial)
    
    return c1_partial

@router.get("/student/{student_id}/history", response_model=List[C1Result])
async def get_c1_history(
    student_id: str,
    limit: int = 5,
    current_user: dict = Depends(get_current_user)
):
    """Retrieve the recent C1 learner states for a student."""
    # Add ownership/therapist checks here in production
    states = await c1_repository.get_recent_states(student_id, limit=limit)
    return states
