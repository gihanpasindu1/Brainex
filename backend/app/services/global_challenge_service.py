from datetime import datetime, timedelta, timezone
from typing import Literal

from bson import ObjectId
from fastapi import HTTPException

from app.db.mongo import (
    global_challenge_participants_col,
    global_challenge_progress_col,
    global_challenge_submissions_col,
    global_challenges_col,
)
from app.services.friend_challenge_service import _build_challenge_questions
from app.services.rag_service import generate_mcqs
from app.services.user_profile_service import (
    award_global_challenge_completion_xp,
    award_global_challenge_first_place_bonus,
    award_global_challenge_top_10_bonus,
)

SRI_LANKA_TZ = timezone(timedelta(hours=5, minutes=30), name="Asia/Colombo")
GLOBAL_CHALLENGE_DAYS = {0: "Monday", 2: "Wednesday", 4: "Friday"}
GLOBAL_CHALLENGE_START_HOUR = 20
GLOBAL_CHALLENGE_DURATION_SECONDS = 2 * 60 * 60
GLOBAL_CHALLENGE_QUESTION_COUNT = 50
GLOBAL_CHALLENGE_DIFFICULTY = "Medium"
GLOBAL_CHALLENGE_PAPER_TYPE = "Final"
GLOBAL_CHALLENGE_GRADE = "13"
GLOBAL_CHALLENGE_REMINDER_MINUTES = [30, 10]


def _utc_now() -> datetime:
    return datetime.utcnow()


def _as_aware_utc(dt: datetime) -> datetime:
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _challenge_phase(challenge_doc: dict, now_utc: datetime) -> str:
    if now_utc < challenge_doc["scheduled_start_at"]:
        return "upcoming"
    if now_utc < challenge_doc["scheduled_end_at"]:
        return "live"
    return "ended"


def _challenge_slot_key(start_at_utc: datetime) -> str:
    return _as_aware_utc(start_at_utc).astimezone(SRI_LANKA_TZ).strftime("%Y-%m-%d")


def _build_week_slots(now_utc: datetime) -> list[dict]:
    now_lk = _as_aware_utc(now_utc).astimezone(SRI_LANKA_TZ)
    slots: list[dict] = []
    candidate_date = now_lk.date()

    while len(slots) < len(GLOBAL_CHALLENGE_DAYS):
        weekday_index = candidate_date.weekday()
        label = GLOBAL_CHALLENGE_DAYS.get(weekday_index)
        if label is None:
            candidate_date += timedelta(days=1)
            continue

        scheduled_start_lk = datetime(
            year=candidate_date.year,
            month=candidate_date.month,
            day=candidate_date.day,
            hour=GLOBAL_CHALLENGE_START_HOUR,
            minute=0,
            second=0,
            tzinfo=SRI_LANKA_TZ,
        )
        scheduled_end_lk = scheduled_start_lk + timedelta(seconds=GLOBAL_CHALLENGE_DURATION_SECONDS)
        if scheduled_end_lk <= now_lk:
            candidate_date += timedelta(days=1)
            continue

        slots.append(
            {
                "day_label": label,
                "slot_key": scheduled_start_lk.strftime("%Y-%m-%d"),
                "scheduled_start_at": scheduled_start_lk.astimezone(timezone.utc).replace(
                    tzinfo=None
                ),
                "scheduled_end_at": scheduled_end_lk.astimezone(timezone.utc).replace(
                    tzinfo=None
                ),
                "reminder_times": [
                    (
                        scheduled_start_lk - timedelta(minutes=minutes)
                    ).astimezone(timezone.utc).replace(tzinfo=None)
                    for minutes in GLOBAL_CHALLENGE_REMINDER_MINUTES
                ],
            }
        )
        candidate_date += timedelta(days=1)

    slots.sort(key=lambda item: item["scheduled_start_at"])
    return slots


