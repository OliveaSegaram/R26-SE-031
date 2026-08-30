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
# THERAPIST DASHBOARD DTOs
# ==========================================

class TherapistOverviewDTO(MLResponseBase):
    accuracy: int
    attempted_items: int
    fluency_status: str
    overall_mastery: float

class TherapistBehavioralDTO(MLResponseBase):
    accuracy: int
    attempted: int
    correct: int
    incorrect: int
    completion_rate: float
    accuracy_trend: List[Dict[str, Any]] # [{"session": "SES001", "accuracy": 75}]

class SpeechComparisonItem(BaseModel):
    expected: str
    recognized: str
    result: str # "✓" or "⚠"

class TherapistSpeechAnalysisDTO(MLResponseBase):
    # STT Results
    stt_results: List[SpeechComparisonItem]
    wer: float
    stt_confidence: float
    # Acoustic Results
    voice_onset_time: float
    acoustic_latency: float
    detected_peaks: int
    expected_syllables: int
    peak_count_delta: int
    intra_word_silence_ratio: float
    jitter: float
    shimmer: float
    recording_quality: str
    acoustic_confidence: float
    # Charts
    latency_trend: List[Dict[str, Any]]
    silence_trend: List[Dict[str, Any]]

class TherapistMultimodalEvidenceDTO(MLResponseBase):
    expected_text: str
    stt_text: str
    wer: float
    stt_confidence: float
    latency: float
    silence_ratio: float
    peak_delta: int
    jitter: float
    shimmer: float
    quality: str
    combined_fluency: str
    evidence_quality: str
    interpretation: str

class ShapExplanation(BaseModel):
    feature: str
    contribution: float

class TherapistProfileDTO(MLResponseBase):
    selected_pattern: str
    probabilities: Dict[str, float]
    shap_values: List[ShapExplanation]
    interpretation: str

class TherapistKnowledgeDTO(MLResponseBase):
    knowledge_components: Dict[str, float]
    mastery_trend: List[Dict[str, Any]]

class AdaptiveTimelineEvent(BaseModel):
    attempt: int
    mastery: float
    difficulty: float
    scaffold_desc: str

class TherapistAdaptiveDTO(MLResponseBase):
    learner_ability: float
    item_difficulty: float
    fatigue: float
    decision_timeline: List[Dict[str, Any]]
