"""
schemas/students.py
===================
Pydantic models for student management endpoints.
"""

from pydantic import BaseModel, Field
from typing import Optional


class StudentCreate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    grade: str = "Grade 1"  # Locked to Grade 1 for this app
    daily_limit: str = "No Limit"
    assessment_results: list[bool] = []
    comprehensive_assessment_results: dict[str, list[bool]] = {}
    completed_activities: list[str] = []
    activity_scores: dict[str, int] = {}
    avatar_url: Optional[str] = None
    consent_given: bool = False
    consent_parent_name: Optional[str] = None
    consent_date: Optional[str] = None


class StudentUpdate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    grade: str = "Grade 1"
    daily_limit: str = "No Limit"
    avatar_url: Optional[str] = None


class AssessmentSubmit(BaseModel):
    assessment_results: list[bool] = Field(..., min_length=14, max_length=14)

class ComprehensiveAssessmentSubmit(BaseModel):
    assessment_results: list[bool]


class StudentResponse(BaseModel):
    id: str
    first_name: str
    last_name: str
    grade: str
    daily_limit: str
    avatar_url: Optional[str] = None
    assessment_results: list[bool] = []
    comprehensive_assessment_results: dict[str, list[bool]] = {}
    completed_activities: list[str] = []
    activity_scores: dict[str, int] = {}
    assessment_completed: bool = False

class ProgressSyncRequest(BaseModel):
    completed_activities: list[str]
    activity_scores: dict[str, int]
