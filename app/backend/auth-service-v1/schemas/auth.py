"""
schemas/auth.py
===============
Pydantic models for authentication endpoints.
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class UserCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8, description="Password must be at least 8 characters long")
    role: Optional[str] = "parent"
    specialization: Optional[str] = None
    clinic_name: Optional[str] = None


class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=50)
    email: Optional[EmailStr] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    device_id: Optional[str] = None
    device_name: Optional[str] = None
    role: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefreshRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: str
    name: str
    email: EmailStr
    role: str
    login_alerts_enabled: bool = True
    profile_picture_url: Optional[str] = None
    clinic_code: Optional[str] = None
    specialization: Optional[str] = None
    clinic_name: Optional[str] = None


class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=8)


class VerifyPasswordRequest(BaseModel):
    password: str

class GoogleLoginRequest(BaseModel):
    id_token: str
    device_id: Optional[str] = None
    device_name: Optional[str] = None
    role: Optional[str] = "parent"
    specialization: Optional[str] = None
    clinic_name: Optional[str] = None

class MicrosoftLoginRequest(BaseModel):
    access_token: str
    device_id: Optional[str] = None
    device_name: Optional[str] = None
    role: Optional[str] = "parent"
    specialization: Optional[str] = None
    clinic_name: Optional[str] = None

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=8)

class VerifyEmailRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)

class ToggleLoginAlertsRequest(BaseModel):
    enabled: bool

class RequestEmailUpdate(BaseModel):
    new_email: EmailStr

class VerifyEmailUpdate(BaseModel):
    new_email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)
