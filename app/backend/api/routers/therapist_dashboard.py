from fastapi import APIRouter, Depends, HTTPException, Response
from schemas.dashboards import (TherapistOverviewDTO, TherapistC1BehavioralDTO, TherapistC2SpeechDTO,
                                TherapistC3ProfileDTO, TherapistC4AdaptiveDTO)
from shared.database import get_db
from services.dashboard_access import require_dashboard_access
from services.dashboard_data import (KC_NAMES, number, timestamp, records, mlbase, speech, pattern_profile,
                                     mastery_status, research_evidence)

router = APIRouter(prefix="/api/v1/therapist/students", tags=["Therapist Dashboard"],
                   dependencies=[Depends(require_dashboard_access)])

@router.get("/{student_id}/overview", response_model=TherapistOverviewDTO)
async def get_therapist_overview(student_id: str):
    db = get_db()
    summaries = await records(db, "session_summaries", student_id)
    speeches = await records(db, "speech_features", student_id, 1)
    profiles = await records(db, "learner_profiles", student_id, 1)
    states = await records(db, "knowledge_states", student_id, 1)
    decisions = await records(db, "adaptive_decisions", student_id, 1)
    latest = summaries[0] if summaries else {}
    values = [number(v) for v in (states[0].get("knowledge_state", {}) if states else {}).values()]
    values = [v for v in values if v is not None]
    mastery = sum(values)/len(values) if values else None
    profile, _, pattern = pattern_profile(profiles[0] if profiles else {})
    fatigue = number(latest.get("behavioral_fatigue_proxy"))
    from bson import ObjectId
    student_doc = None
    try:
        student_doc = await db.students.find_one({"_id": ObjectId(student_id)})
    except Exception:
        pass
    session_ids = await db.session_summaries.distinct("session_id", {"student_id": student_id})
    assessment_results = student_doc.get("assessment_results", []) if student_doc else []
    comprehensive_assessment_results = student_doc.get("comprehensive_assessment_results", {}) if student_doc else {}
    reviewed_assessments = student_doc.get("reviewed_assessments", {}) if student_doc else {}

    first_name = student_doc.get("first_name") if student_doc else None
    last_name = student_doc.get("last_name") if student_doc else None
    student_name = f"{first_name or ''} {last_name or ''}".strip() if (first_name or last_name) else None
    grade = student_doc.get("grade", "Grade 1") if student_doc else "Grade 1"
    age = student_doc.get("age") if student_doc else None
    avatar_url = student_doc.get("avatar_url") if student_doc else None

    parent_name = None
    if student_doc and "parent_id" in student_doc:
        try:
            parent_doc = await db.users.find_one({"_id": ObjectId(student_doc["parent_id"])})
            if parent_doc:
                parent_name = parent_doc.get("name")
        except Exception:
            pass

    return TherapistOverviewDTO(**mlbase(student_id, latest, "descriptive + BKT/IRT", "c1-v2"),
        accuracy=number((latest.get("overall") or {}).get("accuracy")), attempted_items=latest.get("total_trials", 0),
        completed_sessions=len([x for x in session_ids if x]), reading_fluency_status=mastery_status(mastery),
        overall_mastery=mastery, current_pattern=pattern, pattern_confidence=number(profile.get("confidence")),
        fatigue_status="Unavailable" if fatigue is None else f"Proxy {fatigue:.2f} (not a diagnosis)",
        last_active=timestamp(latest), c1_available=bool(summaries), c2_available=bool(speeches),
        c3_available=bool(profiles), c4_available=bool(states),
        latest_recommendation=decisions[0].get("decision_reason") if decisions else None,
        assessment_results=assessment_results,
        comprehensive_assessment_results=comprehensive_assessment_results,
        reviewed_assessments=reviewed_assessments,
        first_name=first_name,
        last_name=last_name,
        student_name=student_name,
        grade=grade,
        age=age,
        avatar_url=avatar_url,
        parent_name=parent_name)

