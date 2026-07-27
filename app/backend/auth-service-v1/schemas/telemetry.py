from pydantic import BaseModel
from typing import Optional, List

class TelemetryEvent(BaseModel):
    activity_name: str
    round_number: Optional[int] = None
    is_correct: bool
    timestamp: str
    time_since_start_ms: int

class TelemetrySessionSubmit(BaseModel):
    student_id: str
    session_duration_seconds: int
    events: List[TelemetryEvent]
