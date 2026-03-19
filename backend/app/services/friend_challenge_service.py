import random
import string
from datetime import datetime, timedelta
from typing import Literal, Optional

from bson import ObjectId
from fastapi import HTTPException

from app.db.mongo import (
    friend_challenge_participants_col,
    friend_challenge_submissions_col,
    friend_challenges_col,
)
from app.services.rag_service import generate_mcqs
from app.services.user_profile_service import (
    award_friend_challenge_completion_xp,
    award_friend_challenge_win_bonus,
)

CHALLENGE_STATUS_WAITING = "waiting"
CHALLENGE_STATUS_STARTED = "started"


async def _generate_unique_invite_code(length: int = 6) -> str:
    alphabet = string.ascii_uppercase + string.digits

    for _ in range(20):
        invite_code = "".join(random.choices(alphabet, k=length))
        existing = await friend_challenges_col.find_one({"invite_code": invite_code})
        if not existing:
            return invite_code

    raise HTTPException(status_code=500, detail="Could not generate invite code")


def _normalize_generation_params(
    *,
    paper_type: str,
    grade: Optional[str],
    term: Optional[str],
    topic: Optional[str],
) -> tuple[str, Optional[str], Optional[str]]:
    if paper_type == "Subject":
        if not grade or not topic:
            raise HTTPException(
                status_code=400,
                detail="grade and topic are required when paper_type is Subject",
            )
        return grade, None, topic

    if paper_type == "Term":
        if not grade or not term:
            raise HTTPException(
                status_code=400,
                detail="grade and term are required when paper_type is Term",
            )
        return grade, term, None

    if paper_type == "Final":
        return "13", None, None

    raise HTTPException(status_code=400, detail="Invalid paper_type")


def _build_challenge_questions(generated_questions: list[dict]) -> list[dict]:
    challenge_questions = []

    for index, question in enumerate(generated_questions):
        question_id = f"challenge_q_{index + 1}"
        challenge_questions.append(
            {
                "question_id": question_id,
                "question": question["question"],
                "options": question["options"],
                "correct_answer": question["correct_answer"],
                "explanation": question.get("explanation"),
                "topic": question.get("topic"),
            }
        )

    return challenge_questions


def _to_challenge_response(challenge_doc: dict, participants: list[dict]) -> dict:
    return {
        "id": str(challenge_doc["_id"]),
        "invite_code": challenge_doc["invite_code"],
        "host_user_id": challenge_doc["host_user_id"],
        "title": challenge_doc["title"],
        "status": challenge_doc["status"],
        "duration_seconds": challenge_doc["duration_seconds"],
        "question_count": challenge_doc["question_count"],
        "question_ids": [q["question_id"] for q in challenge_doc["questions"]],
        "paper_type": challenge_doc["paper_type"],
        "difficulty": challenge_doc["difficulty"],
        "grade": challenge_doc.get("grade"),
        "term": challenge_doc.get("term"),
        "topic": challenge_doc.get("topic"),
        "created_at": challenge_doc["created_at"],
        "started_at": challenge_doc.get("started_at"),
        "ends_at": challenge_doc.get("ends_at"),
        "participants": [
            {
                "challenge_id": participant["challenge_id"],
                "user_id": participant["user_id"],
                "role": participant["role"],
                "joined_at": participant["joined_at"],
            }
            for participant in participants
        ],
    }


