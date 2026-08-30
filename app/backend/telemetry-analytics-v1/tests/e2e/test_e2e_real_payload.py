import asyncio
import sys
from motor.motor_asyncio import AsyncIOMotorClient
import json
from httpx import AsyncClient, ASGITransport
from bson import ObjectId

sys.path.append("d:/01 ACADEMIA/4th Year/Y4.S2/RP-IT4010/00 - Implementation/R26-SE-031/app/backend/telemetry-analytics-v1")
from main import app
from database import connect_to_mongo, get_db

import pytest
import mongomock_motor

@pytest.mark.asyncio
async def test_real_payload():
    print("Testing Real Payload Propagation to MongoDB...")
    
    db_mock = mongomock_motor.AsyncMongoMockClient()["r26_se_031"]
    # override db
    import database
    database.db_instance.client = mongomock_motor.AsyncMongoMockClient()
    global db
    db = database.db_instance.client["r26_se_031"]
    
    # 1. Create a dummy parent and student in the DB for the test
    parent_id = ObjectId()
    student_id = ObjectId()
    parent = {"_id": parent_id, "role": "parent"}
    # We must insert str parent_id into students, since that's what telemetry checks.
    parent_str = str(parent_id)
    student = {"_id": student_id, "parent_id": parent_id}
    
    await db.users.insert_one(parent)
    await db.students.insert_one(student)

    # 2. Construct a mock "real" payload that matches Flutter's exact new shape for "wrong, wrong, correct"
    payload = {
        "student_id": str(student_id),
        "session_id": "e2e_test_session_999",
        "session_duration_seconds": 45,
        "device_metrics": {"os": "android", "model": "Pixel 6"},
        "events": [
            {
                "event_id": "test_evt_1",
                "activity_name": "odd_one_out",
                "round_number": 1,
                "is_correct": True,
                "score": 100,
                "timestamp": "2026-08-30T10:00:00Z",
                "first_touch_latency_ms": 1200,
                "total_round_latency_ms": 4500,
                "misclick_count": 0,
                "hesitation_count": 0,
                "audio_replay_count": 0,
                "correction_count": 0,
                "hint_count": 0,
                "is_abandoned": False,
                "touch_path": [],
                "attempt_count": 3,
                "incorrect_attempt_count": 2,
                "first_attempt_correct": False,
                "final_correct": True,
                "time_to_first_response_ms": 1200,
                "time_to_correct_ms": 4500,
                "skill_id": "skill_2",
                "activity_id": "skill2_act1_odd_one_out",
                "item_id": "S2A1R01",
                "item_version": 1,
                "knowledge_component_id": "KC_AKSHARA_IDENTITY",
                "prompt_modality": "visual",
                "response_modality": "tap",
                "research_role": "primary",
                "difficulty_label": "easy",
                "difficulty_b": 0.2,
                "is_anchor": False,
                "targets": ["A", "A", "A", "B"],
                "selected_answers": ["A", "A", "B"],
                "error_type": "unknown_error"
            }
        ]
    }

    # 3. Post to the FastAPI app as the parent
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Mock auth
        app.dependency_overrides.clear()
        from dependencies import get_current_user
        app.dependency_overrides[get_current_user] = lambda: {"_id": parent_id, "role": "parent"}
        
        print("\n--- Submitting Payload ---")
        response = await client.post(f"/api/v1/auth/telemetry", json=payload)
        print("Status:", response.status_code)
        print("Response:", response.json())
        
        # 4. Check DB for canonical fields
        print("\n--- Verifying MongoDB ---")
        inserted_session = await db.telemetry_events.find_one({"session_id": "e2e_test_session_999"})
        event = inserted_session["events"][0]
        print(f"Propagated item_id: {event.get('item_id')}")
        print(f"Propagated error_type: {event.get('error_type')}")
        print(f"Propagated correction_count: {event.get('correction_count')}")
        
        # 5. Check Therapist Dashboard endpoint
        print("\n--- Fetching Therapist C1 Dashboard ---")
        app.dependency_overrides[get_current_user] = lambda: {"_id": parent_id, "role": "therapist"}
        c1_res = await client.get(f"/api/v1/therapist/students/{str(student_id)}/c1-behavioral")
        print("Status:", c1_res.status_code)
        c1_data = c1_res.json()
        print(json.dumps(c1_data, indent=2))
        
        assert event.get('item_id') == "S2A1R01"
        assert event.get('knowledge_component_id') == "KC_AKSHARA_IDENTITY"
        assert event.get('attempt_count') == 3
        assert event.get('incorrect_attempt_count') == 2
        assert event.get('first_attempt_correct') == False
        assert event.get('final_correct') == True
        assert event.get('selected_answers') == ["A", "A", "B"]

        print("Asserting Derived Behavioral Data...")
        assert c1_data.get('first_attempt_accuracy') == 0.0
        assert c1_data.get('mean_attempts_per_round') == 3.0
        assert c1_data.get('kc_performance', {}).get('KC_AKSHARA_IDENTITY') == 0.0


        print("\n>>> ALL ASSERTIONS PASSED! <<<")

if __name__ == "__main__":
    asyncio.run(test_real_payload())