@router.get("/{student_id}/c1-behavioral", response_model=TherapistC1BehavioralDTO)
async def get_therapist_c1_behavioral(student_id: str):
    history = (await records(get_db(), "session_summaries", student_id))[:10]
    latest = history[0] if history else {}
    overall, errors, kcs = latest.get("overall") or {}, latest.get("error_profile") or {}, latest.get("knowledge_components") or {}
    def trend(field, fatigue=False):
        return [{"session": row.get("session_id"), "value": number(row.get("behavioral_fatigue_proxy") if fatigue else (row.get("overall") or {}).get(field))} for row in reversed(history)]
    has_errors = (number(overall.get("error_rate")) or 0) > 0
    return TherapistC1BehavioralDTO(**mlbase(student_id, latest, "descriptive", "c1-v2"), session_id=latest.get("session_id"),
        first_attempt_accuracy=number(overall.get("accuracy")), median_response_latency_ms=number(overall.get("median_response_latency_ms")),
        retry_rate=number(overall.get("retry_rate")), mean_attempts_per_round=number(overall.get("mean_attempts_per_round")),
        median_time_to_correct_ms=number(overall.get("median_time_to_correct_ms")), correction_rate=number(overall.get("correction_rate")),
        behavioral_fatigue_proxy=number(latest.get("behavioral_fatigue_proxy")),
        kc_performance={kc:number((kcs.get(kc) or {}).get("accuracy")) for kc in KC_NAMES},
        error_distribution={k:number(errors.get(k+"_rate")) if has_errors else None for k in ("visual_confusion", "phonological_confusion", "sequence_error", "unknown_error")},
        trends=dict(accuracy=trend("accuracy"), latency=trend("median_response_latency_ms"), fatigue=trend("", True)))

@router.get("/{student_id}/c2-speech", response_model=TherapistC2SpeechDTO)
async def get_therapist_c2_speech(student_id: str):
    history = (await records(get_db(), "speech_features", student_id))[:10]
    latest = history[0] if history else {}
    def trend(key):
        return [{"session":row.get("session_id"),"value":speech(row)[key]} for row in reversed(history)]
    return TherapistC2SpeechDTO(**mlbase(student_id, latest, "speech prototype", "speech-v1"), latest=speech(latest),
        trends=dict(accuracy=[], wer=trend("wer"), latency=trend("acoustic_latency_ms"), silence_ratio=trend("silence_ratio"), peak_delta=trend("peak_delta")))

@router.get("/{student_id}/c3-profile", response_model=TherapistC3ProfileDTO)
async def get_therapist_c3_profile(student_id: str):
    db = get_db()
    rows = await records(db, "learner_profiles", student_id, 1)
    audit_rows = await records(db, "model_audit_log", student_id, 20)
    audit = next(
        (row for row in audit_rows if row.get("model_name") == "XGBoost"),
        {},
    )
    doc = rows[0] if rows else {}
    profile, probs, pattern = pattern_profile(doc)
    explanations=[]
    for f in (doc.get("shap_explanations") or {}).get("top_contributing_features", []):
        contribution=number(f.get("shap_impact"))
        if contribution is not None:
            explanations.append(dict(feature=f.get("feature_name", ""), contribution=contribution,
                observed_value=number(f.get("observed_value", f.get("value"))),
                direction="increases model score" if contribution>0 else "decreases model score" if contribution<0 else "neutral"))
    pipeline_status = audit.get("status") or ("profile_available" if rows else "not_run")
    missing_inputs = list(audit.get("missing_features") or [])
    skip_reason = None
    if not rows and pipeline_status == "skipped_missing_inputs":
        skip_reason = "C3 fusion was safely skipped because required inputs were unavailable."
    elif not rows:
        skip_reason = "Insufficient linked multimodal data to generate a learner profile."
    metadata = mlbase(student_id, doc or audit, "XGBoost", "c3-fusion-v1")
    metadata["available"] = bool(rows)
    return TherapistC3ProfileDTO(**metadata, primary_pattern=pattern,
        probabilities=probs, confidence=number(profile.get("confidence")), modalities_used=profile.get("modalities_used") or [],
        shap_explanations=explanations, llm_summary=doc.get("llm_summary"), llm_recommendations=doc.get("llm_recommendations"),
        pipeline_status=pipeline_status, missing_inputs=missing_inputs,
        skip_reason=skip_reason)

