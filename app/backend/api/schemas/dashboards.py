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
    current_skill: str
    fatigue_status: str
    response_speed_status: str

class SkillProgress(BaseModel):
    skill_id: str
    skill_name: str
    mastery_percentage: int
    status: str # "Not Started", "Developing", "Progressing", "Mastered", "Locked"

class ParentSkillsDTO(APIResponseBase):
    skills: List[SkillProgress]

class ParentLearningPatternDTO(APIResponseBase):
    primary_learning_pattern: str
    confidence_level: str
    supporting_observations: List[str]
    recommended_practice: str

class ActivityHistoryItem(BaseModel):
    session_date: str
    activity_name: str
    skill_name: str
    accuracy: int
    duration_minutes: int

class ParentActivityHistoryDTO(APIResponseBase):
    history: List[ActivityHistoryItem]

# ==========================================
# THERAPIST DASHBOARD DTOs
# ==========================================

class TherapistOverviewDTO(MLResponseBase):
    accuracy: int
    median_latency_ms: int
    hesitation_rate: float
    misclick_rate: float
    fatigue_score: float
    primary_learning_pattern: str
    overall_mastery: float
    current_kc: str
    current_difficulty: float

class TherapistBehavioralDTO(MLResponseBase):
    accuracy_trend: List[Dict[str, Any]] # [{"session": "SES001", "accuracy": 75}]
    latency_trend: List[Dict[str, Any]]
    fatigue_trend: List[Dict[str, Any]]
    learner_indices: Dict[str, float]
    error_composition: Dict[str, int]

class ConfusionPair(BaseModel):
    target: str
    selected: str
    count: int

class TherapistKinematicsDTO(MLResponseBase):
    touch_trajectories: List[Dict[str, Any]]
    oci_trend: List[Dict[str, Any]]
    path_efficiency_trend: List[Dict[str, Any]]
    top_confusion_pairs: List[ConfusionPair]
    feature_comparison: Dict[str, Any]

class ShapExplanation(BaseModel):
    feature: str
    contribution: float

class TherapistProfileDTO(MLResponseBase):
    selected_pattern: str
    probabilities: Dict[str, float]
    shap_values: List[ShapExplanation]
    top_shap_features: List[str]

class TherapistKnowledgeDTO(MLResponseBase):
    knowledge_components: Dict[str, float]
    mastery_trend: List[Dict[str, Any]]

class AdaptiveTimelineEvent(BaseModel):
    attempt: int
    mastery: float
    difficulty: float
    scaffold_level: int
    scaffold_desc: str

class TherapistAdaptiveDTO(MLResponseBase):
    learner_ability: float
    item_difficulty: float
    timeline: List[AdaptiveTimelineEvent]
