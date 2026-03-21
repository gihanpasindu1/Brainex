from datetime import datetime, timedelta, timezone

from app.db.mongo import users_col, model_paper_submissions_col
from app.schemas.user_profile import UserOnboardingRequest, UserUpdateRequest

DAILY_LOGIN_XP = 10
FRIEND_CHALLENGE_COMPLETION_XP = 20
FRIEND_CHALLENGE_WIN_BONUS_XP = 15
GLOBAL_CHALLENGE_COMPLETION_XP = 30
GLOBAL_CHALLENGE_TOP_10_BONUS_XP = 20
GLOBAL_CHALLENGE_FIRST_PLACE_BONUS_XP = 30
SRI_LANKA_TZ = timezone(timedelta(hours=5, minutes=30), name="Asia/Colombo")


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _today_lk_string() -> str:
    return _utc_now().astimezone(SRI_LANKA_TZ).date().isoformat()


def _build_default_user_doc(user_id: str) -> dict:
    now = _utc_now()
    return {
        "user_id": user_id,
        "total_xp": 0,
        "last_login_xp_date": None,
        "xp_history": [],
        "onboarding_completed": False,
        "created_at": now,
        "updated_at": now,
    }


async def ensure_user_profile(user_id: str) -> dict:
    existing = await users_col.find_one({"user_id": user_id})
    if existing:
        return existing

    user_doc = _build_default_user_doc(user_id)
    await users_col.insert_one(user_doc)
    return await users_col.find_one({"user_id": user_id}) or user_doc

async def complete_user_onboarding(user_id: str, data: UserOnboardingRequest) -> dict:
    await ensure_user_profile(user_id)
    now = _utc_now()
    update_data = data.model_dump()
    update_data["onboarding_completed"] = True
    update_data["updated_at"] = now
    
    # Store email if provided
    if "email" in update_data and update_data["email"]:
        update_data["email"] = update_data["email"].lower().strip()

    await users_col.update_one(
        {"user_id": user_id},
        {"$set": update_data}
    )
    return await users_col.find_one({"user_id": user_id})

async def update_user_profile(user_id: str, data: UserUpdateRequest) -> dict:
    await ensure_user_profile(user_id)
    update_data = data.model_dump(exclude_unset=True)
    if not update_data:
        return await users_col.find_one({"user_id": user_id})
        
    update_data["updated_at"] = _utc_now()
    
    await users_col.update_one(
        {"user_id": user_id},
        {"$set": update_data}
    )
    return await users_col.find_one({"user_id": user_id})

async def get_user_profile(user_id: str) -> dict:
    profile = await ensure_user_profile(user_id)
    papers_count = await model_paper_submissions_col.count_documents({"user_id": user_id})
    profile["papers_completed"] = papers_count
    return profile


async def _has_xp_event(user_id: str, event_type: str, reference_id: str) -> bool:
    existing = await users_col.find_one(
        {
            "user_id": user_id,
            "xp_history": {
                "$elemMatch": {
                    "type": event_type,
                    "reference_id": reference_id,
                }
            },
        }
    )
    return existing is not None


async def _award_xp_once(
    user_id: str,
    *,
    event_type: str,
    reference_id: str,
    xp_amount: int,
) -> dict:
    profile = await ensure_user_profile(user_id)

    if xp_amount <= 0:
        return {"xp_awarded": 0, "profile": profile}

    if await _has_xp_event(user_id, event_type, reference_id):
        return {"xp_awarded": 0, "profile": profile}

    now = _utc_now()
    history_item = {
        "type": event_type,
        "xp_amount": xp_amount,
        "date": now,
        "reference_id": reference_id,
    }

    await users_col.update_one(
        {"user_id": user_id},
        {
            "$inc": {"total_xp": xp_amount},
            "$push": {"xp_history": history_item},
            "$set": {"updated_at": now},
        },
    )
    updated_profile = await users_col.find_one({"user_id": user_id}) or profile
    return {"xp_awarded": xp_amount, "profile": updated_profile}


async def award_daily_login_xp(user_id: str) -> dict:
    await ensure_user_profile(user_id)
    today = _today_lk_string()
    now = _utc_now()

    update_result = await users_col.update_one(
        {
            "user_id": user_id,
            "last_login_xp_date": {"$ne": today},
        },
        {
            "$set": {
                "last_login_xp_date": today,
                "updated_at": now,
            },
            "$inc": {"total_xp": DAILY_LOGIN_XP},
            "$push": {
                "xp_history": {
                    "type": "daily_login",
                    "xp_amount": DAILY_LOGIN_XP,
                    "date": now,
                    "reference_id": today,
                }
            },
        },
    )

    profile = await users_col.find_one({"user_id": user_id}) or await ensure_user_profile(user_id)
    return {
        "xp_awarded": DAILY_LOGIN_XP if update_result.modified_count else 0,
        "already_claimed_today": update_result.modified_count == 0,
        "profile": profile,
    }


async def award_model_paper_xp(
    user_id: str,
    *,
    paper_id: str,
    submission_id: str,
    score: int,
) -> dict:
    reference_id = f"{paper_id}:{submission_id}"
    return await _award_xp_once(
        user_id,
        event_type="model_paper",
        reference_id=reference_id,
        xp_amount=max(0, int(score)),
    )


async def award_friend_challenge_completion_xp(
    challenge_id: str,
    user_id: str,
    score_percent: float,
) -> dict:
    xp_amount = FRIEND_CHALLENGE_COMPLETION_XP + max(0, round(score_percent))
    return await _award_xp_once(
        user_id,
        event_type="friend_challenge_completion",
        reference_id=challenge_id,
        xp_amount=xp_amount,
    )


async def award_friend_challenge_win_bonus(challenge_id: str, user_id: str) -> dict:
    return await _award_xp_once(
        user_id,
        event_type="friend_challenge_win",
        reference_id=challenge_id,
        xp_amount=FRIEND_CHALLENGE_WIN_BONUS_XP,
    )


async def award_global_challenge_completion_xp(
    challenge_id: str,
    user_id: str,
    score_percent: float,
) -> dict:
    xp_amount = GLOBAL_CHALLENGE_COMPLETION_XP + max(0, round(score_percent))
    return await _award_xp_once(
        user_id,
        event_type="global_challenge_completion",
        reference_id=challenge_id,
        xp_amount=xp_amount,
    )


async def award_global_challenge_top_10_bonus(challenge_id: str, user_id: str) -> dict:
    return await _award_xp_once(
        user_id,
        event_type="global_challenge_top_10",
        reference_id=challenge_id,
        xp_amount=GLOBAL_CHALLENGE_TOP_10_BONUS_XP,
    )


async def award_global_challenge_first_place_bonus(challenge_id: str, user_id: str) -> dict:
    return await _award_xp_once(
        user_id,
        event_type="global_challenge_first_place",
        reference_id=challenge_id,
        xp_amount=GLOBAL_CHALLENGE_FIRST_PLACE_BONUS_XP,
    )