@router.get("/{student_id}/c4-adaptive", response_model=TherapistC4AdaptiveDTO)
async def get_therapist_c4_adaptive(student_id: str, window: int = 20):
    db=get_db()
    window=max(5,min(int(window),100))
    states=await records(db,"knowledge_states",student_id,1)
    state=states[0] if states else {}
    all_history=[
        row for row in await records(db,"adaptive_decisions",student_id,500)
        if row.get("research_eligible") is not False
    ]
    history=all_history[:window]

    def independent(row):
        first=row.get("first_attempt_correct")
        if first is None:
            first=str(row.get("response_quality") or "").upper() in {
                "CLEAN_SUCCESS","INDEPENDENT_SUCCESS","MASTERED"
            }
        return bool(first is True and int(row.get("scaffold_level_used",row.get("scaffold_level",0)) or 0)==0)

    mastery_values=[]
    for kc_id,raw_value in (state.get("knowledge_state") or {}).items():
        value=number(raw_value)
        if value is not None and 0 <= value <= 1:
            mastery_values.append((str(kc_id),value))
    primary_focus=min(mastery_values,key=lambda pair:pair[1]) if mastery_values else None
    primary_id=primary_focus[0] if primary_focus else None
    primary_name=(
        KC_NAMES.get(primary_id,primary_id.removeprefix("KC_").replace("_"," ").title())
        if primary_id else "Unavailable"
    )

    core_rows=[row for row in history if str(row.get("item_role") or "CORE").upper()=="CORE"]
    confirmation_rows=[row for row in history if str(row.get("item_role") or "").upper()=="CONFIRMATION"]
    independent_core=sum(1 for row in core_rows if independent(row))
    supported_core=len(core_rows)-independent_core
    independent_confirmations=sum(1 for row in confirmation_rows if independent(row))

    trend_source=[
        row for row in reversed(all_history[:100])
        if number(row.get("mastery_after")) is not None
        and (primary_id is None or row.get("kc_id")==primary_id)
    ]
    if not trend_source:
        trend_source=[
            row for row in reversed(all_history[:100])
            if number(row.get("mastery_after")) is not None
        ]
    mastery_trend=[{
        "timestamp": timestamp(row),
        "value": number(row.get("mastery_after")),
        "item_id": row.get("current_item"),
        "activity_id": row.get("activity_id"),
        "knowledge_component_id": row.get("kc_id"),
    } for row in trend_source[-6:]]

    target_groups={}
    for row in all_history[:100]:
        activity=str(row.get("activity_id") or "")
        for raw_unit in (row.get("struggled_target_units") or []):
            unit=str(raw_unit).strip()
            if not unit:
                continue
            group=target_groups.setdefault(unit,{
                "unit":unit,"observations":0,"activities":set(),"last_observed_at":None
            })
            group["observations"]+=1
            if activity:
                group["activities"].add(activity)
            group["last_observed_at"]=group["last_observed_at"] or timestamp(row)
    recurring_targets=[]
    for group in target_groups.values():
        if group["observations"] < 2:
            continue
        recurring_targets.append({
            **group,
            "activities":sorted(group["activities"]),
        })
    recurring_targets=sorted(
        recurring_targets,key=lambda row:(row["observations"],len(row["activities"])),reverse=True
    )[:6]

    focus_rows=[row for row in all_history if primary_id and row.get("kc_id")==primary_id]
    plan_source=(focus_rows or all_history)
    plan_activity=str(plan_source[0].get("activity_id") or "") if plan_source else ""
    activity_parts=plan_activity.split(".")
    practice_available=(
        len(activity_parts)==2
        and all(part.isdigit() for part in activity_parts)
        and 1 <= int(activity_parts[0]) <= 4
        and 1 <= int(activity_parts[1]) <= 5
    )
    focus_evidence=(
        f"Current {primary_name.lower()} mastery estimate is {round(primary_focus[1]*100)}%."
        if primary_focus else "More observed tasks are needed before selecting a focus."
    )
    next_session_plan={
        "focus_knowledge_component_id":primary_id,
        "focus_name":primary_name,
        "activity_id":plan_activity or None,
        "minutes":5,
        "practice_available":practice_available,
        "evidence":focus_evidence,
        "instruction":(
            f"Use reviewed {primary_name.lower()} practice for 5 minutes, then check learning with a fresh equivalent item."
            if primary_focus else "Continue normal activities while the app gathers more learning evidence."
        ),
    }

    latest_measurement_se = None
    timeline=[]
    for d in reversed(history):
        reason_codes = d.get("policy_reason") or []
        if isinstance(reason_codes, str):
            reason_codes = [reason_codes]
        measurement_se = number(d.get("measurement_standard_error"))
        if measurement_se is not None:
            latest_measurement_se = measurement_se
        timeline.append(dict(timestamp=timestamp(d) or "Unavailable", mastery_before=number(d.get("mastery_before")),
            mastery_after=number(d.get("mastery_after")), fatigue=number(d.get("behavioral_fatigue_indicator", d.get("fatigue_score"))),
            previous_difficulty=number(d.get("difficulty_b", d.get("previous_difficulty"))), selected_difficulty=number(d.get("selected_difficulty")),
            scaffold_level=d.get("scaffold_level",0), next_activity=d.get("next_activity",d.get("selected_activity","Unavailable")),
            decision=d.get("decision", "Unavailable"),
            reason=d.get("decision_reason") or ", ".join(reason_codes) or "Unavailable",
            reason_codes=reason_codes,item_id=d.get("current_item"),
            knowledge_component_id=d.get("kc_id"),response_quality=d.get("response_quality")))
    policy_rows=(await records(db,"policy_decisions",student_id))[:100]
    c3_audit_rows=await records(db,"model_audit_log",student_id,20)
    c3_audit=next(
        (row for row in c3_audit_rows if row.get("model_name") == "XGBoost"),
        {},
    )
    action_groups = {}
    for row in policy_rows:
        action = row.get("applied_action") or "Unavailable"
        group = action_groups.setdefault(action, {"action": action, "uses": 0, "outcomes": 0, "independent_successes": 0})
        group["uses"] += 1
        if row.get("outcome_observed") is True:
            group["outcomes"] += 1
            group["independent_successes"] += int(row.get("outcome_first_attempt_correct") is True)
    effectiveness = []
    for group in action_groups.values():
        outcomes = group["outcomes"]
        effectiveness.append({
            **group,
            "next_independent_success_rate": (
                round(group["independent_successes"] / outcomes, 4)
                if outcomes else None
            ),
        })
    latest_policy = policy_rows[0] if policy_rows else {}
    origins = sorted({str(row.get("data_origin") or "unspecified") for row in policy_rows})
    comparable_policy_rows = [
        row for row in policy_rows
        if row.get("model_recommendation") and row.get("applied_action")
    ]
    recommendation_agreements = sum(
        1 for row in comparable_policy_rows
        if row.get("model_recommendation") == row.get("applied_action")
    )
    model_status = latest_policy.get("model_validation_status", "unavailable")
    policy_mode = latest_policy.get("policy_mode", "baseline")
    controls_live_adaptation = bool(
        latest_policy.get("controls_live_adaptation")
        or (
            policy_mode == "model"
            and model_status in {"pilot_approved", "validated_observed"}
        )
    )
    execution_source = latest_policy.get(
        "execution_source", "deterministic_capability_policy"
    )
    # The Skill 1-2 cross-activity target-memory experiment is retired. Keep
    # the response field for API compatibility, but do not surface historical
    # experimental rows as current therapist recommendations.
    persistent_learning_needs = []
    return TherapistC4AdaptiveDTO(**mlbase(student_id,state,"BKT + Rasch + action-outcome shadow model","c4-v3"),
        knowledge_components=[dict(id=k,name=KC_NAMES.get(k,k),mastery=v) for k,x in (state.get("knowledge_state") or {}).items() if (v:=number(x)) is not None],
        theta=number(state.get("theta_estimate")), theta_se=number(state.get("theta_se")), updated_at_state=timestamp(state), history=timeline,
        policy_status={
            "mode": policy_mode,
            "applied_policy": execution_source,
            "model_version": latest_policy.get("model_version"),
            "model_validation_status": model_status,
            "fallback_reason": latest_policy.get("fallback_reason"),
            "controls_live_adaptation": controls_live_adaptation,
            "evidence_scope": (
                "Synthetic-trained model simulation; functional evidence only, not child efficacy"
                if execution_source == "synthetic_model_simulation"
                else "Observed shadow comparison; descriptive, not causal"
                if policy_rows else "No action-policy observations yet"
            ),
        },
        latest_policy_decision={key: latest_policy.get(key) for key in (
            "timestamp", "item_id", "candidate_actions", "model_recommendation",
            "model_confidence", "applied_action", "predicted_next_independent_success",
            "action_utilities", "execution_source", "controls_live_adaptation",
            "proximal_next_response_correct", "proximal_response_phase",
            "outcome_first_attempt_correct", "outcome_response_quality", "outcome_item_id",
        )},
        support_effectiveness=sorted(effectiveness, key=lambda row: row["action"]),
        persistent_learning_needs=persistent_learning_needs,
        summary={
            "window_decisions":len(history),
            "primary_focus_id":primary_id,
            "primary_focus_name":primary_name,
            "primary_mastery":primary_focus[1] if primary_focus else None,
            "core_tasks":len(core_rows),
            "independent_core_tasks":independent_core,
            "supported_core_tasks":supported_core,
            "support_dependence_rate":(
                round(supported_core/len(core_rows),4) if core_rows else None
            ),
            "confirmation_tasks":len(confirmation_rows),
            "independent_confirmations":independent_confirmations,
            "independent_transfer_rate":(
                round(independent_confirmations/len(confirmation_rows),4)
                if confirmation_rows else None
            ),
        },
        mastery_trend=mastery_trend,
        recurring_targets=recurring_targets,
        next_session_plan=next_session_plan,
        data_quality={
            "decision_rows": len(history),
            "available_decision_rows":len(all_history),
            "window_size":window,
            "policy_rows": len(policy_rows),
            "policy_rows_with_proximal_outcomes": sum(1 for row in policy_rows if row.get("proximal_outcome_observed") is True),
            "policy_rows_with_outcomes": sum(1 for row in policy_rows if row.get("outcome_observed") is True),
            "recommendation_comparisons": len(comparable_policy_rows),
            "recommendation_agreements": recommendation_agreements,
            "recommendation_agreement_rate": (
                round(recommendation_agreements / len(comparable_policy_rows), 4)
                if comparable_policy_rows else None
            ),
            "data_origins": origins,
            "c3_pipeline_status": c3_audit.get("status") or "not_run",
            "c3_missing_inputs": list(c3_audit.get("missing_features") or []),
            "calibration_warning": "Rasch/BKT calibration requires an approved observed cohort; synthetic rows are excluded.",
        })

