from fastapi import APIRouter, Query
from typing import Optional

from app.schemas.user_profile import UserLoginXpResponse, UserProfileResponse, UserOnboardingRequest, UserUpdateRequest
from app.services.user_profile_service import award_daily_login_xp, get_user_profile, complete_user_onboarding, update_user_profile
from app.services.leaderboard_service import get_global_leaderboard, get_my_rank

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/leaderboard/global")
async def get_global_leaderboard_endpoint(limit: int = Query(default=50, ge=1, le=200)):
    """Returns all users sorted by XP, with rank injected."""
    entries = await get_global_leaderboard(limit=limit)
    return {"leaderboard": entries, "count": len(entries)}


@router.get("/leaderboard/me")
async def get_my_leaderboard_endpoint(
    user_id: str = Query(...),
    limit: int = Query(default=50, ge=1, le=200),
):
    """Returns ranked list plus the calling user's rank and XP."""
    entries = await get_global_leaderboard(limit=limit)
    my_info = await get_my_rank(user_id)
    return {
        "leaderboard": entries,
        "count": len(entries),
        "my_rank": my_info["my_rank"],
        "my_xp": my_info["my_xp"],
    }


@router.get("/{user_id}", response_model=UserProfileResponse)
async def get_user_profile_endpoint(user_id: str):
    return await get_user_profile(user_id)


@router.post("/{user_id}/login", response_model=UserLoginXpResponse)
async def award_daily_login_xp_endpoint(user_id: str):
    return await award_daily_login_xp(user_id)


@router.put("/{user_id}/onboarding", response_model=UserProfileResponse)
async def complete_onboarding_endpoint(user_id: str, request: UserOnboardingRequest):
    return await complete_user_onboarding(user_id, request)

@router.patch("/{user_id}/profile", response_model=UserProfileResponse)
async def update_profile_endpoint(user_id: str, request: UserUpdateRequest):
    return await update_user_profile(user_id, request)
