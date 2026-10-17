from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from services.stt_service import get_stt_engine, get_stt_status
from datetime import datetime
from database import get_db
import json

from services.c2_pipeline_service import get_c2_pipeline
from services.sinhala_alignment_service import SinhalaAlignmentService

router = APIRouter(prefix="/stt", tags=["Speech-to-Text"])


def require_stt_available() -> None:
    """Reject quickly while startup preload is running or has failed."""
    status = get_stt_status()
    if status["status"] in {"loading", "failed"}:
        warming_up = status["status"] == "loading"
        raise HTTPException(
            status_code=503,
            detail={
                "code": "stt_warming_up" if warming_up else "stt_unavailable",
                "message": "The speech model is preparing. Please retry shortly."
                if warming_up
                else "The speech model could not be loaded.",
                "retryable": warming_up,
            },
        )

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    """
    Accepts an audio file and transcribes it into Sinhala text using Whisper.
    """
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")
    require_stt_available()
        
    try:
        audio_bytes = await file.read()
        if len(audio_bytes) == 0:
            raise HTTPException(status_code=400, detail="Empty file uploaded")
            
        stt_engine = get_stt_engine()
        transcription = stt_engine.transcribe_audio_bytes(audio_bytes)
        
        return {"transcription": transcription}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze-reading")
