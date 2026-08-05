import os
import uuid
import hashlib
from gtts import gTTS

class TTSService:
    @staticmethod
    def text_to_speech(text: str) -> str:
        """Generate a new speech file for given text and return its filepath."""
        file_name = f"{uuid.uuid4()}.mp3"
        
        # We'll save it to a public static folder so frontend can access
        os.makedirs("static/audio", exist_ok=True)
        file_path = f"static/audio/{file_name}"
        
        try:
            tts = gTTS(text=text, lang="si")
            tts.save(file_path)
            return file_path
        except Exception as e:
            raise RuntimeError(f"Text-to-speech generation failed: {e}")

    @staticmethod
    def get_existing_speech(text: str) -> str | None:
        """Check if a speech file for the given text already exists based on hash."""
        text_hash = hashlib.md5(text.encode()).hexdigest()
        file_name = f"{text_hash}.mp3"
        file_path = f"static/audio/{file_name}"

        if os.path.exists(file_path):
            return file_path
        return None
