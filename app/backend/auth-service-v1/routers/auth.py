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
    UserResponse, ChangePasswordRequest, VerifyPasswordRequest, GoogleLoginRequest, MicrosoftLoginRequest
)
from services.auth_utils import (
    get_password_hash, verify_password,
    create_access_token, create_refresh_token, verify_token, verify_google_token, verify_microsoft_token
)
from dependencies import get_current_user

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])
limiter = Limiter(key_func=get_remote_address)


@router.post("/signup", status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register_user(request: Request, user: UserCreate):
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

    # Check if user already exists in the MAIN database
    existing_user = await db.users.find_one({"email": email.lower()})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists.",
        )

    # We do NOT insert into db.users yet. We only generate OTP and store pending data.
    hashed_password = get_password_hash(user.password)
    
    from services.auth_utils import generate_otp, send_otp_email
    otp = generate_otp()
    
    from datetime import datetime, timedelta
    
    pending_user = {
        "name": user.name,
        "hashed_password": hashed_password,
        "role": user.role or "parent",
        "auth_provider": "local",
    }
    
    await db.otps.update_one(
        {"email": email.lower()},
        {"$set": {
            "otp": otp, 
            "expires_at": datetime.utcnow() + timedelta(minutes=10),
            "pending_user": pending_user
        }},
        upsert=True
    )
    
    # Send email
    send_otp_email(email.lower(), otp)

    # We return a message instead of tokens, because they need to verify first
    return {"message": "OTP sent. Please verify your email to complete registration."}

from schemas.auth import VerifyEmailRequest

@router.post("/verify-email", response_model=Token)
@limiter.limit("5/minute")
async def verify_email(request: Request, req: VerifyEmailRequest):
    """Verify email via OTP and return JWT tokens on success."""
    db = get_db()
    email = req.email.lower()
    
    # Find OTP
    otp_record = await db.otps.find_one({"email": email, "otp": req.otp})
    if not otp_record:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP.")
        
    from datetime import datetime
    if datetime.utcnow() > otp_record["expires_at"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP has expired.")
        
    # Check if this OTP contains pending user data (meaning it's a Signup Verification)
    pending = otp_record.get("pending_user")
    
    if pending:
        # Create the user permanently in the DB now that they verified!
        user_doc = {
            "name": pending["name"],
            "email": email,
            "hashed_password": pending["hashed_password"],
            "role": pending["role"],
            "is_verified": True
        }
        
        if pending.get("role") == "specialist":
            import random
            import string
            # Generate a professional 6-character alphanumeric clinic code
            user_doc["clinic_code"] = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
        
        # Upsert just in case they were somehow inserted but unverified before we changed architecture
        await db.users.update_one(
            {"email": email},
            {"$set": user_doc},
            upsert=True
        )
        user_doc = await db.users.find_one({"email": email})
    else:
        # Fallback for old unverified accounts doing a standard verify
        user_doc = await db.users.find_one_and_update(
            {"email": email},
            {"$set": {"is_verified": True}},
            return_document=True
        )
    
    if not user_doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
        
    # Delete OTP
    await db.otps.delete_one({"email": email})
    
    # Issue Tokens
    token_data = {
        "sub": user_doc["email"],
        "role": user_doc.get("role", "parent"),
        "id": str(user_doc["_id"]),
    }
    access_token = create_access_token(data=token_data)
    refresh_token = create_refresh_token(data=token_data)

    return Token(access_token=access_token, refresh_token=refresh_token, token_type="bearer")


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

    if user_doc.get("auth_provider", "local") != "local" or not user_doc.get("hashed_password"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account uses social login (Google/Microsoft). Please sign in using your OAuth provider.",
        )

    if not verify_password(user.password, user_doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    if user_doc.get("is_verified") == False:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email address before logging in.",
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
            "hashed_password": None,
            "role": "parent",
            "auth_provider": "google",
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

@router.post("/microsoft", response_model=Token)
@limiter.limit("10/minute")
async def microsoft_login(request: Request, login_req: MicrosoftLoginRequest):
    """Authenticate via Microsoft Access token and return JWT tokens."""
    db = get_db()

    # Verify the token with Microsoft Graph API
    user_info = verify_microsoft_token(login_req.access_token)
    if not user_info:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Microsoft token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    email = user_info.get("email", "").lower()
    name = user_info.get("name", "User")
    
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Microsoft token did not contain an email address",
        )

    # Check if user already exists
    user_doc = await db.users.find_one({"email": email})
    
    if not user_doc:
        # Implicitly sign up the user
        user_doc = {
            "name": name,
            "email": email,
            "hashed_password": None,
            "role": "parent",
            "auth_provider": "microsoft",
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
    provider = current_user.get("auth_provider", "local")
    if provider in ["google", "microsoft"] or not current_user.get("hashed_password"):
        return {"status": "success", "message": "Social user authenticated"}

    if not verify_password(request.password, current_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect password")
    return {"status": "success", "message": "Password is correct"}

from datetime import datetime, timedelta
from schemas.auth import ForgotPasswordRequest, ResetPasswordRequest

@router.post("/forgot-password")
@limiter.limit("3/minute")
async def forgot_password(request: Request, req: ForgotPasswordRequest):
    """Initiate password reset process."""
    db = get_db()
    email = req.email.lower()
    
    user = await db.users.find_one({"email": email})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No account found with this email address."
        )
    # Check if this is an OAuth account
    hashed_pwd = user.get("hashed_password", "")
    if verify_password("google-oauth-placeholder-password", hashed_pwd) or "google-oauth" in hashed_pwd:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You signed up using a social account (Google/Microsoft). Please log in using that button.",
        )
        
    # Generate OTP
    from services.auth_utils import generate_otp, send_otp_email
    otp = generate_otp()
    
    # Store OTP in DB with 10 min expiration
    await db.otps.update_one(
        {"email": email},
        {"$set": {"otp": otp, "expires_at": datetime.utcnow() + timedelta(minutes=10)}},
        upsert=True
    )
    
    # Send email (prints to console currently)
    send_otp_email(email, otp)
    
    return {"message": "If that email exists, an OTP has been sent."}


@router.post("/reset-password")
@limiter.limit("5/minute")
async def reset_password(request: Request, req: ResetPasswordRequest):
    """Reset the password using the OTP."""
    db = get_db()
    email = req.email.lower()
    
    # Find OTP
    otp_record = await db.otps.find_one({"email": email, "otp": req.otp})
    if not otp_record:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP.")
        
    if datetime.utcnow() > otp_record["expires_at"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP has expired.")
        
    # Update Password and mark as verified (since they proved ownership via OTP)
    new_hashed = get_password_hash(req.new_password)
    await db.users.update_one(
        {"email": email},
        {"$set": {
            "hashed_password": new_hashed,
            "is_verified": True
        }}
    )
    
    # Delete OTP so it can't be reused
    await db.otps.delete_one({"email": email})
    
    return {"message": "Password successfully reset."}
