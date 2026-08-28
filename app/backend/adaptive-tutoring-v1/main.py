from fastapi import FastAPI, HTTPException
from schemas import InteractionRequest, TutoringResponse, NextAction
from database import connect_to_mongo, close_mongo_connection
import database
from services.bkt_engine import bkt_engine
from services.irt_engine import irt_engine
from services.policy_engine import policy_engine

app = FastAPI(title="Adaptive Tutoring Service", version="1.0")

@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()

@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "adaptive-tutoring-v1"}

@app.post("/update_interaction", response_model=TutoringResponse)
async def update_interaction(request: InteractionRequest):
    # Retrieve Learner DB State
    student_doc = await database.knowledge_states_collection.find_one({"student_id": request.student_id})
    db = database.get_db()
    
    if student_doc and "knowledge_state" in student_doc:
        knowledge_state = student_doc["knowledge_state"]
        theta = student_doc.get("theta_estimate", 0.0)
    else:
        knowledge_state = {
            "KC_LETTER_IDENTITY": bkt_engine.priors.get("KC_LETTER_IDENTITY", bkt_engine.priors["default"])[0],
            "KC_VISUAL_DISCRIMINATION": bkt_engine.priors.get("KC_VISUAL_DISCRIMINATION", bkt_engine.priors["default"])[0]
        }
        theta = 0.0
        
    current_prob = knowledge_state.get(request.knowledge_component_id, bkt_engine.priors["default"][0])
    
    # Fetch Item parameters from Item Bank
    item_doc = await db.item_bank.find_one({"item_id": request.item_id})
    item_b = item_doc.get("difficulty_b", 0.0) if item_doc else 0.0
    
    # 1. Update BKT State
    new_prob = bkt_engine.update_knowledge_state(
        current_prob=current_prob,
        target_kc=request.knowledge_component_id,
        is_correct=request.is_correct
    )
    knowledge_state[request.knowledge_component_id] = new_prob
    
    # 2. Update IRT Theta
    theta_new = irt_engine.update_theta(
        theta_old=theta,
        is_correct=request.is_correct,
        b_i=item_b,
        learning_rate=0.5
    )
    
    # 3. Policy Engine Decision
    policy_output = policy_engine.get_next_action(
        kc_mastery=new_prob,
        fatigue_score=request.fatigue_score,
        current_activity=request.activity_id,
        learner_profile=request.learner_profile
    )
    
    # Update DB
    await database.knowledge_states_collection.update_one(
        {"student_id": request.student_id},
        {"$set": {
            "knowledge_state": knowledge_state,
            "theta_estimate": theta_new
        }},
        upsert=True
    )
    
    next_action = NextAction(
        next_activity=policy_output["next_activity"],
        next_item=policy_output["next_item"],
        difficulty=policy_output["difficulty"],
        scaffold_level=policy_output["scaffold_level"],
        decision=policy_output["decision"]
    )
    
    return TutoringResponse(
        student_id=request.student_id,
        updated_knowledge_state=knowledge_state,
        next_action=next_action
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8017, reload=False)
