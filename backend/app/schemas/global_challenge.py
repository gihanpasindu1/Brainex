from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field

from app.schemas.modelpaper import DifficultyType, GradeType, PaperType, TermType


GlobalChallengePhase = Literal["upcoming", "live", "ended"]


class GlobalChallengeParticipant(BaseModel):
    challenge_id: str
    user_id: str
    joined_at: datetime


class GlobalChallengeSummary(BaseModel):
    id: str
    title: str
    status: GlobalChallengePhase
    duration_seconds: int
    question_count: int
    paper_type: PaperType
    difficulty: DifficultyType
    grade: Optional[GradeType] = None
    term: Optional[TermType] = None
    topic: Optional[str] = None
    challenge_date_label: str
    scheduled_start_at: datetime
    scheduled_end_at: datetime
    reminder_times: list[datetime] = Field(default_factory=list)
    participant_count: int = 0
    submission_count: int = 0


class GlobalChallengeScheduleResponse(BaseModel):
    timezone: str
    fixed_start_time: str
    challenge_days: list[str]
    challenges: list[GlobalChallengeSummary]


class JoinGlobalChallengeRequest(BaseModel):
    user_id: str


class JoinGlobalChallengeResponse(BaseModel):
    challenge_id: str
    participant: GlobalChallengeParticipant
    already_joined: bool


class GlobalChallengeQuestion(BaseModel):
    question_id: str
    question: str
    options: dict[str, str]


class GlobalChallengeQuestionsResponse(BaseModel):
    challenge_id: str
    title: str
    status: GlobalChallengePhase
    scheduled_end_at: datetime
    remaining_seconds: int = Field(..., ge=0)
    questions: list[GlobalChallengeQuestion]


class SaveGlobalChallengeProgressRequest(BaseModel):
    user_id: str
    answers: dict[str, Literal["A", "B", "C", "D", "E"]] = Field(
        ...,
        description="Map of question_id -> selected option (A/B/C/D/E)",
    )


class SubmitGlobalChallengeRequest(BaseModel):
    user_id: str
    answers: dict[str, Literal["A", "B", "C", "D", "E"]] = Field(
        ...,
        description="Map of question_id -> selected option (A/B/C/D/E)",
    )


class SubmitGlobalChallengeResponse(BaseModel):
    challenge_id: str
    user_id: str
    submitted_at: datetime
    total_questions: int
    correct_answers: int
    score_percent: float
    submission_mode: Literal["manual", "auto"]
    xp_awarded: int = 0
    total_xp: Optional[int] = None


class GlobalChallengeResultItem(BaseModel):
    rank: int
    user_id: str
    score_percent: float
    correct_answers: int
    total_questions: int
    submitted_at: datetime
    submission_mode: Literal["manual", "auto"]


class GlobalChallengeResultsResponse(BaseModel):
    challenge_id: str
    leaderboard: list[GlobalChallengeResultItem]
