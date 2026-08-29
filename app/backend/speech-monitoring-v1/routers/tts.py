import os
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
from services.tts_service import TTSService

router = APIRouter(prefix="/tts", tags=["Text-to-Speech"])

class TTSRequest(BaseModel):
    text: str

@router.post("/generate")
def generate_speech(request: TTSRequest):
    """
    Converts Sinhala text into speech using Google TTS.
    Returns the streaming URL for the generated MP3.
    """
    text = request.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text cannot be empty")
        
    try:
        text_hash = TTSService.text_to_speech(text)
        return {"file_path": f"/tts/audio/{text_hash}.wav"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.api_route("/audio/{text_hash}.wav", methods=["GET", "HEAD"])
async def get_audio(text_hash: str):
    """
    Streams the TTS audio file directly from local filesystem.
    """
    local_path = os.path.join(os.path.dirname(__file__), "..", "local_audio", f"{text_hash}.wav")
    if not os.path.exists(local_path):
        raise HTTPException(status_code=404, detail="Audio not found")
        
    return FileResponse(local_path, media_type="audio/wav")