async def analyze_reading(
    expected_text: str = Form(...),
    file: UploadFile = File(...)
):
    """
    Accepts an audio file and the expected Sinhala text.
    Transcribes the audio and calculates the Word Error Rate (WER) using Levenshtein Distance.
    """
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")
    require_stt_available()
        
    try:
        audio_bytes = await file.read()
        if len(audio_bytes) == 0:
            raise HTTPException(status_code=400, detail="Empty file uploaded")
            
        stt_engine = get_stt_engine()
        transcription = stt_engine.transcribe_audio_bytes(audio_bytes)
        
        alignment = SinhalaAlignmentService().compare(expected_text, transcription)
            
        return {
            "transcription": transcription,
            "expected_text": expected_text,
            "word_error_rate": alignment["word"]["error_rate"],
            "grapheme_error_rate": alignment["grapheme"]["error_rate"],
            "alignment": alignment,
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze-acoustics")
async def analyze_acoustics(
    student_id: str = Form(None),
    session_id: str = Form(None),
    event_id: str = Form(None),
    attempt_id: str = Form(None),
    skill_id: str = Form(None),
    activity_id: str = Form(None),
    item_id: str = Form(None),
    round_id: str = Form(None),
    dataset_id: str = Form(None),
    data_origin: str = Form("observed"),
    expected_text: str = Form(""),
    allowed_variants_json: str = Form("[]"),
    expected_syllables: int = Form(0),
    t_stimulus: int = Form(0),
    t_record_start: int = Form(0),
    file: UploadFile = File(...)
):
    """
    Accepts a raw WAV audio file and analyzes it for acoustic hesitation,
    latency, syllable peak deltas, and prosodic instability (jitter/shimmer).
    """
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")
    require_stt_available()
        
    try:
        audio_bytes = await file.read()
        if len(audio_bytes) == 0:
            raise HTTPException(status_code=400, detail="Empty file uploaded")
            
        try:
            allowed_variants = json.loads(allowed_variants_json or "[]")
            if not isinstance(allowed_variants, list):
                raise ValueError
            allowed_variants = [str(value) for value in allowed_variants]
        except (ValueError, TypeError, json.JSONDecodeError):
            raise HTTPException(422, "allowed_variants_json must be a JSON string array")
        if data_origin not in {"observed", "synthetic"}:
            raise HTTPException(422, "data_origin must be observed or synthetic")
        resolved_dataset_id = dataset_id or (
            f"session:{session_id}" if session_id else None
        )

        result = get_c2_pipeline().process(
            wav_bytes=audio_bytes,
            expected_text=expected_text,
            expected_syllables=expected_syllables,
            t_stimulus=t_stimulus,
            t_record_start=t_record_start,
            allowed_variants=allowed_variants,
        )
        quality = result["quality"]
        transcription = result["transcription"]
        alignment = result["alignment"]
        acoustic = result["acoustic"]
        fluency = result["fluency"]
        fusion = result["fusion"]
        recognized_text = transcription.get("text", "")
        word_metrics = alignment.get("word") or {}
        grapheme_metrics = alignment.get("grapheme") or {}

        resolved_attempt_id = attempt_id or event_id
        if not resolved_attempt_id and session_id and item_id:
            resolved_attempt_id = f"{session_id}:{item_id}:{t_record_start}"
        
        doc = {
            "attempt_id": resolved_attempt_id,
            "event_id": event_id,
            "student_id": student_id,
            "session_id": session_id,
            "skill_id": skill_id,
            "activity_id": activity_id,
            "item_id": item_id,
            "round_id": round_id,
            "dataset_id": resolved_dataset_id,
            "expected_text": expected_text,
            "recognized_text": recognized_text,
            "allowed_variants": allowed_variants,
            "asr_engine": transcription.get("engine"),
            "asr_model": transcription.get("model"),
            "asr_confidence": transcription.get("confidence"),
            "stt_confidence": transcription.get("confidence"),
            "stt_confidence_method": "mean_token_likelihood",
            "exact_match": alignment.get("exact_match"),
            "character_error_rate": grapheme_metrics.get("error_rate"),
            "grapheme_error_rate": grapheme_metrics.get("error_rate"),
            "grapheme_accuracy": grapheme_metrics.get("accuracy"),
            "word_error_rate": word_metrics.get("error_rate"),
            "word_accuracy": word_metrics.get("accuracy"),
            "normalized_similarity": grapheme_metrics.get("accuracy"),
            "error_operations": grapheme_metrics.get("operations", []),
            "acoustic_latency_ms": acoustic.get("Acoustic_Latency_ms"),
            "voice_onset_ms": acoustic.get("Voice_Onset_ms"),
            "detected_peaks": acoustic.get("Detected_Peaks"),
            "expected_syllables": acoustic.get("Expected_Syllables"),
            "syllabic_event_mismatch": acoustic.get("Peak_Count_Delta"),
            "intra_word_silence_ratio": acoustic.get("Intra_Word_Silence_Ratio"),
            "speech_duration_ms": acoustic.get("Speech_Duration_ms"),
            "pause_count": acoustic.get("Pause_Count"),
            "mean_pause_duration_ms": acoustic.get("Mean_Pause_Duration_ms"),
            "pause_ratio": acoustic.get("Pause_Ratio"),
            "reading_rate_wpm": fluency.get("recognized_words_per_minute"),
            "adjacent_repetitions": fluency.get("adjacent_repetitions"),
            "local_jitter": acoustic.get("Local_Jitter"),
            "local_shimmer": acoustic.get("Local_Shimmer"),
            "recording_quality": quality.get("status"),
            "recording_quality_score": quality.get("quality_score"),
            "recording_quality_issues": quality.get("issues", []),
            "combined_confidence": fusion.get("combined_confidence"),
            "reading_performance_score": fusion.get("reading_performance_score"),
            "created_at": datetime.utcnow(),
            "pipeline_version": result.get("pipeline_version"),
            "feature_version": result.get("pipeline_version"),
            "data_origin": data_origin,
            "validation_status": "not_clinically_validated",
            "measurement_status": fusion.get("measurement_status"),
            "persistence_status": "not_requested",
            "audio_sha256": result.get("audio_sha256"),
            "quality": quality,
            "transcription_evidence": transcription,
            "alignment": alignment,
            "acoustic": acoustic,
            "fluency": fluency,
            "fusion": fusion,
        }
        
        # Save to DB
        if student_id:
            if not all((session_id, activity_id, item_id)):
                raise HTTPException(422, "student/session/activity/item identifiers are required for stored speech")
            try:
                db = get_db()
                stored_doc = dict(doc)
                if resolved_attempt_id:
                    await db.speech_features.update_one(
                        {"student_id": student_id, "attempt_id": resolved_attempt_id},
                        {"$set": stored_doc},
                        upsert=True,
                    )
                else:
                    await db.speech_features.insert_one(stored_doc)
                doc["persistence_status"] = "saved"
            except Exception as e:
                doc["persistence_status"] = "failed"
                doc["measurement_status"] = "persistence_failed"
                doc["persistence_error"] = type(e).__name__
                
        # Preserve the former flat response keys while returning all seven
        # versioned evidence stages for new clients.
        return {
            **acoustic,
            **doc,
            "transcription": recognized_text,
            "word_error_rate": word_metrics.get("error_rate"),
            "Acoustic_Latency_ms": acoustic.get("Acoustic_Latency_ms"),
            "Peak_Count_Delta": acoustic.get("Peak_Count_Delta"),
            "Local_Jitter": acoustic.get("Local_Jitter"),
            "Local_Shimmer": acoustic.get("Local_Shimmer"),
            "pipeline": result,
        }

        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Acoustic analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
