"""FastAPI router for Task 02 early identification."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from adaptive_engine import AdaptiveSession, list_curriculum

router = APIRouter(prefix="/api/v1/task02", tags=["task02"])


class StartSessionPayload(BaseModel):
    student_id: str = "guest"


class AnswerPayload(BaseModel):
    session_id: str
    answer: str


@router.get("/curriculum")
def get_curriculum():
    return list_curriculum()


@router.post("/session/start")
def start_session(payload: StartSessionPayload):
    session = AdaptiveSession.create(student_id=payload.student_id)
    question = AdaptiveSession.next_question(session["session_id"])
    return {**session, **question}


@router.get("/session/{session_id}/next")
def next_question(session_id: str):
    try:
        return AdaptiveSession.next_question(session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")


@router.post("/session/answer")
def submit_answer(payload: AnswerPayload):
    try:
        return AdaptiveSession.submit(payload.session_id, payload.answer)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session or question not found")


@router.get("/session/{session_id}")
def get_session(session_id: str):
    session = AdaptiveSession.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session
