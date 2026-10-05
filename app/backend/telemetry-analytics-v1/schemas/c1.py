from pydantic import BaseModel, Field
from typing import Optional, Dict

class BehavioralFeatures(BaseModel):
    accuracy: Optional[float] = None
    mean_latency_ms: Optional[float] = None
    median_latency_ms: Optional[float] = None
    latency_std_ms: Optional[float] = None
    mean_first_touch_latency_ms: Optional[float] = None
    hesitation_rate: Optional[float] = None
    misclick_rate: Optional[float] = None
    replay_rate: Optional[float] = None
    completion_rate: Optional[float] = None
    latency_drift: Optional[float] = None
    error_drift: Optional[float] = None
    hesitation_drift: Optional[float] = None
    accuracy_slope: Optional[float] = None
    total_questions: Optional[int] = 0
    correct_answers: Optional[int] = 0
    hesitation_count: Optional[int] = 0
    misclick_count: Optional[int] = 0
    replay_count: Optional[int] = 0

class LearnerIndices(BaseModel):
    visual_processing_index: Optional[float] = None
    phonological_task_index: Optional[float] = None
    motor_interaction_index: Optional[float] = None
    attention_stability_index: Optional[float] = None

class FatigueState(BaseModel):
    score: float = Field(default=0.0)
    state: str = Field(default="LOW", description="LOW, MODERATE, HIGH, VERY_HIGH")

class InteractionState(BaseModel):
    score: float = Field(default=0.0)
    state: str = Field(default="ENGAGED", description="ENGAGED, MODERATE_LOAD, HIGH_LOAD")

class QualityMetrics(BaseModel):
    events_received: int
    events_valid: int
    events_invalid: int
    missing_feature_rate: float
    quality_score: float

class ModelMetadata(BaseModel):
    model_name: str
    model_version: str
    feature_schema_version: str
    predicted_pattern: Optional[str] = None
    probabilities: Optional[Dict[str, float]] = None
    confidence: Optional[float] = None
    model_used: Optional[str] = None

class C1Result(BaseModel):
    student_id: str
    session_id: str
    behavior: BehavioralFeatures
    indices: LearnerIndices
    fatigue: FatigueState
    interaction_state: InteractionState
    quality: QualityMetrics
    model: ModelMetadata

from datetime import datetime

class ParentC1Summary(BaseModel):
    student_id: str
    overall_progress: int
    accuracy: int
    response_speed: str
    attention: str
    fatigue: str
    learning_observations: list[str] = Field(default_factory=list)
    recommended_practice: list[str] = Field(default_factory=list)
    updated_at: datetime

class TherapistC1State(C1Result):
    updated_at: Optional[datetime] = None

class C1TrendPoint(BaseModel):
    session_id: str
    session_index: int
    accuracy: float
    median_latency_ms: float
    fatigue_score: float
    hesitation_rate: float
    timestamp: datetime

class C1SessionSummary(BaseModel):
    session_id: str
    session_index: int
    accuracy: float
    median_latency_ms: float
    hesitation_rate: float
    fatigue_score: float
    timestamp: datetime
