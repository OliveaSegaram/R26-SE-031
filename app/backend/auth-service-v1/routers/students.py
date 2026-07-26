"""
routers/students.py
===================
Student management endpoints: add, list, update.

CRITICAL: Every query filters by parent_id to ensure complete data isolation
between parent accounts.
"""

from fastapi import APIRouter, HTTPException, status, Depends
from bson.objectid import ObjectId

from shared.database import get_db
from schemas.students import StudentCreate, StudentUpdate, StudentResponse, AssessmentSubmit
from services.auth_utils import verify_password
from dependencies import get_current_user

router = APIRouter(prefix="/api/v1/auth", tags=["Students"])


@router.post("/students", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)
async def add_student(request: StudentCreate, current_user: dict = Depends(get_current_user)):
    """Add a new student under the authenticated parent's account."""
    # 1. Verification of parent password is no longer required

    db = get_db()
    parent_oid = current_user["_id"]  # This is always a BSON ObjectId from MongoDB

    # 2. Check if username is taken globally
    existing = await db.students.find_one({"username": request.username.lower()})
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists")

    # 3. Create student document — parent_id is stored as ObjectId for consistency
    student_doc = {
        "parent_id": parent_oid,
        "first_name": request.first_name,
        "last_name": request.last_name,
        "username": request.username.lower(),
        "grade": "Grade 1",  # Locked to Grade 1
        "daily_limit": request.daily_limit,
        "assessment_results": request.assessment_results,
        "avatar_url": request.avatar_url,
        "consent_given": request.consent_given,
        "consent_parent_name": request.consent_parent_name,
        "consent_date": request.consent_date,
    }

    result = await db.students.insert_one(student_doc)

    return StudentResponse(
        id=str(result.inserted_id),
        first_name=request.first_name,
        last_name=request.last_name,
        username=request.username,
        grade="Grade 1",
        daily_limit=request.daily_limit,
        avatar_url=request.avatar_url,
        assessment_results=request.assessment_results,
        assessment_completed=len(request.assessment_results) == 14,
    )


@router.get("/students", response_model=list[StudentResponse])
async def list_students(current_user: dict = Depends(get_current_user)):
    """List all students belonging to the authenticated parent.

    ISOLATION: Only returns students whose parent_id matches the
    current user's MongoDB _id (ObjectId).
    """
    db = get_db()
    parent_oid = current_user["_id"]

    # Query using the exact ObjectId — this guarantees isolation
    cursor = db.students.find({"parent_id": parent_oid})
    students = await cursor.to_list(length=100)

    result = []
    for s in students:
        assessment = s.get("assessment_results", [])
        result.append(StudentResponse(
            id=str(s["_id"]),
            first_name=s["first_name"],
            last_name=s["last_name"],
            username=s["username"],
            grade=s.get("grade", "Grade 1"),
            daily_limit=s.get("daily_limit", "No Limit"),
            avatar_url=s.get("avatar_url"),
            assessment_results=assessment,
            assessment_completed=len(assessment) == 14,
        ))

    return result


@router.put("/students/{student_id}", response_model=StudentResponse)
async def update_student(student_id: str, request: StudentUpdate, current_user: dict = Depends(get_current_user)):
    """Update a student's details. Only the owning parent can update."""
    provider = current_user.get("auth_provider", "local")
    is_social = provider in ["google", "microsoft"] or not current_user.get("hashed_password")
    if not is_social:
        if not verify_password(request.parent_password, current_user["hashed_password"]):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect parent password")

    try:
        obj_id = ObjectId(student_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid student ID")

    db = get_db()
    parent_oid = current_user["_id"]

    # Ensure student belongs to THIS parent
    existing_student = await db.students.find_one({"_id": obj_id, "parent_id": parent_oid})
    if not existing_student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

    # Check username collision (allow same username for same student)
    existing_username = await db.students.find_one({"username": request.username.lower(), "_id": {"$ne": obj_id}})
    if existing_username:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists")

    update_doc = {
        "first_name": request.first_name,
        "last_name": request.last_name,
        "username": request.username.lower(),
        "grade": "Grade 1",  # Locked to Grade 1
        "daily_limit": request.daily_limit,
        "avatar_url": request.avatar_url,
    }

    await db.students.update_one({"_id": obj_id}, {"$set": update_doc})

    updated = await db.students.find_one({"_id": obj_id})
    assessment = updated.get("assessment_results", [])
    return StudentResponse(
        id=str(obj_id),
        first_name=request.first_name,
        last_name=request.last_name,
        username=request.username,
        grade="Grade 1",
        daily_limit=request.daily_limit,
        avatar_url=request.avatar_url,
        assessment_results=assessment,
        assessment_completed=len(assessment) == 14,
    )


@router.patch("/students/{student_id}/assessment", response_model=StudentResponse)
async def submit_assessment(student_id: str, request: AssessmentSubmit, current_user: dict = Depends(get_current_user)):
    """Submit assessment results for an existing student. Only the owning parent can do this."""
    try:
        obj_id = ObjectId(student_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid student ID")

    db = get_db()
    parent_oid = current_user["_id"]

    # Ensure student belongs to THIS parent
    existing_student = await db.students.find_one({"_id": obj_id, "parent_id": parent_oid})
    if not existing_student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

    await db.students.update_one(
        {"_id": obj_id},
        {"$set": {"assessment_results": request.assessment_results}}
    )

    return StudentResponse(
        id=str(obj_id),
        first_name=existing_student["first_name"],
        last_name=existing_student["last_name"],
        username=existing_student["username"],
        grade=existing_student.get("grade", "Grade 1"),
        daily_limit=existing_student.get("daily_limit", "No Limit"),
        avatar_url=existing_student.get("avatar_url"),
        assessment_results=request.assessment_results,
        assessment_completed=True,
    )
