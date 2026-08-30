from pydantic import BaseModel
from typing import List, Dict, Any, Optional

class APIResponseBase(BaseModel):
    updated_at: str
    student_id: str
    reporting_period: str

class MLResponseBase(APIResponseBase):
    model_version: str
    feature_version: str
    confidence: Optional[float] = None

# ==========================================
# PARENT DASHBOARD DTOs
# ==========================================

class ParentOverviewDTO(APIResponseBase):
    accuracy: int
    practice_time_minutes: int
    sessions_completed: int
    reading_progress: str

class ParentReadingFluencyDTO(APIResponseBase):
    fluency_status: str
    fluency_score: float

class ParentReadingProgressDTO(APIResponseBase):
    accuracy_trend: List[Dict[str, Any]] # [{"session": "S1", "accuracy": 78}, ...]

class ParentLearningPatternDTO(APIResponseBase):
    observation: str
    recommended_practices: List[str]

class ActivityHistoryItem(BaseModel):
    session_date: str
    activity_name: str
    accuracy: int
    duration_minutes: int

class ParentActivityHistoryDTO(APIResponseBase):
    history: List[ActivityHistoryItem]

# ==========================================
# THERAPIST DASHBOARD DTOs (C1-C4 Architecture)
# ==========================================

class TherapistOverviewDTO(MLResponseBase):
    accuracy: float
    attempted_items: int
    completed_sessions: int
    reading_fluency_status: str
    overall_mastery: float
    current_pattern: str
    pattern_confidence: float
    fatigue_status: str
    last_active: str

class BehavioralIndices(BaseModel):
    visual_processing: float
    phonological_tasks: float
    motor_interaction: float
    attention_stability: float

class BehavioralTrends(BaseModel):
    accuracy: List[Dict[str, Any]]
    latency: List[Dict[str, Any]]
    fatigue: List[Dict[str, Any]]

class TherapistC1BehavioralDTO(MLResponseBase):
    accuracy: float
    median_latency_ms: float
    latency_variability: float
    latency_drift: float
    error_rate: float
    error_drift: float
    hesitation_rate: float
    misclick_rate: float
    audio_replay_rate: float
    fatigue_score: float
    indices: BehavioralIndices
    trends: BehavioralTrends

class SpeechLatest(BaseModel):
    expected_text: str
    transcription: str
    wer: float
    stt_confidence: float
    acoustic_latency_ms: float
    voice_onset_ms: float
    peak_delta: int
    silence_ratio: float
    jitter: float
    shimmer: float
    recording_quality: str

class SpeechTrends(BaseModel):
    accuracy: List[Dict[str, Any]]
    wer: List[Dict[str, Any]]
    latency: List[Dict[str, Any]]
    silence_ratio: List[Dict[str, Any]]
    peak_delta: List[Dict[str, Any]]

class TherapistC2SpeechDTO(MLResponseBase):
    latest: SpeechLatest
    trends: SpeechTrends

class ShapExplanation(BaseModel):
    feature: str
    contribution: float

class TherapistC3ProfileDTO(MLResponseBase):
    primary_pattern: str
    probabilities: Dict[str, float]
    confidence: float
    modalities_used: List[str]
    shap_explanations: List[ShapExplanation]

class KnowledgeComponent(BaseModel):
    id: str
    name: str
    mastery: float

class AdaptiveHistoryItem(BaseModel):
    timestamp: str
    mastery_before: float
    mastery_after: float
    fatigue: float
    previous_difficulty: float
    selected_difficulty: float
    scaffold_level: int
    next_activity: str
    decision: str
    reason: str

class TherapistC4AdaptiveDTO(MLResponseBase):
    knowledge_components: List[KnowledgeComponent]
    theta: float
    theta_se: float
    updated_at: str
    history: List[AdaptiveHistoryItem]
