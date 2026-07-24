"""
Sinhala TTS for C4 Flutter UI.

Primary: Dialog SinhalaVITS (Hugging Face Space) — better single-letter quality
Fallback: gTTS

Space: https://huggingface.co/spaces/dialoglk/SinhalaVITS
API:   https://dialoglk-sinhalavits.hf.space/gradio_api/call/generate_speech
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse

router = APIRouter(prefix="/api/v1/c4", tags=["tts"])

_CACHE_DIR = Path(__file__).resolve().parent.parent / ".tts_cache"
_CACHE_DIR.mkdir(parents=True, exist_ok=True)

_SAFE_NAME = re.compile(r"[^a-zA-Z0-9._-]+")
_SINHALA_RE = re.compile(r"[\u0D80-\u0DFF]")

VITS_BASE = os.getenv(
    "SINHALA_VITS_BASE",
    "https://dialoglk-sinhalavits.hf.space",
)
VITS_SPEAKER = os.getenv("SINHALA_VITS_SPEAKER", "Female Voice 2")
# Prefer VITS for Sinhala; set SINHALA_TTS_ENGINE=gtts to force gTTS only
TTS_ENGINE = os.getenv("SINHALA_TTS_ENGINE", "vits").lower()


def _cache_path(key_material: str, ext: str) -> Path:
    key = hashlib.sha256(key_material.encode("utf-8")).hexdigest()[:32]
    return _CACHE_DIR / f"{key}{ext}"


def _is_sinhala(text: str) -> bool:
    return bool(_SINHALA_RE.search(text))


def _prepare_vits_text(text: str, kind: str) -> str:
    """
    Single akshara often needs a tiny phonetic frame for VITS to pronounce
    clearly. Keep it short; still one target sound for the child.
    """
    cleaned = text.strip()
    if kind in ("syllable", "first_sound") and len(cleaned) <= 3:
        # Trailing Sinhala full stop helps phrasing without English letters
        return f"{cleaned}."
    return cleaned


def _synthesize_vits(text: str, speaker: str) -> Path:
    """Call Gradio generate_speech and download the WAV into cache."""
    speak = text.strip()
    path = _cache_path(f"vits|{speaker}|{speak}", ".wav")
    if path.exists() and path.stat().st_size > 100:
        return path

    payload = json.dumps({"data": [speak, speaker]}).encode("utf-8")
    req = urllib.request.Request(
        f"{VITS_BASE}/gradio_api/call/generate_speech",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        meta = json.loads(resp.read().decode("utf-8"))
    event_id = meta.get("event_id")
    if not event_id:
        raise RuntimeError(f"SinhalaVITS missing event_id: {meta}")

    # SSE stream until complete
    result_url = None
    with urllib.request.urlopen(
        f"{VITS_BASE}/gradio_api/call/generate_speech/{event_id}",
        timeout=120,
    ) as resp:
        for raw in resp:
            line = raw.decode("utf-8", "replace").strip()
            if line.startswith("data:"):
                data_str = line[5:].strip()
                if not data_str or data_str == "null":
                    continue
                try:
                    data = json.loads(data_str)
                except json.JSONDecodeError:
                    continue
                if isinstance(data, list) and data:
                    item = data[0]
                    if isinstance(item, dict) and item.get("url"):
                        result_url = item["url"]
                        break

    if not result_url:
        raise RuntimeError("SinhalaVITS returned no audio URL")

    with urllib.request.urlopen(result_url, timeout=60) as audio_resp:
        path.write_bytes(audio_resp.read())
    return path


def _synthesize_gtts(text: str, lang: str, kind: str) -> Path:
    from gtts import gTTS

    slow = kind in ("syllable", "first_sound", "ui")
    speak_text = text
    if slow and len(text) <= 4:
        speak_text = f"{text} {text}"
    path = _cache_path(f"gtts|{lang}|{slow}|{speak_text}", ".mp3")
    if not path.exists():
        gTTS(text=speak_text, lang=lang, slow=slow).save(str(path))
    return path


@router.get("/tts")
def synthesize(
    text: str = Query(..., min_length=1, max_length=200),
    lang: str = Query("si"),
    kind: str = Query("word"),
    speaker: str = Query(None, description="VITS voice: Female Voice 2, etc."),
):
    """
    Return `{ "url": "/api/v1/c4/tts/audio/<file>.wav|.mp3", "engine": "vits"|"gtts" }`.

    Sinhala → SinhalaVITS (Dialog HF Space) by default.
    Non-Sinhala / VITS failure → gTTS fallback.
    """
    cleaned = text.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail="text required")

    voice = speaker or VITS_SPEAKER
    engine_used = "gtts"
    path: Path | None = None
    err_vits: str | None = None

    use_vits = (
        TTS_ENGINE == "vits"
        and (lang.startswith("si") or _is_sinhala(cleaned))
    )

    if use_vits:
        try:
            vits_text = _prepare_vits_text(cleaned, kind)
            path = _synthesize_vits(vits_text, voice)
            engine_used = "vits"
        except Exception as exc:
            err_vits = str(exc)
            path = None

    if path is None:
        try:
            # gTTS needs latin for en; for Sinhala use lang=si
            g_lang = "si" if (_is_sinhala(cleaned) or lang.startswith("si")) else lang
            path = _synthesize_gtts(cleaned, g_lang, kind)
            engine_used = "gtts"
        except Exception as exc:
            detail = f"TTS failed: {exc}"
            if err_vits:
                detail += f" (VITS also failed: {err_vits})"
            raise HTTPException(status_code=500, detail=detail) from exc

    return {
        "url": f"/api/v1/c4/tts/audio/{path.name}",
        "engine": engine_used,
        "speaker": voice if engine_used == "vits" else None,
    }


@router.get("/tts/audio/{filename}")
def serve_audio(filename: str):
    safe = _SAFE_NAME.sub("", filename)
    if safe != filename or not (
        safe.endswith(".mp3") or safe.endswith(".wav")
    ):
        raise HTTPException(status_code=400, detail="invalid filename")

    path = _CACHE_DIR / safe
    if not path.is_file():
        raise HTTPException(status_code=404, detail="audio not found")

    media = "audio/wav" if safe.endswith(".wav") else "audio/mpeg"
    return FileResponse(
        path,
        media_type=media,
        headers={"Cache-Control": "public, max-age=86400"},
    )
