from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional

class InteractionRequest(BaseModel):
    student_id: str
    target_kc: str
    is_correct: bool
    dyslexia_risk_profile: Dict[str, float] = Field(
        default_factory=dict, 
        description="Risk probabilities from Component 3 (e.g., visual_orthographic, phonological)"
    )

class NextAction(BaseModel):
    terminate_session: bool
    ui_scaffolding: Dict[str, bool] = Field(
        default_factory=dict,
        description="Flags for UI adaptations (e.g., enable_high_contrast, slow_playback)"
    )

class TutoringResponse(BaseModel):
    student_id: str
    updated_knowledge_state: Dict[str, float]
    next_action: NextAction
