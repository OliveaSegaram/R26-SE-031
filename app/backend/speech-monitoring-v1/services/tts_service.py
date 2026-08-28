import hashlib
import struct
import os
from database import get_fs
from google import genai
from google.genai import types

def parse_audio_mime_type(mime_type: str) -> dict:
    bits_per_sample = 16
    rate = 24000

    parts = mime_type.split(";")
    for param in parts:
        param = param.strip()
        if param.lower().startswith("rate="):
            try:
                rate_str = param.split("=", 1)[1]
                rate = int(rate_str)
            except (ValueError, IndexError):
                pass
        elif param.startswith("audio/L"):
            try:
                bits_per_sample = int(param.split("L", 1)[1])
            except (ValueError, IndexError):
                pass

    return {"bits_per_sample": bits_per_sample, "rate": rate}

def convert_to_wav(audio_data: bytes, mime_type: str) -> bytes:
    parameters = parse_audio_mime_type(mime_type)
    bits_per_sample = parameters["bits_per_sample"]
    sample_rate = parameters["rate"]
    num_channels = 1
    data_size = len(audio_data)
    bytes_per_sample = bits_per_sample // 8
    block_align = num_channels * bytes_per_sample
    byte_rate = sample_rate * block_align
    chunk_size = 36 + data_size

    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF",          
        chunk_size,       
        b"WAVE",          
        b"fmt ",          
        16,               
        1,                
        num_channels,     
        sample_rate,      
        byte_rate,        
        block_align,      
        bits_per_sample,  
        b"data",          
        data_size         
    )
    return header + audio_data


class TTSService:
    @staticmethod
    async def text_to_speech(text: str) -> str:
        """Generate a new speech file for given text and upload to GridFS. Returns text_hash."""
        text_hash = hashlib.md5(text.encode()).hexdigest()
        
        # Check if already exists in GridFS
        existing = await TTSService.get_existing_speech(text_hash)
        if existing:
            return text_hash
            
        try:
            client = genai.Client(
                api_key=os.environ.get("GEMINI_API_KEY"),
            )

            model = "gemini-3.1-flash-tts-preview"
            
            # Format the text with the perfect Scene and Context settings
            prompt_text = f"""## Scene:
A friendly, bright classroom setting, learning a new language together.

## Sample Context:
Clear pronunciation, very encouraging tone, patient pacing, speaking naturally and fluently in Sinhala to a young child.

## Transcript:
Speaker 1: {text}"""

            contents = [
                types.Content(
                    role="user",
                    parts=[types.Part.from_text(text=prompt_text)],
                ),
            ]
            
            generate_content_config = types.GenerateContentConfig(
                temperature=0.5,
                response_modalities=["audio"],
                speech_config=types.SpeechConfig(
                    multi_speaker_voice_config=types.MultiSpeakerVoiceConfig(
                        speaker_voice_configs=[
                            types.SpeakerVoiceConfig(
                                speaker="Speaker 1",
                                voice_config=types.VoiceConfig(
                                    prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                        voice_name="Zephyr"
                                    )
                                ),
                            ),
                        ]
                    ),
                ),
            )

            response_stream = client.models.generate_content_stream(
                model=model,
                contents=contents,
                config=generate_content_config,
            )

            audio_buffer = b""
            mime_type = "audio/L16;rate=24000"
            
            for chunk in response_stream:
                if chunk.parts is None:
                    continue
                if chunk.parts[0].inline_data and chunk.parts[0].inline_data.data:
                    inline_data = chunk.parts[0].inline_data
                    audio_buffer += inline_data.data
                    mime_type = inline_data.mime_type
            
            if not audio_buffer:
                raise Exception("No audio returned from Gemini API")

            # Convert to WAV
            wav_data = convert_to_wav(audio_buffer, mime_type)
            
            # Upload to GridFS
            fs = get_fs()
            await fs.upload_from_stream(
                filename=text_hash,
                source=wav_data,
                metadata={"contentType": "audio/wav", "text": text}
            )
            return text_hash
        except Exception as e:
            raise RuntimeError(f"Text-to-speech generation failed: {e}")

    @staticmethod
    async def get_existing_speech(text_hash: str) -> bool:
        """Check if a speech file for the given hash already exists in GridFS."""
        fs = get_fs()
        cursor = fs.find({"filename": text_hash})
        docs = await cursor.to_list(length=1)
        return len(docs) > 0
