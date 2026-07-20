"""
config.py
=========
Application configuration and constants.
"""

import os

# JWT Configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "super-secret-key-for-development-only")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7   # 7 days
REFRESH_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30  # 30 days

# Server
PORT = int(os.getenv("C5_PORT", "8015"))

# CORS
CORS_ORIGINS = ["*"]
