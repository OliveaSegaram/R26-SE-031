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
from email_validator import validate_email, EmailNotValidError
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Allow importing from shared/
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from shared.database import connect_to_mongo, close_mongo_connection, get_db
from models import UserCreate, UserLogin, Token, UserResponse, TokenRefreshRequest, ChangePasswordRequest
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=True)
