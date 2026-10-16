from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import re
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
    if not durations:
        # Read-only compatibility for pre-v2 stores where the complete session
        # document lived in telemetry_events. New writes still use
        # telemetry_sessions, so this does not duplicate current data.
        legacy_pipeline=[{"$match":{"student_id":student_id}},
                         {"$group":{"_id":"$session_id","seconds":{"$max":"$session_duration_seconds"}}},
                         {"$group":{"_id":None,"seconds":{"$sum":"$seconds"}}}]
        durations=await db.telemetry_events.aggregate(legacy_pipeline).to_list(length=1)
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
        if raw is None:
            raw=await db.telemetry_events.find_one({
                "student_id":student_id,
                "session_id":r.get("session_id"),
                "events":{"$exists":True},
            })
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
# REVIEWED ACTIVITY METADATA (Skills 1-4)
# ==========================================
ACTIVITY_NAMES = {
    "1.1": "සැඟවුණු පින්තූර සොයමු (Hidden Picture Search)",
    "1.2": "සෙවණැල්ලට පින්තූරය ගළපමු (Shadow Matching)",
    "1.3": "පින්තූර වෙන් කරමු (Picture Sorting)",
    "1.4": "රටාව සම්පූර්ණ කරමු (Pattern Completion)",
    "1.5": "පින්තූර මතකයෙන් සොයමු (Picture Memory)",
    "2.1": "අකුරු හඳුනමු (Letter Identification)",
    "2.2": "අකුරු ගලපමු (Letter Matching)",
    "2.3": "අහලා හඳුනමු (Listen & Identify)",
    "2.4": "අකුරු කියවමු (Letter Decoding)",
    "2.5": "අකුරු මතක තබමු (Letter Memory)",
    "3.1": "පින්තූරයට වචනය තෝරමු (Choose the Word)",
    "3.2": "අකුරුවලින් වචන හදමු (Build Words)",
    "3.3": "වචන අසා හඳුනා ගනිමු (Listen & Identify Words)",
    "3.4": "අඩු අකුර සොයමු (Find the Missing Letter)",
    "3.5": "අකුරු පිළිවෙළට සකසමු (Order the Letters)",
    "4.1": "පින්තූරයට වාක්‍යය තෝරමු (Choose the Sentence)",
    "4.2": "වචන යොදා වාක්‍ය හදමු (Build Sentences)",
    "4.3": "වාක්‍ය අසා හඳුනා ගනිමු (Listen & Identify Sentences)",
    "4.4": "වචන පිළිවෙළට සකසමු (Order the Words)",
}

ACTIVITY_ROUNDS_TOTAL = {
    **{f"1.{activity}": 5 for activity in range(1, 6)},
    "2.1": 7,
    "2.2": 5,
    "2.3": 5,
    "2.4": 5,
    "2.5": 5,
    **{f"3.{activity}": 5 for activity in range(1, 6)},
    **{f"4.{activity}": 4 for activity in range(1, 5)},
}