async def _create_challenge_doc_for_slot(slot: dict, now_utc: datetime) -> dict:
    generated_questions = await generate_mcqs(
        grade=GLOBAL_CHALLENGE_GRADE,
        paper_type=GLOBAL_CHALLENGE_PAPER_TYPE,
        term=None,
        difficulty=GLOBAL_CHALLENGE_DIFFICULTY,
        mcq_count=GLOBAL_CHALLENGE_QUESTION_COUNT,
        topic=None,
    )
    if len(generated_questions) < GLOBAL_CHALLENGE_QUESTION_COUNT:
        raise HTTPException(
            status_code=500,
            detail="Could not generate enough questions for the global challenge",
        )

    title = (
        f"{slot['day_label']} Global Challenge - "
        f"{_as_aware_utc(slot['scheduled_start_at']).astimezone(SRI_LANKA_TZ).strftime('%b %d')}"
    )
    challenge_doc = {
        "slot_key": slot["slot_key"],
        "title": title,
        "paper_type": GLOBAL_CHALLENGE_PAPER_TYPE,
        "difficulty": GLOBAL_CHALLENGE_DIFFICULTY,
        "grade": GLOBAL_CHALLENGE_GRADE,
        "term": None,
        "topic": None,
        "duration_seconds": GLOBAL_CHALLENGE_DURATION_SECONDS,
        "question_count": GLOBAL_CHALLENGE_QUESTION_COUNT,
        "questions": _build_challenge_questions(generated_questions[:GLOBAL_CHALLENGE_QUESTION_COUNT]),
        "scheduled_start_at": slot["scheduled_start_at"],
        "scheduled_end_at": slot["scheduled_end_at"],
        "reminder_times": slot["reminder_times"],
        "created_at": now_utc,
    }
    result = await global_challenges_col.insert_one(challenge_doc)
    saved_doc = await global_challenges_col.find_one({"_id": result.inserted_id})
    if not saved_doc:
        raise HTTPException(status_code=500, detail="Global challenge creation failed")
    return saved_doc


async def preload_weekly_challenge_docs() -> dict:
    now_utc = _utc_now()
    slots = _build_week_slots(now_utc)
    challenge_docs: list[dict] = []
    created_count = 0

    for slot in slots:
        existing = await global_challenges_col.find_one({"slot_key": slot["slot_key"]})
        if existing:
            challenge_docs.append(existing)
            continue

        created_doc = await _create_challenge_doc_for_slot(slot, now_utc)
        created_count += 1
        challenge_docs.append(created_doc)

    challenge_docs.sort(key=lambda item: item["scheduled_start_at"])
    return {
        "created_count": created_count,
        "total_count": len(challenge_docs),
        "challenges": challenge_docs,
    }


async def _get_weekly_challenge_docs() -> list[dict]:
    slots = _build_week_slots(_utc_now())
    challenge_docs: list[dict] = []

    for slot in slots:
        existing = await global_challenges_col.find_one({"slot_key": slot["slot_key"]})
        if existing:
            challenge_docs.append(existing)

    challenge_docs.sort(key=lambda item: item["scheduled_start_at"])
    return challenge_docs


async def _get_challenge_doc_or_404(challenge_id: str) -> dict:
    try:
        oid = ObjectId(challenge_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid challenge_id")

    challenge_doc = await global_challenges_col.find_one({"_id": oid})
    if not challenge_doc:
        raise HTTPException(status_code=404, detail="Global challenge not found")
    return challenge_doc


async def _ensure_joined(challenge_id: str, user_id: str) -> None:
    participant = await global_challenge_participants_col.find_one(
        {"challenge_id": challenge_id, "user_id": user_id}
    )
    if not participant:
        raise HTTPException(status_code=403, detail="User has not joined this global challenge")


def _validate_question_ids(challenge_doc: dict, answers: dict[str, str]) -> None:
    valid_question_ids = {question["question_id"] for question in challenge_doc["questions"]}
    for answered_question_id in answers.keys():
        if answered_question_id not in valid_question_ids:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid question_id in answers: {answered_question_id}",
            )


def _score_submission(challenge_doc: dict, answers: dict[str, str]) -> tuple[int, int, float]:
    correct_answers = 0
    questions = challenge_doc["questions"]

    for question in questions:
        selected = answers.get(question["question_id"])
        if selected and selected == question["correct_answer"]:
            correct_answers += 1

    total_questions = len(questions)
    score_percent = (correct_answers / total_questions) * 100 if total_questions > 0 else 0.0
    return correct_answers, total_questions, score_percent


async def _create_submission_if_missing(
    challenge_doc: dict,
    user_id: str,
    answers: dict[str, str],
    *,
    submission_mode: Literal["manual", "auto"],
    submitted_at: datetime | None = None,
) -> dict:
    challenge_id = str(challenge_doc["_id"])
    existing_submission = await global_challenge_submissions_col.find_one(
        {"challenge_id": challenge_id, "user_id": user_id}
    )
    if existing_submission:
        return existing_submission

    _validate_question_ids(challenge_doc, answers)
    correct_answers, total_questions, score_percent = _score_submission(challenge_doc, answers)
    final_submitted_at = submitted_at or _utc_now()

    submission_doc = {
        "challenge_id": challenge_id,
        "user_id": user_id,
        "answers": answers,
        "correct_answers": correct_answers,
        "total_questions": total_questions,
        "score_percent": score_percent,
        "submitted_at": final_submitted_at,
        "submission_mode": submission_mode,
    }
    await global_challenge_submissions_col.insert_one(submission_doc)
    return submission_doc


