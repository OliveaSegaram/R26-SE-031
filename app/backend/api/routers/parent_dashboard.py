from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from schemas.dashboards import (
    ParentOverviewDTO,
    ParentReadingFluencyDTO,
    ParentReadingProgressDTO,
    ParentLearningPatternDTO,
    ParentActivityHistoryDTO,
    ActivityHistoryItem,
    RoundJourneyItem,
    RecommendedPracticeItem,
    AdaptiveInsightItem,
    ParentAdaptiveInsightsDTO
)
import sys
from pathlib import Path as PathLib
sys.path.insert(0, str(PathLib(__file__).parent.parent.parent.parent))
from shared.database import get_db
from services.dashboard_access import require_dashboard_access
from services.dashboard_data import KC_NAMES, number, timestamp, records, base, pattern_profile, research_evidence

router=APIRouter(prefix="/api/v1/parent/students",tags=["Parent Dashboard"],dependencies=[Depends(require_dashboard_access)])

@router.get("/{student_id}/overview",response_model=ParentOverviewDTO)
async def get_parent_overview(student_id:str):
    db=get_db(); summaries=await records(db,"session_summaries",student_id)
    latest=summaries[0] if summaries else {}
    student = None
    try:
        from bson import ObjectId
        student = await db.students.find_one({"_id": ObjectId(student_id)})
    except Exception:
        pass
    assessment = (student or {}).get("comprehensive_assessment_results") or {}
    category_counts = {
        key: sum(1 for item in value if isinstance(item, dict) and item.get("answer") is True)
        for key, value in assessment.items() if isinstance(value, list)
    }
    assessment_summary = {
        "completed_categories": len([v for v in assessment.values() if isinstance(v, list) and v]),
        "total_categories": 4,
        "reported_observations": sum(category_counts.values()),
        "by_category": category_counts,
        "reviewed": (student or {}).get("reviewed_assessments") or {},
    }
    sessions=await db.session_summaries.distinct("session_id",{"student_id":student_id})
    pipeline=[{"$match":{"student_id":student_id,"schema_version":"2.0"}},
              {"$group":{"_id":"$session_id","seconds":{"$max":"$session_duration_seconds"}}},
              {"$group":{"_id":None,"seconds":{"$sum":"$seconds"}}}]
    durations=await db.telemetry_sessions.aggregate(pipeline).to_list(length=1)
    accuracy=number((latest.get("overall") or {}).get("accuracy"))
    return ParentOverviewDTO(**base(student_id,latest,"Latest accuracy; all completed sessions and measured session duration"),
        accuracy=round(accuracy*100) if accuracy is not None else None,
        practice_time_minutes=round(durations[0]["seconds"]/60) if durations else None,
        sessions_completed=len([x for x in sessions if x]), reading_progress="Practice recorded" if summaries else "No observations yet",
        assessment_summary=assessment_summary)

@router.get("/{student_id}/assessment-summary")
async def get_parent_assessment_summary(student_id: str):
    db = get_db()
    try:
        from bson import ObjectId
        student = await db.students.find_one({"_id": ObjectId(student_id)})
    except Exception:
        student = None
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    assessment = student.get("comprehensive_assessment_results") or {}
    category_counts = {
        key: sum(1 for item in value if isinstance(item, dict) and item.get("answer") is True)
        for key, value in assessment.items() if isinstance(value, list)
    }
    
    return {
        "student_id": student_id,
        "completed_categories": len([v for v in assessment.values() if isinstance(v, list) and v]),
        "total_categories": 4,
        "reported_observations": sum(category_counts.values()),
        "by_category": category_counts,
        "raw_responses": assessment
    }

@router.get("/{student_id}/fluency",response_model=ParentReadingFluencyDTO)
async def get_parent_fluency(student_id:str):
    return ParentReadingFluencyDTO(**base(student_id),fluency_status="Fluency score is not implemented; mastery is not fluency",fluency_score=None)

@router.get("/{student_id}/progress",response_model=ParentReadingProgressDTO)
async def get_parent_progress(student_id:str):
    rows=(await records(get_db(),"session_summaries",student_id))[:10]
    trend=[]
    for r in reversed(rows):
        value=number((r.get("overall") or {}).get("accuracy"))
        trend.append({"session":r.get("session_id"),"accuracy":round(value*100) if value is not None else None})
    return ParentReadingProgressDTO(**base(student_id,rows[0] if rows else {},"Latest 10 sessions, chronological"),accuracy_trend=trend)

