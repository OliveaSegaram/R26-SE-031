from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime, timedelta
from bson import ObjectId
import secrets
import string

from dependencies import get_current_user
from shared.database import get_db
from schemas.therapist import ConnectionCode, TherapistConnectionResponse, ConnectSpecialistRequest

router = APIRouter(prefix="/api/v1/auth/therapist", tags=["therapist"])

def generate_clinic_code(length=6):
    chars = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))

@router.post("/generate-code", response_model=ConnectionCode)
async def generate_connection_code(current_user: dict = Depends(get_current_user)):
    """Generate a unique 6-digit clinic code for a therapist."""
    if current_user.get("role") != "therapist":
        raise HTTPException(status_code=403, detail="Only therapists can generate clinic codes")
        
    db = get_db()
    
    # Check if they already have an active code that hasn't expired
    existing_code = await db.clinic_codes.find_one({"therapist_id": current_user["_id"]})
    
    # Always regenerate for simplicity
    new_code = generate_clinic_code()
    expires_at = datetime.utcnow() + timedelta(hours=24)
    
    await db.clinic_codes.update_one(
        {"therapist_id": current_user["_id"]},
        {"$set": {
            "clinic_code": new_code,
            "expires_at": expires_at
        }},
        upsert=True
    )
    
    return ConnectionCode(clinic_code=new_code, expires_at=expires_at)


@router.post("/connect", response_model=TherapistConnectionResponse)
async def connect_specialist(request: ConnectSpecialistRequest, current_user: dict = Depends(get_current_user)):
    """Parent submits a clinic code to link a student to a therapist."""
    db = get_db()
    
    # 1. Find the clinic code from users collection
    therapist = await db.users.find_one({
        "role": "specialist",
        "clinic_code": request.clinic_code.upper()
    })
    
    if not therapist:
        raise HTTPException(status_code=404, detail="Invalid clinic code. Please check with your specialist.")
        
    # 2. Verify the student belongs to the current user (parent)
    try:
        student_obj_id = ObjectId(request.student_id)
    except:
        raise HTTPException(status_code=400, detail="Invalid student ID format")
        
    student = await db.students.find_one({
        "_id": student_obj_id,
        "parent_id": current_user["_id"]
    })
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found or access denied")
        
    # 3. Get therapist details (already have it)
    
    # 4. Create the connection
    connection = {
        "therapist_id": str(therapist["_id"]),
        "student_id": request.student_id,
        "parent_id": str(current_user["_id"]),
        "status": "active",
        "connected_at": datetime.utcnow()
    }
    
    # Use upsert to avoid duplicate connections
    result = await db.therapist_connections.update_one(
        {
            "therapist_id": connection["therapist_id"],
            "student_id": connection["student_id"]
        },
        {"$set": connection},
        upsert=True
    )
    
    # Fetch it back to return
    new_conn = await db.therapist_connections.find_one({
        "therapist_id": connection["therapist_id"],
        "student_id": connection["student_id"]
    })
    
    return TherapistConnectionResponse(
        id=str(new_conn["_id"]),
        therapist_id=new_conn["therapist_id"],
        student_id=new_conn["student_id"],
        student_name=student.get("first_name"),
        therapist_name=therapist.get("name"),
        clinic_name="AdaptedMind Clinic", # Could be dynamic later
        status=new_conn["status"],
        connected_at=new_conn["connected_at"]
    )


@router.get("/connections", response_model=List[TherapistConnectionResponse])
async def get_connections(current_user: dict = Depends(get_current_user)):
    """Get all connections for the current user (either parent or therapist)."""
    db = get_db()
    
    query = {}
    if current_user.get("role") == "specialist":
        query["therapist_id"] = str(current_user["_id"])
    else:
        query["parent_id"] = str(current_user["_id"])
        
    cursor = db.therapist_connections.find(query)
    connections = await cursor.to_list(length=100)
    
    result = []
    for conn in connections:
        # Populate names for the UI
        student = await db.students.find_one({"_id": ObjectId(conn["student_id"])})
        therapist = await db.users.find_one({"_id": ObjectId(conn["therapist_id"])})
        
        result.append(TherapistConnectionResponse(
            id=str(conn["_id"]),
            therapist_id=conn["therapist_id"],
            student_id=conn["student_id"],
            student_name=student.get("first_name") if student else "Unknown",
            therapist_name=therapist.get("name") if therapist else "Unknown",
            clinic_name="AdaptedMind Clinic",
            status=conn["status"],
            connected_at=conn["connected_at"]
        ))
        
    return result


@router.delete("/disconnect/{connection_id}")
async def disconnect_specialist(connection_id: str, current_user: dict = Depends(get_current_user)):
    """Delete a connection permanently."""
    db = get_db()
    
    # We should ensure the user has permission to delete this connection.
    # It must belong to either the parent or the therapist.
    query = {"_id": ObjectId(connection_id)}
    if current_user.get("role") == "specialist":
        query["therapist_id"] = str(current_user["_id"])
    else:
        query["parent_id"] = str(current_user["_id"])
        
    result = await db.therapist_connections.delete_one(query)
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Connection not found or permission denied.")
        
    return {"message": "Connection successfully deleted."}