SKILL2_ACTIVITY_NAMES = {
    key: value for key, value in ACTIVITY_NAMES.items() if key.startswith("2.")
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
    if not item_id:
        return False
    match = re.fullmatch(r"S(\d+)A(\d+)R(\d+)", str(item_id), re.IGNORECASE)
    return bool(match and f"{int(match.group(1))}.{int(match.group(2))}" == activity_id)

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
    """Return one current, parent-friendly card per attempted Skill 1-4 activity.

    Each card is restricted to that activity's latest session. This keeps a replay
    from inflating the round journey while ensuring that starting Activity 3 does
    not hide completed Activities 1 and 2.
    """
    db = get_db()
    all_decisions = await db.adaptive_decisions.find(
        {"student_id": student_id}
    ).sort("_id", -1).limit(2000).to_list(length=2000)

    # Rows arrive newest-first. Select the newest session independently for every
    # activity rather than selecting one global session for the whole dashboard.
    latest_session_by_activity: Dict[str, Optional[str]] = {}
    for row in all_decisions:
        activity_id = str(row.get("activity_id"))
        if activity_id in ACTIVITY_NAMES and activity_id not in latest_session_by_activity:
            latest_session_by_activity[activity_id] = row.get("session_id")

    latest_records_by_activity: Dict[str, List[Dict[str, Any]]] = {}
    for activity_id, session_id in latest_session_by_activity.items():
        matching = [
            row for row in all_decisions
            if str(row.get("activity_id")) == activity_id
            and (
                row.get("session_id") == session_id
                if session_id
                else not row.get("session_id")
            )
        ]
        # Current clients always provide a session ID. For legacy rows without one,
        # cap the view to a single curriculum-sized journey rather than presenting
        # every historic database row as one play.
        if not session_id:
            matching = matching[:20]
        latest_records_by_activity[activity_id] = list(reversed(matching))

    summary_decisions = [
        row
        for records_for_activity in latest_records_by_activity.values()
        for row in records_for_activity
    ]
    if not summary_decisions and all_decisions:
        # Compatibility for pre-item-bank rows that did not persist activity_id.
        latest_legacy_session = all_decisions[0].get("session_id")
        summary_decisions = (
            [row for row in all_decisions if row.get("session_id") == latest_legacy_session]
            if latest_legacy_session else all_decisions[:20]
        )
    completed = len(summary_decisions)
    independent = sum(
        1 for row in summary_decisions
        if row.get("response_quality") in {"CLEAN_SUCCESS", "INDEPENDENT_SUCCESS", "MASTERED"}
    )
    supported = sum(
        1 for row in summary_decisions if row.get("response_quality") == "ASSISTED_SUCCESS"
    )
    remediation = sum(1 for row in summary_decisions if row.get("decision") == "REMEDIATION")
    confirmation = sum(1 for row in summary_decisions if row.get("next_phase") == "CONFIRMATION")
    if completed == 0:
        plain_message = "No completed learning tasks are available yet."
    elif supported == 0:
        plain_message = f"Your child completed {completed} tasks without recorded hints."
    else:
        plain_message = (
            f"Your child completed {completed} tasks. The app provided help on "
            f"{supported} tasks and then checked learning with a new task."
        )
    support_summary = {
        "completed_tasks": completed,
        "independent_successes": independent,
        "supported_successes": supported,
        "remediation_routes": remediation,
        "confirmation_checks": confirmation,
        "plain_message": plain_message,
        "scope": "Latest attempt for each activity in Skills 1–4",
        "session_id": None,
        "activity_count": len(latest_records_by_activity),
        "session_count": len({
            str(row.get("session_id")) for row in summary_decisions
            if row.get("session_id")
        }),
    }
    
    def activity_sort_key(activity_id: str):
        try:
            skill, activity = activity_id.split(".", 1)
            return int(skill), int(activity)
        except (AttributeError, TypeError, ValueError):
            return 999, 999

    activity_ids = sorted(latest_records_by_activity, key=activity_sort_key)
    activities = []

    for act_id in activity_ids:
        # all_decisions is newest first; calculations below require chronology.
        all_records = [
            row for row in all_decisions if str(row.get("activity_id")) == act_id
        ]
        latest_session_records = latest_records_by_activity.get(act_id, [])
        if not latest_session_records:
            continue
        rounds_total = ACTIVITY_ROUNDS_TOTAL.get(act_id, 5)
        
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
        independence_by_round = {}
        
        for rec in latest_session_records:
            item = rec.get("current_item", "")
            if not _is_core_item(act_id, item):
                continue
            rn = _extract_round_number(item)
            if rn <= 0:
                continue
            
            scaffold = rec.get("scaffold_level", 0)
            quality = rec.get("response_quality", "")
            
            if rec.get("is_correct", False):
                if scaffold == 0 and quality in ["CLEAN_SUCCESS", "MASTERED", "INDEPENDENT_SUCCESS"]:
                    independence_by_round.setdefault(rn, True)
                else:
                    independence_by_round[rn] = False

        independent_rounds = sum(1 for value in independence_by_round.values() if value)
        guided_rounds = sum(1 for value in independence_by_round.values() if not value)
        
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
                rn = _extract_round_number(item)
                if rn > 0:
                    remediation_triggered.add(rn)
        
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
        distinct_sessions = {
            str(row.get("session_id")) for row in all_records if row.get("session_id")
        }
        # Legacy rows did not carry session_id. They establish that the activity
        # was played, but are not mislabelled as one play per database record.
        times_played = len(distinct_sessions) or (1 if all_records else 0)
        
        # --- 7. Recommended Practice ---
        recommendations = _build_recommendations(act_id, remediation_count, guided_rounds)
        
        activities.append(AdaptiveInsightItem(
            activity_id=act_id,
            activity_name=ACTIVITY_NAMES.get(act_id, f"Activity {act_id}"),
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
    
    latest_policy = await db.policy_decisions.find_one(
        {"student_id": student_id},
        sort=[("_id", -1)],
    )
    execution_source = (latest_policy or {}).get(
        "execution_source", "deterministic_capability_policy"
    )
    if execution_source == "synthetic_model_simulation":
        policy_notice = (
            "Research demonstration mode is active: the app's practice model "
            "chooses among safe, pre-approved help options. This demonstrates "
            "how personalisation works; it is not a diagnosis."
        )
    elif (latest_policy or {}).get("controls_live_adaptation"):
        policy_notice = (
            "The validated learning-support model chooses among safe, "
            "pre-approved help options. It does not diagnose your child."
        )
    else:
        policy_notice = (
            "Your child's learning is guided by tested support rules. Research "
            "predictions are monitored in the background and do not control activities."
        )

    return ParentAdaptiveInsightsDTO(
        **base(
            student_id,
            all_decisions[0] if all_decisions else None,
            "Latest available adaptive observations",
        ),
        activities=activities,
        support_summary=support_summary,
        policy_notice=policy_notice,
    )

@router.get("/{student_id}/report")
async def download_parent_report(student_id:str):
    raise HTTPException(501,"Parent PDF export is not implemented; no placeholder PDF is returned.")
