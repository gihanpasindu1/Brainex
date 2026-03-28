from fastapi import APIRouter

from app.schemas.user_profile import UserLoginXpResponse, UserProfileResponse, UserOnboardingRequest, UserUpdateRequest
from app.services.user_profile_service import award_daily_login_xp, get_user_profile, complete_user_onboarding, update_user_profile

router = APIRouter(prefix="/users", tags=["users"])


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