@router.get("/{student_id}/skills")
async def get_parent_skills(student_id:str):
    rows=await records(get_db(),"knowledge_states",student_id,1); doc=rows[0] if rows else {}
    skills=[{"skill_name":KC_NAMES.get(k,k),"mastery_percentage":round(v*100),"status":"Model estimate, not a test grade"}
            for k,x in (doc.get("knowledge_state") or {}).items() if (v:=number(x)) is not None]
    return {**base(student_id,doc),"skills":skills}

@router.get("/{student_id}/learning-pattern",response_model=ParentLearningPatternDTO)
async def get_parent_learning_pattern(student_id:str):
    rows=await records(get_db(),"learner_profiles",student_id,1); doc=rows[0] if rows else {}
    _,_,pattern=pattern_profile(doc)
    origin=doc.get("data_origin","unspecified")
    obs=(f"Synthetic demonstration: the experimental model produced a {pattern} pattern. This is not a finding about your child."
         if origin=="synthetic" else f"Experimental model output: {pattern}. Input provenance is {origin}; this does not establish a learning difficulty." if doc else "No learning-pattern evidence is available yet.")
    return ParentLearningPatternDTO(**base(student_id,doc),observation=obs,recommended_practices=[])

@router.get("/{student_id}/activity-history",response_model=ParentActivityHistoryDTO)
async def get_parent_activity_history(student_id:str,limit:int=Query(10,ge=1,le=50),days:Optional[int]=Query(None,ge=1,le=365)):
    db=get_db(); rows=await records(db,"session_summaries",student_id)
    cutoff=(datetime.now(timezone.utc)-timedelta(days=days)).isoformat().replace("+00:00","Z") if days else None
    if cutoff: rows=[r for r in rows if (timestamp(r) or "")>=cutoff]
    history=[]
    for r in rows:
        raw=await db.telemetry_sessions.find_one({"student_id":student_id,"session_id":r.get("session_id"),"schema_version":"2.0"})
        for aid,metrics in (r.get("activity_breakdown") or {}).items():
            # Sum matching actual round durations; never multiply first-touch by trial count.
            events=[e for e in (raw or {}).get("events",[]) if e.get("activity_id")==aid]
            durations=[number(e.get("total_round_latency_ms")) for e in events]
            duration=sum(durations)/60000 if durations and all(v is not None for v in durations) else None
            accuracy=number(metrics.get("accuracy"))
            history.append(dict(session_id=r.get("session_id"),session_date=(timestamp(r) or "Unavailable")[:10],activity_name=aid,
                accuracy=round(accuracy*100) if accuracy is not None else None,duration_minutes=round(duration) if duration is not None else None,
                duration_source="sum of recorded round durations" if duration is not None else "unavailable"))
            if len(history)>=limit: break
        if len(history)>=limit: break
    return ParentActivityHistoryDTO(**base(student_id,rows[0] if rows else {},"Recent activity observations"),history=history)

@router.get("/{student_id}/research-evidence")
async def get_parent_evidence(student_id:str):
    return await research_evidence(get_db(),student_id)

# ==========================================
# ACTIVITY NAME MAPPING (Skill 2)
# ==========================================
SKILL2_ACTIVITY_NAMES = {
    "2.1": "අකුරු හඳුනමු (Letter Identification)",
    "2.2": "අකුරු ගලපමු (Letter Matching)",
    "2.3": "අහලා හඳුනමු (Listen & Identify)",
    "2.4": "අකුරු කියවමු (Letter Decoding)",
    "2.5": "අකුරු මතක තබමු (Letter Memory)",
}

SKILL2_ROUNDS_TOTAL = {
    "2.1": 7,
    "2.2": 5,
    "2.3": 5,
    "2.4": 5,
    "2.5": 5,
}

# Core round item patterns (regex-free check)
CORE_ITEM_PREFIXES = {
    "2.1": "S2A1R",
    "2.2": "S2A2R",
    "2.3": "S2A3R",
    "2.4": "S2A4R",
    "2.5": "S2A5R",
}

