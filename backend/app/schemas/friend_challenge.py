from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field

from app.schemas.modelpaper import DifficultyType, GradeType, PaperType, TermType


class CreateFriendChallengeRequest(BaseModel):
    host_user_id: str
    title: str
    duration_seconds: int = Field(..., ge=30)
    question_count: int = Field(..., ge=1, le=100)
    paper_type: PaperType
    difficulty: DifficultyType
    grade: Optional[GradeType] = None
    term: Optional[TermType] = None
    topic: Optional[str] = None


class JoinFriendChallengeRequest(BaseModel):
    user_id: str


class StartFriendChallengeRequest(BaseModel):
    user_id: str


class FriendChallengeParticipant(BaseModel):
    challenge_id: str
    user_id: str
    role: Literal["host", "player"]
    joined_at: datetime


class FriendChallengeResponse(BaseModel):
    id: str
    invite_code: str
    host_user_id: str
    title: str
    status: Literal["waiting", "started"]
    duration_seconds: int
    question_count: int
    question_ids: list[str]
    paper_type: PaperType
    difficulty: DifficultyType
    grade: Optional[GradeType] = None
    term: Optional[TermType] = None
    topic: Optional[str] = None
    created_at: datetime
    started_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    participants: list[FriendChallengeParticipant] = Field(default_factory=list)


class JoinFriendChallengeResponse(BaseModel):
    challenge_id: str
    participant: FriendChallengeParticipant
    already_joined: bool


class FriendChallengeQuestion(BaseModel):
    question_id: str
    question: str
    options: dict[str, str]


class FriendChallengeQuestionsResponse(BaseModel):
    challenge_id: str
    questions: list[FriendChallengeQuestion]


class SubmitFriendChallengeRequest(BaseModel):
    user_id: str
    answers: dict[str, Literal["A", "B", "C", "D", "E"]] = Field(
        ...,
        description="Map of question_id -> selected option (A/B/C/D/E)",
    )


class SubmitFriendChallengeResponse(BaseModel):
    challenge_id: str
    user_id: str
    submitted_at: datetime
    total_questions: int
    correct_answers: int
    score_percent: float
    xp_awarded: int = 0
    total_xp: Optional[int] = None


class FriendChallengeResultItem(BaseModel):
    rank: int
    user_id: str
    score_percent: float
    correct_answers: int
    total_questions: int
    submitted_at: datetime


class FriendChallengeResultsResponse(BaseModel):
    challenge_id: str
    leaderboard: list[FriendChallengeResultItem]
