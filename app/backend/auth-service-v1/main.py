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

from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware

# Allow importing from shared/
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from shared.database import connect_to_mongo, close_mongo_connection, get_db
from models import UserCreate, UserLogin, Token, UserResponse
from auth_utils import get_password_hash, verify_password, create_access_token

PORT = int(os.getenv("C5_PORT", "8015"))

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


@app.get("/health")
def health():
    return {"status": "ok", "service": "C5-Auth"}


@app.post("/api/v1/auth/signup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def signup(user: UserCreate):
    db = get_db()
    
    # Check if user already exists
    existing_user = await db.users.find_one({"email": user.email.lower()})
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
        "email": user.email.lower(),
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
async def login(user: UserLogin):
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
    
    return Token(access_token=access_token, token_type="bearer")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=True)
