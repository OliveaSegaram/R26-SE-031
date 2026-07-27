"""
routers/telemetry.py
====================
Telemetry and monitoring data endpoints.
"""

from fastapi import APIRouter, HTTPException, status, Depends
from bson.objectid import ObjectId

from shared.database import get_db
from dependencies import get_current_user
from schemas.telemetry import TelemetrySessionSubmit

router = APIRouter(prefix="/api/v1/auth", tags=["Telemetry"])

@router.post("/telemetry", status_code=status.HTTP_201_CREATED)
async def submit_telemetry(req: TelemetrySessionSubmit, current_user: dict = Depends(get_current_user)):
    db = get_db()
    
    # Ensure the parent making this request actually owns the student
    try:
        student_oid = ObjectId(req.student_id)
    except:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid student ID format.")
        
    student = await db.students.find_one({"_id": student_oid, "parent_id": current_user["_id"]})
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Student not found or doesn't belong to you."
        )
        
    session_doc = req.model_dump()
    session_doc["student_id"] = str(student_oid) # store as string for easier querying
    
    await db.telemetry.insert_one(session_doc)
    
    return {"message": "Telemetry session logged successfully."}

@router.get("/telemetry/{student_id}")
async def get_telemetry(student_id: str, current_user: dict = Depends(get_current_user)):
    db = get_db()
    
    try:
        student_oid = ObjectId(student_id)
    except:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid student ID format.")
    
    # Check permissions (either the parent, or a connected specialist)
    if current_user.get("role") == "specialist":
        connection = await db.connections.find_one({
            "student_id": student_id,
            "specialist_id": str(current_user["_id"])
        })
        if not connection:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not connected to this student.")
    else:
        # Parent check
        student = await db.students.find_one({"_id": student_oid, "parent_id": current_user["_id"]})
        if not student:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found.")
            
    # Fetch telemetry history
    cursor = db.telemetry.find({"student_id": student_id}).sort("events.0.timestamp", -1)
    sessions = await cursor.to_list(length=100)
    
    for s in sessions:
        s["id"] = str(s["_id"])
        del s["_id"]
        
    return sessions
