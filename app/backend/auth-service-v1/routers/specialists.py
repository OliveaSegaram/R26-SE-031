"""
routers/specialists.py
======================
Endpoints for specialist-parent connections.
"""

from fastapi import APIRouter, HTTPException, status, Depends
from bson.objectid import ObjectId

from shared.database import get_db
from dependencies import get_current_user
from schemas.specialist import SpecialistConnectRequest, SpecialistConnectResponse

router = APIRouter(prefix="/api/v1/specialists", tags=["Specialists"])

@router.post("/connect", response_model=SpecialistConnectResponse)
async def connect_specialist(req: SpecialistConnectRequest, current_user: dict = Depends(get_current_user)):
    db = get_db()
    
    # Verify the current user is a parent
    if current_user.get("role") != "parent":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Only parents can connect specialists."
        )
        
    # Verify the student belongs to the parent
    try:
        student_oid = ObjectId(req.student_id)
    except:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid student ID format.")
        
    student = await db.students.find_one({"_id": student_oid, "parent_id": str(current_user["_id"])})
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Student not found or doesn't belong to you."
        )
        
    # Find the specialist by clinic_code
    specialist = await db.users.find_one({"role": "specialist", "clinic_code": req.clinic_code.upper()})
    if not specialist:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Invalid clinic code. Please check with your specialist."
        )
        
    # Create or update connection
    await db.connections.update_one(
        {"student_id": str(student["_id"]), "specialist_id": str(specialist["_id"])},
        {"$set": {"parent_consent": True}},
        upsert=True
    )
    
    return {"message": "Successfully connected to the specialist!"}

@router.get("/students")
async def get_connected_students(current_user: dict = Depends(get_current_user)):
    db = get_db()
    
    # Verify the current user is a specialist
    if current_user.get("role") != "specialist":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Only specialists can access connected students."
        )
        
    # Find all connections for this specialist
    connections_cursor = db.connections.find({"specialist_id": str(current_user["_id"])})
    connections = await connections_cursor.to_list(length=100)
    
    if not connections:
        return []
        
    # Get student IDs
    student_ids = [ObjectId(c["student_id"]) for c in connections]
    
    # Fetch student details
    students_cursor = db.students.find({"_id": {"$in": student_ids}})
    students = await students_cursor.to_list(length=100)
    
    # Clean up output
    output = []
    for s in students:
        s["id"] = str(s["_id"])
        del s["_id"]
        # Do not return sensitive fields like parent_password
        if "parent_password" in s:
            del s["parent_password"]
        output.append(s)
        
    return output