# Activity metadata for recommendations
ACTIVITY_METADATA = {
    "2.1": {"template_type": "skill2_odd_one_out", "rounds": 7},
    "2.2": {"template_type": "skill2_identical_match", "rounds": 5},
    "2.3": {"template_type": "skill2_audio", "rounds": 5},
    "2.4": {"template_type": "skill2_mcq", "rounds": 5},
    "2.5": {"template_type": "skill2_pattern_memory", "rounds": 5},
}

# KC-based recommendation map: activity -> [rec1, rec2]
RECOMMENDATION_MAP = {
    "2.1": [
        {"id": "2.2", "description": "Strengthens letter matching skills"},
        {"id": "2.3", "description": "Practice letters through sounds"},
    ],
    "2.2": [
        {"id": "2.1", "description": "Strengthens letter recognition"},
        {"id": "2.3", "description": "Practice letters through sounds"},
    ],
    "2.3": [
        {"id": "2.1", "description": "Strengthens visual letter recognition"},
        {"id": "2.2", "description": "Practice matching identical letters"},
    ],
    "2.4": [
        {"id": "2.1", "description": "Builds letter recognition foundation"},
        {"id": "2.3", "description": "Strengthens sound-letter connection"},
    ],
    "2.5": [
        {"id": "2.2", "description": "Reinforces letter matching for memory"},
        {"id": "2.1", "description": "Strengthens letter recognition"},
    ],
}

def _build_recommendations(activity_id: str, remediation_count: int, guided_rounds: int) -> list:
    """Build recommended practice items when child needed help."""
    if remediation_count == 0 and guided_rounds == 0:
        return []
    
    recs = RECOMMENDATION_MAP.get(activity_id, [])
    result = []
    for rec in recs:
        rec_id = rec["id"]
        meta = ACTIVITY_METADATA.get(rec_id, {})
        result.append(RecommendedPracticeItem(
            activity_id=rec_id,
            activity_name=SKILL2_ACTIVITY_NAMES.get(rec_id, f"Activity {rec_id}"),
            description=rec["description"],
            template_type=meta.get("template_type", ""),
            rounds_count=meta.get("rounds", 5)
        ))
    return result

def _is_core_item(activity_id: str, item_id: str) -> bool:
    """Check if an item is a core round (not a variant/remediation)."""
    prefix = CORE_ITEM_PREFIXES.get(activity_id, "")
    if not prefix or not item_id:
        return False
    # Core items: S2A1R01, S2A2R03, etc. (no V suffix)
    return item_id.startswith(prefix) and "V" not in item_id and item_id != "COMPLETE" and item_id != "RESET"

def _extract_round_number(item_id: str) -> int:
    """Extract round number from item_id like S2A1R03 -> 3."""
    try:
        # Find the R and take the digits after it
        r_idx = item_id.rindex("R")
        num_str = item_id[r_idx + 1:].replace("V", "").replace("v", "")[:2]
        return int(num_str)
    except (ValueError, IndexError):
        return 0

def _get_round_result(quality: str, needed_remediation: bool) -> dict:
    """Map response quality + remediation to parent-friendly icon/text."""
    q = (quality or "").upper()
    if q in ["CLEAN_SUCCESS", "MASTERED", "INDEPENDENT_SUCCESS"] and not needed_remediation:
        return {"icon": "⭐", "text": "Got it right!"}
    elif q in ["STRUGGLED_SUCCESS"] and not needed_remediation:
        return {"icon": "👍", "text": "Figured it out after thinking"}
    elif q in ["ASSISTED_SUCCESS"]:
        return {"icon": "💡", "text": "Solved with a helpful hint"}
    elif needed_remediation:
        return {"icon": "📝", "text": "Got extra practice, then solved it"}
    else:
        return {"icon": "👍", "text": "Good attempt"}