async def _finalize_expired_participants(challenge_doc: dict) -> None:
    now_utc = _utc_now()
    if now_utc < challenge_doc["scheduled_end_at"]:
        return

    challenge_id = str(challenge_doc["_id"])
    participants = [
        participant
        async for participant in global_challenge_participants_col.find({"challenge_id": challenge_id})
    ]

    for participant in participants:
        existing_submission = await global_challenge_submissions_col.find_one(
            {"challenge_id": challenge_id, "user_id": participant["user_id"]}
        )
        if existing_submission:
            continue

        saved_progress = await global_challenge_progress_col.find_one(
            {"challenge_id": challenge_id, "user_id": participant["user_id"]}
        )
        answers = saved_progress.get("answers", {}) if saved_progress else {}
        await _create_submission_if_missing(
            challenge_doc,
            participant["user_id"],
            answers,
            submission_mode="auto",
            submitted_at=challenge_doc["scheduled_end_at"],
        )


def _to_challenge_summary(challenge_doc: dict, participant_count: int, submission_count: int) -> dict:
    now_utc = _utc_now()
    scheduled_start_lk = _as_aware_utc(challenge_doc["scheduled_start_at"]).astimezone(
        SRI_LANKA_TZ
    )
    return {
        "id": str(challenge_doc["_id"]),
        "title": challenge_doc["title"],
        "status": _challenge_phase(challenge_doc, now_utc),
        "duration_seconds": challenge_doc["duration_seconds"],
        "question_count": challenge_doc["question_count"],
        "paper_type": challenge_doc["paper_type"],
        "difficulty": challenge_doc["difficulty"],
        "grade": challenge_doc.get("grade"),
        "term": challenge_doc.get("term"),
        "topic": challenge_doc.get("topic"),
        "challenge_date_label": scheduled_start_lk.strftime("%A"),
        "scheduled_start_at": _as_aware_utc(challenge_doc["scheduled_start_at"]),
        "scheduled_end_at": _as_aware_utc(challenge_doc["scheduled_end_at"]),
        "reminder_times": [
            _as_aware_utc(reminder_time)
            for reminder_time in challenge_doc.get("reminder_times", [])
        ],
        "participant_count": participant_count,
        "submission_count": submission_count,
    }


async def get_global_challenge_schedule() -> dict:
    challenges = await _get_weekly_challenge_docs()
    response_items = []

    for challenge_doc in challenges:
        challenge_id = str(challenge_doc["_id"])
        participant_count = await global_challenge_participants_col.count_documents(
            {"challenge_id": challenge_id}
        )
        submission_count = await global_challenge_submissions_col.count_documents(
            {"challenge_id": challenge_id}
        )
        response_items.append(
            _to_challenge_summary(challenge_doc, participant_count, submission_count)
        )

    return {
        "timezone": "Asia/Colombo",
        "fixed_start_time": "20:00",
        "challenge_days": ["Monday", "Wednesday", "Friday"],
        "challenges": response_items,
    }


async def join_global_challenge(challenge_id: str, user_id: str) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    phase = _challenge_phase(challenge_doc, _utc_now())
    if phase != "live":
        raise HTTPException(status_code=400, detail="Global challenge can only be joined while live")

    existing_participant = await global_challenge_participants_col.find_one(
        {"challenge_id": challenge_id, "user_id": user_id}
    )
    if existing_participant:
        return {
            "challenge_id": challenge_id,
            "participant": {
                "challenge_id": existing_participant["challenge_id"],
                "user_id": existing_participant["user_id"],
                "joined_at": existing_participant["joined_at"],
            },
            "already_joined": True,
        }

    participant_doc = {
        "challenge_id": challenge_id,
        "user_id": user_id,
        "joined_at": _utc_now(),
    }
    await global_challenge_participants_col.insert_one(participant_doc)
    return {
        "challenge_id": challenge_id,
        "participant": participant_doc,
        "already_joined": False,
    }


