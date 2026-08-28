from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from dependencies import get_current_user
from schemas.telemetry import TelemetrySessionSubmit
from schemas.c1 import (
    C1Result, ParentC1Summary, TherapistC1State, 
    C1TrendPoint, C1SessionSummary
)
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
    states = await c1_repository.get_recent_states(student_id, limit=limit)
    return states

@router.get("/students/{student_id}/summary", response_model=ParentC1Summary)
async def get_student_summary(student_id: str, current_user: dict = Depends(get_current_user)):
    """Parent dashboard endpoint."""
    summary = await c1_repository.get_parent_summary(student_id)
    if not summary:
        raise HTTPException(status_code=404, detail="No analytics found for this student")
    return summary

@router.get("/students/{student_id}/state", response_model=TherapistC1State)
async def get_student_state(student_id: str, current_user: dict = Depends(get_current_user)):
    """Therapist dashboard endpoint (latest full state)."""
    states = await c1_repository.get_recent_states(student_id, limit=1)
    if not states:
        raise HTTPException(status_code=404, detail="No analytics found for this student")
    state = states[0]
    state['updated_at'] = state.get('_id').generation_time if state.get('_id') else None
    return state

@router.get("/students/{student_id}/trend", response_model=List[C1TrendPoint])
async def get_student_trend(student_id: str, current_user: dict = Depends(get_current_user)):
    """Trend charts endpoint."""
    return await c1_repository.get_c1_trend(student_id)

@router.get("/students/{student_id}/sessions", response_model=List[C1SessionSummary])
async def get_student_sessions(student_id: str, current_user: dict = Depends(get_current_user)):
    """Session history list endpoint."""
    return await c1_repository.get_c1_sessions(student_id)

@router.get("/sessions/{session_id}", response_model=C1Result)
async def get_session_detail(session_id: str, current_user: dict = Depends(get_current_user)):
    """Specific session detailed view endpoint."""
    session = await c1_repository.get_c1_state_by_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session
