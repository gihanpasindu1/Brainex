from fastapi import APIRouter

from app.schemas.global_challenge import (
    GlobalChallengeQuestionsResponse,
    GlobalChallengeResultsResponse,
    GlobalChallengeScheduleResponse,
    JoinGlobalChallengeRequest,
    JoinGlobalChallengeResponse,
    SaveGlobalChallengeProgressRequest,
    SubmitGlobalChallengeRequest,
    SubmitGlobalChallengeResponse,
)
from app.services.global_challenge_service import (
    get_global_challenge_questions,
    get_global_challenge_results,
    get_global_challenge_schedule,
    join_global_challenge,
    preload_weekly_challenge_docs,
    save_global_challenge_progress,
    submit_global_challenge,
)

router = APIRouter(prefix="/global-challenges", tags=["global-challenges"])


@router.post("/preload")
async def preload_global_challenges_endpoint():
    result = await preload_weekly_challenge_docs()
    return {
        "message": "Global challenge papers preloaded",
        "created_count": result["created_count"],
        "total_count": result["total_count"],
    }


@router.get("/schedule", response_model=GlobalChallengeScheduleResponse)
async def get_global_challenge_schedule_endpoint():
    return await get_global_challenge_schedule()


@router.post("/{challenge_id}/join", response_model=JoinGlobalChallengeResponse)
async def join_global_challenge_endpoint(challenge_id: str, req: JoinGlobalChallengeRequest):
    return await join_global_challenge(challenge_id=challenge_id, user_id=req.user_id)


@router.get("/{challenge_id}/questions", response_model=GlobalChallengeQuestionsResponse)
async def get_global_challenge_questions_endpoint(challenge_id: str, user_id: str):
    return await get_global_challenge_questions(challenge_id=challenge_id, user_id=user_id)


@router.post("/{challenge_id}/progress")
async def save_global_challenge_progress_endpoint(
    challenge_id: str,
    req: SaveGlobalChallengeProgressRequest,
):
    return await save_global_challenge_progress(
        challenge_id=challenge_id,
        user_id=req.user_id,
        answers=req.answers,
    )


@router.post("/{challenge_id}/submit", response_model=SubmitGlobalChallengeResponse)
async def submit_global_challenge_endpoint(challenge_id: str, req: SubmitGlobalChallengeRequest):
    return await submit_global_challenge(
        challenge_id=challenge_id,
        user_id=req.user_id,
        answers=req.answers,
    )


@router.get("/{challenge_id}/results", response_model=GlobalChallengeResultsResponse)
async def get_global_challenge_results_endpoint(challenge_id: str):
    return await get_global_challenge_results(challenge_id=challenge_id)
