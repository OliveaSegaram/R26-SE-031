"""
schemas/specialist.py
=====================
Pydantic models for specialist connection endpoints.
"""

from pydantic import BaseModel, Field

class SpecialistConnectRequest(BaseModel):
    clinic_code: str = Field(..., min_length=6, max_length=6, description="6-digit code provided by the specialist")
    student_id: str

class SpecialistConnectResponse(BaseModel):
    message: str
