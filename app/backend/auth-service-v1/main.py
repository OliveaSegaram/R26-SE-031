"""
auth-service-v1/main.py
========================
C5 — Authentication Service
FastAPI application — Port 8015

Endpoints:
    POST /api/v1/auth/signup  → Register a new user
    POST /api/v1/auth/login   → Authenticate and return JWT token
    GET  /health              → Health check
"""

import os
import sys
from pathlib import Path
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, status, Depends, Request
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from email_validator import validate_email, EmailNotValidError
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Allow importing from shared/
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from shared.database import connect_to_mongo, close_mongo_connection, get_db
from models import UserCreate, UserLogin, Token, UserResponse, TokenRefreshRequest, ChangePasswordRequest, StudentCreate, StudentResponse, StudentUpdate
from auth_utils import get_password_hash, verify_password, create_access_token, create_refresh_token, verify_token

PORT = int(os.getenv("C5_PORT", "8015"))
limiter = Limiter(key_func=get_remote_address)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    decoded = verify_token(token)
    if not decoded or decoded.get("type") == "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    
    db = get_db()
    user = await db.users.find_one({"email": decoded["sub"]})
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    
    return user

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    yield
    await close_mongo_connection()

app = FastAPI(
    title="C5 — Authentication Service",
    description="Handles user registration and login with MongoDB.",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_methods=["*"], 
    allow_headers=["*"],
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


@app.get("/health")
def health():
    return {"status": "ok", "service": "C5-Auth"}


@app.post("/api/v1/auth/signup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def signup(request: Request, user: UserCreate):
    db = get_db()
    
    try:
        valid = validate_email(user.email, check_deliverability=True)
        email = valid.normalized
    except EmailNotValidError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    # Check if user already exists
    existing_user = await db.users.find_one({"email": email.lower()})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists."
        )
    
    # Hash password
    hashed_password = get_password_hash(user.password)
    
    # Save to db
    user_doc = {
        "name": user.name,
        "email": email.lower(),
        "hashed_password": hashed_password,
        "role": user.role,
    }
    
    result = await db.users.insert_one(user_doc)
    
    return UserResponse(
        id=str(result.inserted_id),
        name=user_doc["name"],
        email=user_doc["email"],
        role=user_doc["role"]
    )


@app.post("/api/v1/auth/login", response_model=Token)
@limiter.limit("10/minute")
async def login(request: Request, user: UserLogin):
    db = get_db()
    
    # Find user by email
    user_doc = await db.users.find_one({"email": user.email.lower()})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password
    if not verify_password(user.password, user_doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create JWT token
    access_token = create_access_token(
        data={"sub": user_doc["email"], "role": user_doc.get("role", "student"), "id": str(user_doc["_id"])}
    )
    refresh_token = create_refresh_token(
        data={"sub": user_doc["email"], "role": user_doc.get("role", "student"), "id": str(user_doc["_id"])}
    )
    
    return Token(access_token=access_token, refresh_token=refresh_token, token_type="bearer")

@app.post("/api/v1/auth/refresh", response_model=Token)
@limiter.limit("10/minute")
async def refresh_token_endpoint(request: Request, token_req: TokenRefreshRequest):
    decoded = verify_token(token_req.refresh_token)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )
    
    access_token = create_access_token(
        data={"sub": decoded["sub"], "role": decoded.get("role", "student"), "id": decoded.get("id")}
    )
    refresh_token = create_refresh_token(
        data={"sub": decoded["sub"], "role": decoded.get("role", "student"), "id": decoded.get("id")}
    )
    
    return Token(access_token=access_token, refresh_token=refresh_token, token_type="bearer")

@app.get("/api/v1/auth/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    return UserResponse(
        id=str(current_user["_id"]),
        name=current_user["name"],
        email=current_user["email"],
        role=current_user.get("role", "student")
    )

@app.post("/api/v1/auth/change-password")
async def change_password(request: ChangePasswordRequest, current_user: dict = Depends(get_current_user)):
    if not verify_password(request.old_password, current_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect old password")
    
    if request.old_password == request.new_password:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="New password cannot be the same as the current password")
    
    hashed_new = get_password_hash(request.new_password)
    
    db = get_db()
    await db.users.update_one(
        {"_id": current_user["_id"]},
        {"$set": {"hashed_password": hashed_new}}
    )
    
    return {"status": "success", "message": "Password changed successfully"}

class VerifyPasswordRequest(BaseModel):
    password: str

@app.post("/api/v1/auth/verify-password")
async def verify_user_password(request: VerifyPasswordRequest, current_user: dict = Depends(get_current_user)):
    if not verify_password(request.password, current_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect password")
    return {"status": "success", "message": "Password is correct"}

@app.post("/api/v1/auth/students", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)
async def add_student(request: StudentCreate, current_user: dict = Depends(get_current_user)):
    # 1. Verify parent password
    if not verify_password(request.parent_password, current_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect parent password")
    
    db = get_db()
    
    # 2. Check if username is taken
    existing = await db.students.find_one({"username": request.username.lower()})
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists")
    
    # 3. Create student document
    student_doc = {
        "parent_id": current_user["_id"],
        "first_name": request.first_name,
        "last_name": request.last_name,
        "username": request.username.lower(),
        "grade": request.grade,
        "daily_limit": request.daily_limit,
        "assessment_results": request.assessment_results,
        "avatar_url": request.avatar_url,
    }
    
    result = await db.students.insert_one(student_doc)
    
    return StudentResponse(
        id=str(result.inserted_id),
        first_name=request.first_name,
        last_name=request.last_name,
        username=request.username,
        grade=request.grade,
        daily_limit=request.daily_limit,
        avatar_url=request.avatar_url
    )

@app.get("/api/v1/auth/students", response_model=list[StudentResponse])
async def list_students(current_user: dict = Depends(get_current_user)):
    db = get_db()
    cursor = db.students.find({"parent_id": current_user["_id"]})
    students = await cursor.to_list(length=100)
    
    result = []
    for s in students:
        result.append(StudentResponse(
            id=str(s["_id"]),
            first_name=s["first_name"],
            last_name=s["last_name"],
            username=s["username"],
            grade=s["grade"],
            daily_limit=s["daily_limit"],
            avatar_url=s.get("avatar_url")
        ))
    
    return result

@app.put("/api/v1/auth/students/{student_id}", response_model=StudentResponse)
async def update_student(student_id: str, request: StudentUpdate, current_user: dict = Depends(get_current_user)):
    if not verify_password(request.parent_password, current_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect parent password")
    
    from bson.objectid import ObjectId
    try:
        obj_id = ObjectId(student_id)
    except:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid student ID")

    db = get_db()
    
    # Ensure student belongs to parent
    existing_student = await db.students.find_one({"_id": obj_id, "parent_id": current_user["_id"]})
    if not existing_student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

    # Check username collision (allow same username for same student)
    existing_username = await db.students.find_one({"username": request.username.lower(), "_id": {"$ne": obj_id}})
    if existing_username:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists")

    update_doc = {
        "first_name": request.first_name,
        "last_name": request.last_name,
        "username": request.username.lower(),
        "grade": request.grade,
        "daily_limit": request.daily_limit,
        "avatar_url": request.avatar_url,
    }

    await db.students.update_one({"_id": obj_id}, {"$set": update_doc})

    return StudentResponse(
        id=str(obj_id),
        first_name=request.first_name,
        last_name=request.last_name,
        username=request.username,
        grade=request.grade,
        daily_limit=request.daily_limit,
        avatar_url=request.avatar_url
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=True)
