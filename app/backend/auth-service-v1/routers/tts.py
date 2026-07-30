from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from fastapi.responses import FileResponse
from services.tts_service import TTSService
import os

router = APIRouter(prefix="/tts", tags=["Text-to-Speech"])

class TTSRequest(BaseModel):
    text: str

@router.post("/generate")
async def generate_speech(request: TTSRequest):
    """
    Converts Sinhala text into speech using Google TTS.
    Returns the generated MP3 file path.
    """
    text = request.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text cannot be empty")
        
    try:
        # Check if already generated
        existing_path = TTSService.get_existing_speech(text)
        if existing_path:
            return {"file_path": f"/{existing_path}"}
            
        # Generate new
        new_path = TTSService.text_to_speech(text)
        return {"file_path": f"/{new_path}"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
