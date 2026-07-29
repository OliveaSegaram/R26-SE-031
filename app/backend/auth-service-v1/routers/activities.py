from fastapi import APIRouter, HTTPException

router = APIRouter(
    prefix="/api/v1/auth/activities",
    tags=["Activities CMS"]
)

# Mocked CMS database for activities
MOCK_ACTIVITIES_DB = {
    "visual_processing": {
        "id": "visual_processing",
        "title": "Visual Processing",
        "intro_text": "Let's play some visual games!",
        "audio_url": "",
        "activities": [
            {
                "id": "act_1",
                "title": "Odd One Out",
                "template_type": "odd_one_out_game",
                "audio_url": "",
                "rounds": [
                    {"image": "url_to_image", "target": "apple"}
                ]
            },
            {
                "id": "act_2",
                "title": "Complete Pattern",
                "template_type": "pattern_game",
                "audio_url": "",
                "rounds": []
            },
            {
                "id": "act_3",
                "title": "Pattern Memory",
                "template_type": "pattern_memory_game",
                "audio_url": "",
                "rounds": []
            }
        ]
    }
}

@router.get("/{skill_id}")
async def get_activities_for_skill(skill_id: str):
    """
    Returns the dynamic JSON configuration for all activities within a skill.
    This replaces hardcoded Flutter JSON assets, enabling over-the-air updates.
    """
    skill_data = MOCK_ACTIVITIES_DB.get(skill_id)
    if not skill_data:
        # For now, return an empty structure so the app doesn't crash on unmocked skills
        return {
            "id": skill_id,
            "title": skill_id.replace("_", " ").title(),
            "activities": []
        }
    
    return skill_data
