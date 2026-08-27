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
