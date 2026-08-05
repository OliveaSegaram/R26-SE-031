import io
import soundfile as sf
import tempfile
import os

MODEL_NAME = "AqeelShafy7/Whisper-Sinhala_Audio_to_Text"

class STTService:
    def __init__(self):
        import torch
        from transformers import AutoProcessor, AutoModelForSpeechSeq2Seq
        
        self.torch = torch
        self.processor = AutoProcessor.from_pretrained(MODEL_NAME)
        self.model = AutoModelForSpeechSeq2Seq.from_pretrained(MODEL_NAME)
        self.model.eval()

    def transcribe_audio_bytes(self, audio_bytes: bytes) -> str:
        """
        Process the uploaded audio bytes, resample to 16kHz, and transcribe to Sinhala text.
        """
        import librosa
        try:
            # Save bytes to a temp file to let librosa handle format decoding easily
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_file:
                temp_file.write(audio_bytes)
                temp_path = temp_file.name
            
            # Load and resample to 16000 Hz, which is what Whisper expects
            audio_data, sample_rate = librosa.load(temp_path, sr=16000)
            
            # Clean up temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)
                
            inputs = self.processor(audio_data, sampling_rate=16000, return_tensors="pt")
            
            with self.torch.no_grad():
                output = self.model.generate(**inputs)
                
            return self.processor.batch_decode(output, skip_special_tokens=True)[0]
            
        except Exception as e:
            raise RuntimeError(f"Failed to process and transcribe audio: {e}")

# Singleton instance to avoid reloading the model on every request
stt_engine = None

def get_stt_engine():
    global stt_engine
    if stt_engine is None:
        stt_engine = STTService()
    return stt_engine
