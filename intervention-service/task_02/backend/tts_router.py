"""Sinhala TTS for Task 02 UI — gTTS with on-disk cache."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse

router = APIRouter(prefix="/api/v1/c4", tags=["tts"])

_CACHE_DIR = Path(__file__).resolve().parent.parent / ".tts_cache"
_CACHE_DIR.mkdir(parents=True, exist_ok=True)

_SAFE_NAME = re.compile(r"[^a-zA-Z0-9._-]+")


def _cache_path(text: str, lang: str) -> Path:
    key = hashlib.sha256(f"{lang}:{text}".encode("utf-8")).hexdigest()[:32]
    return _CACHE_DIR / f"{key}.mp3"


@router.get("/tts")
def synthesize(
    text: str = Query(..., min_length=1, max_length=200),
    lang: str = Query("si"),
    kind: str = Query("ui"),
):
    """Return JSON `{ "url": "/api/v1/c4/tts/audio/<file>.mp3" }` for PlayAudioService."""
    del kind  # reserved for future ui vs syllable clips
    cleaned = text.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail="text required")

    path = _cache_path(cleaned, lang)
    if not path.exists():
        try:
            from gtts import gTTS

            gTTS(text=cleaned, lang=lang).save(str(path))
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"TTS failed: {exc}") from exc

    return {"url": f"/api/v1/c4/tts/audio/{path.name}"}


@router.get("/tts/audio/{filename}")
def serve_audio(filename: str):
    safe = _SAFE_NAME.sub("", filename)
    if not safe.endswith(".mp3") or safe != filename:
        raise HTTPException(status_code=400, detail="invalid filename")

    path = _CACHE_DIR / safe
    if not path.is_file():
        raise HTTPException(status_code=404, detail="audio not found")

    return FileResponse(path, media_type="audio/mpeg")
