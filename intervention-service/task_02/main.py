"""Task 02 API entry point — run: python -m uvicorn main:app --reload --port 8000"""

import sys
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

_backend = Path(__file__).resolve().parent / "backend"
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from router import router as task02_router
from tts_router import router as tts_router

app = FastAPI(title="Task 02 — Early Identification", version="1.0")
app.include_router(task02_router)
app.include_router(tts_router)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "service": "task02"}
