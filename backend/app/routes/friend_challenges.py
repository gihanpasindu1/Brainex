from fastapi import APIRouter

from app.schemas.friend_challenge import (
    CreateFriendChallengeRequest,
    FriendChallengeResponse,
    FriendChallengeQuestionsResponse,
    FriendChallengeResultsResponse,
    JoinFriendChallengeRequest,
    JoinFriendChallengeResponse,
    SubmitFriendChallengeRequest,
    SubmitFriendChallengeResponse,
    StartFriendChallengeRequest,
)
from app.services.friend_challenge_service import (
    create_friend_challenge,
    get_friend_challenge_questions,
    get_friend_challenge_results,
    get_friend_challenge_by_id,
    join_friend_challenge,
    submit_friend_challenge,
    start_friend_challenge,
)

router = APIRouter(prefix="/friend-challenges", tags=["friend-challenges"])


@router.post("", response_model=FriendChallengeResponse)
async def create_friend_challenge_endpoint(req: CreateFriendChallengeRequest):
    return await create_friend_challenge(
        host_user_id=req.host_user_id,
        title=req.title,
        duration_seconds=req.duration_seconds,
        question_count=req.question_count,
        paper_type=req.paper_type,
        difficulty=req.difficulty,
        grade=req.grade,
        term=req.term,
        topic=req.topic,
    )


@router.get("/{challenge_id}", response_model=FriendChallengeResponse)
async def get_friend_challenge_endpoint(challenge_id: str):
    return await get_friend_challenge_by_id(challenge_id)


@router.post("/{challenge_id}/join", response_model=JoinFriendChallengeResponse)
async def join_friend_challenge_endpoint(challenge_id: str, req: JoinFriendChallengeRequest):
    return await join_friend_challenge(challenge_id=challenge_id, user_id=req.user_id)


@router.post("/{challenge_id}/start", response_model=FriendChallengeResponse)
async def start_friend_challenge_endpoint(challenge_id: str, req: StartFriendChallengeRequest):
    return await start_friend_challenge(challenge_id=challenge_id, user_id=req.user_id)


@router.get("/{challenge_id}/questions", response_model=FriendChallengeQuestionsResponse)
async def get_friend_challenge_questions_endpoint(challenge_id: str, user_id: str):
    return await get_friend_challenge_questions(challenge_id=challenge_id, user_id=user_id)


@router.post("/{challenge_id}/submit", response_model=SubmitFriendChallengeResponse)
async def submit_friend_challenge_endpoint(challenge_id: str, req: SubmitFriendChallengeRequest):
    return await submit_friend_challenge(
        challenge_id=challenge_id,
        user_id=req.user_id,
        answers=req.answers,
    )


@router.get("/{challenge_id}/results", response_model=FriendChallengeResultsResponse)
async def get_friend_challenge_results_endpoint(challenge_id: str):
    return await get_friend_challenge_results(challenge_id=challenge_id)
