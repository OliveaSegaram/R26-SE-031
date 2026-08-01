from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class ConnectionCreate(BaseModel):
    student_id: str

class ConnectionCode(BaseModel):
    clinic_code: str
    expires_at: datetime

class TherapistConnectionResponse(BaseModel):
    id: str
    therapist_id: str
    student_id: str
    student_name: Optional[str] = None
    therapist_name: Optional[str] = None
    parent_name: Optional[str] = None
    parent_email: Optional[str] = None
    parent_profile_picture: Optional[str] = None
    student_profile_picture: Optional[str] = None
    clinic_name: Optional[str] = None
    status: str = "active"
    connected_at: datetime

class ConnectSpecialistRequest(BaseModel):
    clinic_code: str
    student_id: str