@router.get("/{student_id}/adaptive-insights", response_model=ParentAdaptiveInsightsDTO)
async def get_adaptive_insights(student_id: str = Path(...)):
    """Return parent-friendly adaptive learning insights for all Skill 2 activities.
    
    Aggregates ALL decision records per activity to compute concrete, accurate metrics
    instead of relying on misleading BKT probability percentages.
    """
    db = get_db()
    
    skill2_activities = ["2.1", "2.2", "2.3", "2.4", "2.5"]
    activities = []
    
    for act_id in skill2_activities:
        # Get ALL decisions for this activity, sorted chronologically
        cursor = db.adaptive_decisions.find(
            {"student_id": student_id, "activity_id": act_id}
        ).sort("_id", 1)
        all_records = await cursor.to_list(length=500)
        
        if not all_records:
            continue
        
        rounds_total = SKILL2_ROUNDS_TOTAL.get(act_id, 5)
        
        # --- Find the latest session's records ---
        # Group by looking for the last RESET or first R01 item
        latest_session_records = all_records  # Default: use all records
        
        # Find the last reset/fresh start point
        last_start_idx = 0
        for i, rec in enumerate(all_records):
            item = rec.get("current_item", "")
            if item == "RESET":
                last_start_idx = i + 1
            elif _is_core_item(act_id, item) and _extract_round_number(item) == 1:
                # Check if this is a restart (not the very first record)
                if i > 0:
                    last_start_idx = i
        
        latest_session_records = all_records[last_start_idx:]
        
        if not latest_session_records:
            continue
        
        # --- 1. Completion Progress ---
        completed_core_rounds = set()
        is_activity_complete = False
        
        for rec in latest_session_records:
            item = rec.get("current_item", "")
            decision = rec.get("decision", "")
            
            if _is_core_item(act_id, item) and rec.get("is_correct", False):
                rn = _extract_round_number(item)
                if rn > 0:
                    completed_core_rounds.add(rn)
            
            if decision in ["ACTIVITY_COMPLETE", "CURRICULUM_COMPLETE"]:
                is_activity_complete = True
        
        rounds_completed = len(completed_core_rounds)
        if is_activity_complete:
            rounds_completed = rounds_total
            completion_text = "Activity Complete! ✅"
        else:
            completion_text = f"{rounds_completed} of {rounds_total} puzzles done"
        
        # --- 2. First-Try Accuracy ---
        # For each core round, check if the FIRST attempt was correct without scaffold
        first_try_results = {}  # round_num -> was_first_try_correct
        seen_core_rounds = set()
        
        for rec in latest_session_records:
            item = rec.get("current_item", "")
            if not _is_core_item(act_id, item):
                continue
            rn = _extract_round_number(item)
            if rn == 0 or rn in seen_core_rounds:
                continue
            seen_core_rounds.add(rn)
            
            quality = rec.get("response_quality", "")
            is_first_try = quality in ["CLEAN_SUCCESS", "MASTERED", "INDEPENDENT_SUCCESS"]
            first_try_results[rn] = is_first_try
        
        first_try_correct = sum(1 for v in first_try_results.values() if v)
        first_try_total = len(first_try_results)
        
        if first_try_total == 0:
            accuracy_text = "No rounds attempted yet"
        elif first_try_correct == first_try_total:
            accuracy_text = f"Got all {first_try_correct} right on the first try! ⭐"
        elif first_try_correct > 0:
            accuracy_text = f"Got {first_try_correct} of {first_try_total} right on the first try"
        else:
            accuracy_text = "Needed some practice, but kept trying!"
        
        # --- 3. App Adaptation Story (Remediation Count) ---
        remediation_count = 0
        remediation_rounds = set()
        
        for rec in latest_session_records:
            decision = rec.get("decision", "")
            policy_reasons = rec.get("policy_reason", [])
            
            if decision == "REMEDIATION":
                rn_item = rec.get("current_item", "")
                rn = _extract_round_number(rn_item) if rn_item else 0
                if rn > 0 and rn not in remediation_rounds:
                    remediation_rounds.add(rn)
                    remediation_count += 1
            # Also check policy_reason for remediation triggers
            for reason in policy_reasons:
                if "STRUGGLED" in str(reason) and "REMEDIATION" not in str(reason):
                    pass  # Already counted via decision
        
        if remediation_count == 0:
            adaptation_text = "Sailed through all puzzles! 🎯"
        elif remediation_count == 1:
            adaptation_text = "The app gave extra practice on 1 tricky puzzle to help 📝"
        else:
            adaptation_text = f"The app gave extra practice on {remediation_count} puzzles to help 📝"
        
        # --- 4. Independence Level ---
        independent_rounds = 0
        guided_rounds = 0
        
        for rec in latest_session_records:
            item = rec.get("current_item", "")
            if not _is_core_item(act_id, item):
                continue
            
            scaffold = rec.get("scaffold_level", 0)
            quality = rec.get("response_quality", "")
            
            if rec.get("is_correct", False):
                if scaffold == 0 and quality in ["CLEAN_SUCCESS", "MASTERED", "INDEPENDENT_SUCCESS"]:
                    independent_rounds += 1
                else:
                    guided_rounds += 1
        
        total_judged = independent_rounds + guided_rounds
        if total_judged == 0:
            independence_text = "No data yet"
            independence_badge = "Getting Started 🌱"
        elif independent_rounds == total_judged:
            independence_text = f"Solved all {independent_rounds} independently!"
            independence_badge = "Independent Learner 🌟"
        elif independent_rounds > guided_rounds:
            independence_text = f"Solved {independent_rounds} independently, needed hints on {guided_rounds}"
            independence_badge = "Independent Learner 🌟"
        elif independent_rounds > 0:
            independence_text = f"Solved {independent_rounds} independently, needed hints on {guided_rounds}"
            independence_badge = "Guided Learner 💡"
        else:
            independence_text = f"Needed guidance on all {guided_rounds} puzzles"
            independence_badge = "Supported Learner 🤝"
        
        # --- 5. Round Journey ---
        round_journey = []
        core_round_records = {}  # round_num -> first core record
        remediation_triggered = set()
        
        for rec in latest_session_records:
            item = rec.get("current_item", "")
            decision = rec.get("decision", "")
            
            if _is_core_item(act_id, item):
                rn = _extract_round_number(item)
                if rn > 0 and rn not in core_round_records:
                    core_round_records[rn] = rec
            
            # Track which rounds triggered remediation
            if decision == "REMEDIATION":
                for reason in rec.get("policy_reason", []):
                    if "STRUGGLED" in str(reason):
                        rn_str = str(reason)
                        for r in range(1, rounds_total + 1):
                            if f"R{r}" in rn_str:
                                remediation_triggered.add(r)
                                break
        
        for rn in sorted(core_round_records.keys()):
            rec = core_round_records[rn]
            quality = rec.get("response_quality", "")
            needed_rem = rn in remediation_triggered
            result = _get_round_result(quality, needed_rem)
            
            was_first_try = quality in ["CLEAN_SUCCESS", "MASTERED", "INDEPENDENT_SUCCESS"]
            
            round_journey.append(RoundJourneyItem(
                round_number=rn,
                result_icon=result["icon"],
                result_text=result["text"],
                was_first_try=was_first_try,
                needed_remediation=needed_rem
            ))
        
        # --- 6. Overall Rating ---
        if first_try_total > 0:
            first_try_ratio = first_try_correct / first_try_total
        else:
            first_try_ratio = 0
        
        if first_try_ratio >= 0.8 and remediation_count == 0:
            star_rating = 3
            rating_text = "⭐⭐⭐ Excellent!"
        elif first_try_ratio >= 0.5 or (is_activity_complete and remediation_count <= 2):
            star_rating = 2
            rating_text = "⭐⭐ Good Progress!"
        else:
            star_rating = 1
            rating_text = "⭐ Keep Practicing!"
        
        # --- Meta ---
        last_record = latest_session_records[-1]
        last_played = last_record.get("timestamp", "")
        times_played = len(all_records)
        
        # --- 7. Recommended Practice ---
        recommendations = _build_recommendations(act_id, remediation_count, guided_rounds)
        
        activities.append(AdaptiveInsightItem(
            activity_id=act_id,
            activity_name=SKILL2_ACTIVITY_NAMES.get(act_id, f"Activity {act_id}"),
            rounds_completed=rounds_completed,
            rounds_total=rounds_total,
            is_activity_complete=is_activity_complete,
            completion_text=completion_text,
            first_try_correct=first_try_correct,
            first_try_total=first_try_total,
            accuracy_text=accuracy_text,
            remediation_count=remediation_count,
            adaptation_text=adaptation_text,
            independent_rounds=independent_rounds,
            guided_rounds=guided_rounds,
            independence_text=independence_text,
            independence_badge=independence_badge,
            round_journey=round_journey,
            star_rating=star_rating,
            rating_text=rating_text,
            recommendations=recommendations,
            last_played=last_played,
            times_played=times_played
        ))
    
    return ParentAdaptiveInsightsDTO(
        updated_at=get_current_time_str(),
        student_id=student_id,
        reporting_period="Latest Session",
        activities=activities
    )

@router.get("/{student_id}/report")
async def download_parent_report(student_id:str):
    raise HTTPException(501,"Parent PDF export is not implemented; no placeholder PDF is returned.")
