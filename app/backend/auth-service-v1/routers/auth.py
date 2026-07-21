"""
routers/auth.py
===============
Authentication endpoints: signup, login, refresh, me, change-password, verify-password.
"""

from fastapi import APIRouter, HTTPException, status, Depends, Request
from email_validator import validate_email, EmailNotValidError
from slowapi import Limiter
from slowapi.util import get_remote_address

from shared.database import get_db
from schemas.auth import (
    UserCreate, UserLogin, Token, TokenRefreshRequest,
    UserResponse, ChangePasswordRequest, VerifyPasswordRequest, GoogleLoginRequest
)
from services.auth_utils import (
    get_password_hash, verify_password,
    create_access_token, create_refresh_token, verify_token, verify_google_token
)
from dependencies import get_current_user

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])
limiter = Limiter(key_func=get_remote_address)


@router.post("/signup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def signup(request: Request, user: UserCreate):
    """Register a new parent account."""
    db = get_db()

    try:
        valid = validate_email(user.email, check_deliverability=True)
        email = valid.normalized
    except EmailNotValidError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    # Check if user already exists
    existing_user = await db.users.find_one({"email": email.lower()})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists.",
        )

    # Hash password and save
    hashed_password = get_password_hash(user.password)
    user_doc = {
        "name": user.name,
        "email": email.lower(),
        "hashed_password": hashed_password,
        "role": user.role or "parent",
    }

    result = await db.users.insert_one(user_doc)

    return UserResponse(
        id=str(result.inserted_id),
        name=user_doc["name"],
        email=user_doc["email"],
        role=user_doc["role"],
    )


@router.post("/login", response_model=Token)
@limiter.limit("10/minute")
async def login(request: Request, user: UserLogin):
    """Authenticate and return JWT tokens."""
    db = get_db()

    user_doc = await db.users.find_one({"email": user.email.lower()})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not verify_password(user.password, user_doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_data = {
        "sub": user_doc["email"],
        "role": user_doc.get("role", "parent"),
        "id": str(user_doc["_id"]),
    }
    access_token = create_access_token(data=token_data)
    refresh_token = create_refresh_token(data=token_data)

    return Token(access_token=access_token, refresh_token=refresh_token, token_type="bearer")

@router.post("/google", response_model=Token)
@limiter.limit("10/minute")
async def google_login(request: Request, login_req: GoogleLoginRequest):
    """Authenticate via Google ID token and return JWT tokens."""
    db = get_db()

    # Verify the token with Google
    idinfo = verify_google_token(login_req.id_token)
    if not idinfo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    email = idinfo.get("email", "").lower()
    name = idinfo.get("name", "User")
    
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google token did not contain an email address",
        )

    # Check if user already exists
    user_doc = await db.users.find_one({"email": email})
    
    if not user_doc:
        # Implicitly sign up the user
        user_doc = {
            "name": name,
            "email": email,
            "hashed_password": get_password_hash("google-oauth-placeholder-password"),
            "role": "parent",
        }
        result = await db.users.insert_one(user_doc)
        user_id = str(result.inserted_id)
    else:
        user_id = str(user_doc["_id"])

    token_data = {
        "sub": email,
        "role": user_doc.get("role", "parent"),
        "id": user_id,
    }
    
    access_token = create_access_token(data=token_data)
    refresh_token = create_refresh_token(data=token_data)

    return Token(access_token=access_token, refresh_token=refresh_token, token_type="bearer")

@router.post("/refresh", response_model=Token)
@limiter.limit("10/minute")
async def refresh_token_endpoint(request: Request, token_req: TokenRefreshRequest):
    """Exchange a refresh token for new access + refresh tokens."""
    decoded = verify_token(token_req.refresh_token)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    token_data = {
        "sub": decoded["sub"],
        "role": decoded.get("role", "parent"),
        "id": decoded.get("id"),
    }
    access_token = create_access_token(data=token_data)
    refresh_token = create_refresh_token(data=token_data)

    return Token(access_token=access_token, refresh_token=refresh_token, token_type="bearer")


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    """Return the authenticated user's profile."""
    return UserResponse(
        id=str(current_user["_id"]),
        name=current_user["name"],
        email=current_user["email"],
        role=current_user.get("role", "parent"),
    )


@router.post("/change-password")
async def change_password(request: ChangePasswordRequest, current_user: dict = Depends(get_current_user)):
    """Change the authenticated user's password."""
    if not verify_password(request.old_password, current_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect old password")

    if request.old_password == request.new_password:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="New password cannot be the same as the current password")

    hashed_new = get_password_hash(request.new_password)

    db = get_db()
    await db.users.update_one(
        {"_id": current_user["_id"]},
        {"$set": {"hashed_password": hashed_new}},
    )

    return {"status": "success", "message": "Password changed successfully"}


@router.post("/verify-password")
async def verify_user_password(request: VerifyPasswordRequest, current_user: dict = Depends(get_current_user)):
    """Verify the authenticated user's password (e.g. before sensitive actions)."""
    if not verify_password(request.password, current_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect password")
    return {"status": "success", "message": "Password is correct"}
