from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field

class UserOnboardingRequest(BaseModel):
    name: str
    email: Optional[str] = None
    grade: str
    exam_year: str
    school: Optional[str] = None
    district: Optional[str] = None
    plan: str
    hear_about_us: str

class UserUpdateRequest(BaseModel):
    name: Optional[str] = None
    profile_picture_base64: Optional[str] = None

XpEventType = Literal[
    "daily_login",
    "model_paper",
    "friend_challenge_completion",
    "friend_challenge_win",
    "global_challenge_completion",
    "global_challenge_top_10",
    "global_challenge_first_place",
]


class XpHistoryItem(BaseModel):
    type: XpEventType
    xp_amount: int = Field(..., ge=0)
    date: datetime
    reference_id: str


class UserProfileResponse(BaseModel):
    user_id: str
    email: Optional[str] = None
    total_xp: int = Field(..., ge=0)
    papers_completed: int = 0
    last_login_xp_date: Optional[str] = None
    xp_history: list[XpHistoryItem] = Field(default_factory=list)
    onboarding_completed: bool = False
    name: Optional[str] = None
    grade: Optional[str] = None
    exam_year: Optional[str] = None
    school: Optional[str] = None
    district: Optional[str] = None
    plan: Optional[str] = None
    hear_about_us: Optional[str] = None
    profile_picture_base64: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class UserLoginXpResponse(BaseModel):
    profile: UserProfileResponse
    xp_awarded: int = Field(..., ge=0)
    already_claimed_today: bool
