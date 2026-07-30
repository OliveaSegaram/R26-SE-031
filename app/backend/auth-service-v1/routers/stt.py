from fastapi import APIRouter, File, UploadFile, HTTPException
from services.stt_service import get_stt_engine

router = APIRouter(prefix="/stt", tags=["Speech-to-Text"])

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    """
    Accepts an audio file and transcribes it into Sinhala text using Whisper.
    """
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")
        
    try:
        audio_bytes = await file.read()
        if len(audio_bytes) == 0:
            raise HTTPException(status_code=400, detail="Empty file uploaded")
            
        stt_engine = get_stt_engine()
        transcription = stt_engine.transcribe_audio_bytes(audio_bytes)
        
        return {"transcription": transcription}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
