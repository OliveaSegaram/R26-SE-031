import asyncio
from datetime import datetime
import uuid
import sys
import os

# Add app backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "app", "backend"))
from shared.database import get_db, connect_to_mongo, close_mongo_connection

async def seed_data():
    await connect_to_mongo()
    db = get_db()
    
    student_id = "STU123"
    
    # 1. Clear old data for student
    await db.telemetry_events.delete_many({"student_id": student_id})
    await db.speech_features.delete_many({"student_id": student_id})
    await db.learner_profiles.delete_many({"student_id": student_id})
    await db.adaptive_decisions.delete_many({"student_id": student_id})
    
    # 2. Insert Telemetry
    for i in range(5):
        event_id = str(uuid.uuid4())
        await db.telemetry_events.insert_one({
            "event_id": event_id,
            "student_id": student_id,
            "session_id": f"SES00{i+1}",
            "activity_id": "Activity_1",
            "item_id": "Item_1",
            "timestamp": datetime.utcnow().isoformat(),
            "is_correct": True if i % 2 == 0 else False,
            "first_touch_latency_ms": 1500,
            "total_round_latency_ms": 25000, # 25 seconds practice
            "hesitation_count": 1,
            "misclick_count": 0,
            "audio_replay_count": 0
        })
        
        # Insert Speech for the latest one
        if i == 4:
            await db.speech_features.insert_one({
                "event_id": event_id,
                "student_id": student_id,
                "session_id": f"SES00{i+1}",
                "timestamp": datetime.utcnow().isoformat(),
                "speech_data": {
                    "transcription": "ගමට යමු",
                    "Acoustic_Latency_ms": 1400,
                    "Voice_Onset_ms": 300,
                    "Detected_Peaks": 4,
                    "Expected_Syllables": 4,
                    "Peak_Count_Delta": 0,
                    "Intra_Word_Silence_Ratio": 0.15,
                    "Local_Jitter": 0.012,
                    "Local_Shimmer": 0.025,
                    "recording_quality": "good",
                    "expected_text": "ගමට යමු",
                    "word_error_rate": 0.0
                }
            })
            
    # 3. Insert Learner Profile
    await db.learner_profiles.insert_one({
        "student_id": student_id,
        "session_id": "SES005",
        "timestamp": datetime.utcnow().isoformat(),
        "learner_profile": {
            "class_probabilities": {"Typical": 0.12, "Visual-Orthographic": 0.18, "Phonological": 0.61, "Combined": 0.09},
            "primary_pattern": "Phonological"
        }
    })
    
    # 4. Insert Adaptive Decision
    await db.adaptive_decisions.insert_one({
        "student_id": student_id,
        "session_id": "SES005",
        "timestamp": datetime.utcnow().isoformat(),
        "mastery_after": 0.68,
        "selected_difficulty": 0.5,
        "selected_activity": "Skill_5",
        "scaffold_level": 1,
        "decision_reason": "CONTINUE"
    })
    
    await close_mongo_connection()
    print("Database seeded with sample multimodal data.")

if __name__ == "__main__":
    asyncio.run(seed_data())