@router.get("/{student_id}/research-evidence")
async def get_therapist_evidence(student_id: str):
    return await research_evidence(get_db(),student_id)

@router.get("/{student_id}/research-summary")
async def get_therapist_research_summary(student_id: str):
    result={"student_id":student_id}
    for key,fn in (("c1_behavioral",get_therapist_c1_behavioral),("c2_speech",get_therapist_c2_speech),
                   ("c3_profile",get_therapist_c3_profile),("c4_adaptive",get_therapist_c4_adaptive)):
        result[key]=(await fn(student_id)).model_dump()
    result["research_evidence"]=await get_therapist_evidence(student_id)
    return result

@router.get("/{student_id}/report/pdf")
async def get_therapist_research_pdf(student_id: str):
    from utils.research_report_generator import generate_research_pdf
    d=await get_therapist_research_summary(student_id)
    content=generate_research_pdf(student_id,d["c1_behavioral"],d["c2_speech"],d["c3_profile"],d["c4_adaptive"])
    return Response(content=content,media_type="application/pdf",headers={"Content-Disposition":f'attachment; filename="Sipsara_Report_{student_id}.pdf"'})

from pydantic import BaseModel
class ReviewAssessmentRequest(BaseModel):
    reviewed: bool = True

@router.patch("/{student_id}/review-assessment/{category}")
async def review_assessment(student_id: str, category: str, req: ReviewAssessmentRequest):
    db = get_db()
    from bson import ObjectId
    try:
        obj_id = ObjectId(student_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid student ID")
    
    field = f"reviewed_assessments.{category}"
    await db.students.update_one(
        {"_id": obj_id},
        {"$set": {field: req.reviewed}}
    )
    student_doc = await db.students.find_one({"_id": obj_id})
    return {
        "student_id": student_id,
        "category": category,
        "reviewed": req.reviewed,
        "reviewed_assessments": student_doc.get("reviewed_assessments", {}) if student_doc else {}
    }