async def _get_challenge_doc_or_404(challenge_id: str) -> dict:
    try:
        oid = ObjectId(challenge_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid challenge_id")

    challenge_doc = await friend_challenges_col.find_one({"_id": oid})
    if not challenge_doc:
        raise HTTPException(status_code=404, detail="Friend challenge not found")
    return challenge_doc


async def _ensure_participant(challenge_id: str, user_id: str) -> None:
    participant = await friend_challenge_participants_col.find_one(
        {"challenge_id": challenge_id, "user_id": user_id}
    )
    if not participant:
        raise HTTPException(status_code=403, detail="User is not a participant of this challenge")


def _ensure_challenge_active(challenge_doc: dict) -> None:
    if challenge_doc["status"] != CHALLENGE_STATUS_STARTED:
        raise HTTPException(status_code=400, detail="Challenge is not active")

    started_at = challenge_doc.get("started_at")
    ends_at = challenge_doc.get("ends_at")
    now = datetime.utcnow()

    if not started_at or not ends_at:
        raise HTTPException(status_code=400, detail="Challenge timing is not set")
    if now < started_at:
        raise HTTPException(status_code=400, detail="Challenge has not started yet")
    if now >= ends_at:
        raise HTTPException(status_code=400, detail="Challenge has already ended")


async def create_friend_challenge(
    host_user_id: str,
    title: str,
    duration_seconds: int,
    question_count: int,
    paper_type: str,
    difficulty: str,
    grade: Optional[str] = None,
    term: Optional[str] = None,
    topic: Optional[str] = None,
) -> dict:
    normalized_grade, normalized_term, normalized_topic = _normalize_generation_params(
        paper_type=paper_type,
        grade=grade,
        term=term,
        topic=topic,
    )

    generated_questions = await generate_mcqs(
        grade=normalized_grade,
        paper_type=paper_type,
        term=normalized_term,
        difficulty=difficulty,
        mcq_count=question_count,
        topic=normalized_topic,
    )

    if len(generated_questions) < question_count:
        raise HTTPException(
            status_code=500,
            detail="Could not generate enough questions for the friend challenge",
        )

    now = datetime.utcnow()
    invite_code = await _generate_unique_invite_code()
    challenge_questions = _build_challenge_questions(generated_questions[:question_count])

    challenge_doc = {
        "invite_code": invite_code,
        "host_user_id": host_user_id,
        "title": title,
        "status": CHALLENGE_STATUS_WAITING,
        "duration_seconds": duration_seconds,
        "question_count": question_count,
        "paper_type": paper_type,
        "difficulty": difficulty,
        "grade": normalized_grade,
        "term": normalized_term,
        "topic": normalized_topic,
        "questions": challenge_questions,
        "created_at": now,
        "started_at": None,
        "ends_at": None,
    }

    result = await friend_challenges_col.insert_one(challenge_doc)
    challenge_id = str(result.inserted_id)

    host_participant_doc = {
        "challenge_id": challenge_id,
        "user_id": host_user_id,
        "role": "host",
        "joined_at": now,
    }
    await friend_challenge_participants_col.insert_one(host_participant_doc)

    saved_challenge = await friend_challenges_col.find_one({"_id": result.inserted_id})
    participants = [host_participant_doc]
    return _to_challenge_response(saved_challenge, participants)


async def get_friend_challenge_by_id(challenge_id: str) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    participants_cursor = friend_challenge_participants_col.find({"challenge_id": challenge_id})
    participants = [participant async for participant in participants_cursor]
    return _to_challenge_response(challenge_doc, participants)


async def join_friend_challenge(challenge_id: str, user_id: str) -> dict:
    challenge = await get_friend_challenge_by_id(challenge_id)
    if challenge["status"] != CHALLENGE_STATUS_WAITING:
        raise HTTPException(status_code=400, detail="Only waiting challenges can be joined")

    existing_participant = await friend_challenge_participants_col.find_one(
        {"challenge_id": challenge_id, "user_id": user_id}
    )
    if existing_participant:
        return {
            "challenge_id": challenge_id,
            "participant": {
                "challenge_id": existing_participant["challenge_id"],
                "user_id": existing_participant["user_id"],
                "role": existing_participant["role"],
                "joined_at": existing_participant["joined_at"],
            },
            "already_joined": True,
        }

    participant_doc = {
        "challenge_id": challenge_id,
        "user_id": user_id,
        "role": "player",
        "joined_at": datetime.utcnow(),
    }
    await friend_challenge_participants_col.insert_one(participant_doc)

    return {
        "challenge_id": challenge_id,
        "participant": participant_doc,
        "already_joined": False,
    }


async def start_friend_challenge(challenge_id: str, user_id: str) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    oid = challenge_doc["_id"]

    if challenge_doc["host_user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Only host can start this challenge")

    if challenge_doc["status"] != CHALLENGE_STATUS_WAITING:
        raise HTTPException(status_code=400, detail="Challenge has already started")

    started_at = datetime.utcnow()
    ends_at = started_at + timedelta(seconds=challenge_doc["duration_seconds"])

    await friend_challenges_col.update_one(
        {"_id": oid},
        {
            "$set": {
                "status": CHALLENGE_STATUS_STARTED,
                "started_at": started_at,
                "ends_at": ends_at,
            }
        },
    )

    updated_challenge_doc = await friend_challenges_col.find_one({"_id": oid})
    participants_cursor = friend_challenge_participants_col.find({"challenge_id": challenge_id})
    participants = [participant async for participant in participants_cursor]
    return _to_challenge_response(updated_challenge_doc, participants)


async def get_friend_challenge_questions(challenge_id: str, user_id: str) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    await _ensure_participant(challenge_id, user_id)
    _ensure_challenge_active(challenge_doc)

    questions = [
        {
            "question_id": question["question_id"],
            "question": question["question"],
            "options": question["options"],
        }
        for question in challenge_doc["questions"]
    ]

    return {"challenge_id": challenge_id, "questions": questions}


async def submit_friend_challenge(
    challenge_id: str,
    user_id: str,
    answers: dict[str, Literal["A", "B", "C", "D", "E"]],
) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)
    await _ensure_participant(challenge_id, user_id)
    _ensure_challenge_active(challenge_doc)

    existing_submission = await friend_challenge_submissions_col.find_one(
        {"challenge_id": challenge_id, "user_id": user_id}
    )
    if existing_submission:
        raise HTTPException(status_code=400, detail="Participant has already submitted")

    questions = challenge_doc["questions"]
    valid_question_ids = {question["question_id"] for question in questions}

    for answered_question_id in answers.keys():
        if answered_question_id not in valid_question_ids:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid question_id in answers: {answered_question_id}",
            )

    correct_answers = 0
    for question in questions:
        selected = answers.get(question["question_id"])
        if selected and selected == question["correct_answer"]:
            correct_answers += 1

    total_questions = len(questions)
    score_percent = (correct_answers / total_questions) * 100 if total_questions > 0 else 0
    submitted_at = datetime.utcnow()

    submission_doc = {
        "challenge_id": challenge_id,
        "user_id": user_id,
        "answers": answers,
        "correct_answers": correct_answers,
        "total_questions": total_questions,
        "score_percent": score_percent,
        "submitted_at": submitted_at,
    }
    await friend_challenge_submissions_col.insert_one(submission_doc)

    xp_result = await award_friend_challenge_completion_xp(
        challenge_id,
        user_id,
        score_percent,
    )

    return {
        "challenge_id": challenge_id,
        "user_id": user_id,
        "submitted_at": submitted_at,
        "total_questions": total_questions,
        "correct_answers": correct_answers,
        "score_percent": round(score_percent, 2),
        "xp_awarded": xp_result["xp_awarded"],
        "total_xp": xp_result["profile"]["total_xp"],
    }


async def get_friend_challenge_results(challenge_id: str) -> dict:
    challenge_doc = await _get_challenge_doc_or_404(challenge_id)

    submissions_cursor = friend_challenge_submissions_col.find({"challenge_id": challenge_id}).sort(
        [("score_percent", -1), ("submitted_at", 1)]
    )
    submissions = [submission async for submission in submissions_cursor]

    ends_at = challenge_doc.get("ends_at")
    if submissions and ends_at and datetime.utcnow() >= ends_at:
        await award_friend_challenge_win_bonus(challenge_id, submissions[0]["user_id"])

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
            }
        )

    return {"challenge_id": challenge_id, "leaderboard": leaderboard}
