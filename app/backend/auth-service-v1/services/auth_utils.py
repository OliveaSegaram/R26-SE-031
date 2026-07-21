"""
services/auth_utils.py
======================
Password hashing, JWT creation and verification utilities.
"""

import bcrypt
import jwt
from datetime import datetime, timedelta
from google.oauth2 import id_token
from google.auth.transport import requests
from config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES, REFRESH_TOKEN_EXPIRE_MINUTES
import urllib.request
import json


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Check a plaintext password against a bcrypt hash."""
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    """Hash a plaintext password with bcrypt."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')


def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    """Create a short-lived JWT access token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(data: dict, expires_delta: timedelta = None) -> str:
    """Create a long-lived JWT refresh token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=REFRESH_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def verify_token(token: str) -> dict:
    """Decode and verify a JWT token. Returns payload dict or None."""
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def verify_google_token(token: str) -> dict:
    """Verify a Google ID token and return user info."""
    try:
        # Accept tokens generated for any of our 3 clients (Web, iOS, Android)
        idinfo = id_token.verify_oauth2_token(
            token, 
            requests.Request(), 
            audience=[
                "733315696908-tpau04bmsk824olg6m0a3coanojl147v.apps.googleusercontent.com", # Web
                "733315696908-p1b7u8vgcdkfj08kss6r9u0b5mgvt1uo.apps.googleusercontent.com", # iOS
                "733315696908-le4r1kebs5o83a31d17ngbm4ve0vee4m.apps.googleusercontent.com", # Android
            ]
        )
        return idinfo
    except ValueError as e:
        print(f"Google Token Verification Error: {e}")
        return None

def verify_microsoft_token(access_token: str) -> dict:
    """Verify a Microsoft access token by querying the Microsoft Graph API."""
    try:
        url = "https://graph.microsoft.com/v1.0/me"
        req = urllib.request.Request(url, headers={'Authorization': f'Bearer {access_token}'})
        
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                data = json.loads(response.read().decode())
                
                # Extract relevant fields
                return {
                    "email": data.get("mail") or data.get("userPrincipalName", ""),
                    "name": data.get("displayName", "Microsoft User")
                }
            else:
                return None
    except Exception as e:
        print(f"Microsoft Token Verification Error: {e}")
        return None
