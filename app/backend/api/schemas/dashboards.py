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

class KCPerformance(BaseModel):
    KC_AKSHARA_IDENTITY: Optional[float] = None
    KC_PHONEME_GRAPHEME: Optional[float] = None
    KC_WORD_RECOGNITION: Optional[float] = None
    KC_SPELLING_SEQUENCE: Optional[float] = None
    KC_SENTENCE_LANGUAGE: Optional[float] = None
    KC_READING_COMPREHENSION: Optional[float] = None
    KC_VISUAL_SUPPORT: Optional[float] = None

class ErrorDistribution(BaseModel):
    visual_confusion: Optional[float] = None
    phonological_confusion: Optional[float] = None
    sequence_error: Optional[float] = None
    unknown_error: Optional[float] = None

class BehavioralTrends(BaseModel):
    accuracy: List[Dict[str, Any]]
    latency: List[Dict[str, Any]]
    fatigue: List[Dict[str, Any]]

class TherapistC1BehavioralDTO(MLResponseBase):
    session_id: Optional[str] = None
    data_source: str = "session_summaries"
    first_attempt_accuracy: Optional[float] = None
    median_response_latency_ms: Optional[float] = None
    retry_rate: Optional[float] = None
    mean_attempts_per_round: Optional[float] = None
    median_time_to_correct_ms: Optional[float] = None
    correction_rate: Optional[float] = None
    behavioral_fatigue_proxy: Optional[float] = None
    kc_performance: KCPerformance
    error_distribution: ErrorDistribution
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
