from fastapi import APIRouter, HTTPException
from bson import ObjectId
from app.schemas.planner import StudyPlanRequest, StudyPlanDB, StudyPlanResponse
from app.services.planner_service import generate_study_plan_ai
from app.db.mongo import plans_col

router = APIRouter(prefix="/planner", tags=["Study Planner"])


@router.post("/generate-and-save", response_model=StudyPlanResponse)
async def create_study_plan(req: StudyPlanRequest):
    """
    1. Sends user preferences to Gemini.
    2. Receives a JSON study schedule.
    3. Saves it directly to MongoDB.
    """
    try:
        # 1. Get raw dictionary from AI
        ai_response = generate_study_plan_ai(req)

        # 2. Combine user request data with AI output to form the DB model
        db_doc = StudyPlanDB(
            user_id=req.user_id,
            exam_type=req.exam_type,
            grade=req.grade,
            term_number=req.term_number,
            weeks=ai_response.get("weeks", []),
            ai_advice=ai_response.get("ai_advice", "Good luck with your studies!")
        )

        # 3. Save to MongoDB
        result = await plans_col.insert_one(db_doc.model_dump())

        return {
            "id": str(result.inserted_id),
            "plan": db_doc
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating plan: {str(e)}")


@router.get("/user/{user_id}")
async def get_user_plans(user_id: str):
    """
    Retrieves all study plans created by a specific user.
    """
    cursor = plans_col.find({"user_id": user_id}).sort("created_at", -1)
    plans = []
    async for p in cursor:
        p["id"] = str(p["_id"])
        del p["_id"]
        plans.append(p)

    if not plans:
        raise HTTPException(status_code=404, detail="No study plans found for this user")

    return plans


@router.get("/{plan_id}")
async def get_plan_by_id(plan_id: str):
    """
    Retrieves a specific study plan by its ID.
    """
    p = await plans_col.find_one({"_id": ObjectId(plan_id)})
    if not p:
        raise HTTPException(status_code=404, detail="Plan not found")

    p["id"] = str(p["_id"])
    del p["_id"]
    return p