async def get_global_challenge_questions(challenge_id: str, user_id: str) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    await _ensure_joined(challenge_id, user_id)

    existing_submission = await global_challenge_submissions_col.find_one(
        {"challenge_id": challenge_id, "user_id": user_id}
    )
    if existing_submission:
        raise HTTPException(status_code=400, detail="Participant has already submitted")

    phase = _challenge_phase(challenge_doc, _utc_now())
    if phase != "live":
        raise HTTPException(status_code=400, detail="Global challenge is not currently live")

    questions = [
        {
            "question_id": question["question_id"],
            "question": question["question"],
            "options": question["options"],
        }
        for question in challenge_doc["questions"]
    ]

    remaining_seconds = max(
        0,
        int((challenge_doc["scheduled_end_at"] - _utc_now()).total_seconds()),
    )

    return {
        "challenge_id": challenge_id,
        "title": challenge_doc["title"],
        "status": "live",
        "scheduled_end_at": _as_aware_utc(challenge_doc["scheduled_end_at"]),
        "remaining_seconds": remaining_seconds,
        "questions": questions,
    }


async def save_global_challenge_progress(
    challenge_id: str,
    user_id: str,
    answers: dict[str, Literal["A", "B", "C", "D", "E"]],
) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    await _ensure_joined(challenge_id, user_id)
    _validate_question_ids(challenge_doc, answers)

    await global_challenge_progress_col.update_one(
        {"challenge_id": challenge_id, "user_id": user_id},
        {
            "$set": {
                "answers": answers,
                "updated_at": _utc_now(),
            }
        },
        upsert=True,
    )

    return {"challenge_id": challenge_id, "user_id": user_id, "saved_answers": len(answers)}


async def submit_global_challenge(
    challenge_id: str,
    user_id: str,
    answers: dict[str, Literal["A", "B", "C", "D", "E"]],
) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    await _ensure_joined(challenge_id, user_id)

    await global_challenge_progress_col.update_one(
        {"challenge_id": challenge_id, "user_id": user_id},
        {
            "$set": {
                "answers": answers,
                "updated_at": _utc_now(),
            }
        },
        upsert=True,
    )

    phase = _challenge_phase(challenge_doc, _utc_now())
    submission_mode: Literal["manual", "auto"] = "manual" if phase == "live" else "auto"
    submitted_at = _utc_now() if submission_mode == "manual" else challenge_doc["scheduled_end_at"]

    submission_doc = await _create_submission_if_missing(
        challenge_doc,
        user_id,
        answers,
        submission_mode=submission_mode,
        submitted_at=submitted_at,
    )

    xp_result = await award_global_challenge_completion_xp(
        challenge_id,
        user_id,
        float(submission_doc["score_percent"]),
    )

    return {
        "challenge_id": challenge_id,
        "user_id": user_id,
        "submitted_at": submission_doc["submitted_at"],
        "total_questions": submission_doc["total_questions"],
        "correct_answers": submission_doc["correct_answers"],
        "score_percent": round(float(submission_doc["score_percent"]), 2),
        "submission_mode": submission_doc["submission_mode"],
        "xp_awarded": xp_result["xp_awarded"],
        "total_xp": xp_result["profile"]["total_xp"],
    }


async def get_global_challenge_results(challenge_id: str) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    await _finalize_expired_participants(challenge_doc)

    submissions_cursor = global_challenge_submissions_col.find({"challenge_id": challenge_id}).sort(
        [("score_percent", -1), ("submitted_at", 1)]
    )
    submissions = [submission async for submission in submissions_cursor]

    if submissions and _challenge_phase(challenge_doc, _utc_now()) == "ended":
        for index, submission in enumerate(submissions[:10]):
            await award_global_challenge_top_10_bonus(challenge_id, submission["user_id"])
            if index == 0:
                await award_global_challenge_first_place_bonus(
                    challenge_id,
                    submission["user_id"],
                )

    leaderboard = []
    for index, submission in enumerate(submissions):
        leaderboard.append(
            {
                "rank": index + 1,
                "user_id": submission["user_id"],
                "score_percent": round(float(submission.get("score_percent", 0)), 2),
                "correct_answers": submission.get("correct_answers", 0),
                "total_questions": submission.get("total_questions", 0),
                "submitted_at": submission["submitted_at"],
                "submission_mode": submission.get("submission_mode", "manual"),
            }
        )

    return {"challenge_id": challenge_id, "leaderboard": leaderboard}


async def run_global_challenge_maintenance_pass() -> None:
    preload_result = await preload_weekly_challenge_docs()
    challenges = preload_result["challenges"]
    for challenge_doc in challenges:
        await _finalize_expired_participants(challenge_doc)
