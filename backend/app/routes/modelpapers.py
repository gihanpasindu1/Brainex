from fastapi import APIRouter, HTTPException
from bson import ObjectId
from typing import Optional

from app.db.mongo import model_paper_submissions_col, model_papers_col
from app.schemas.modelpaper import (
    GenerateModelPaperRequest, 
    ModelPaperListItem, 
    PerformanceAnalysisRequest, 
    PerformanceAnalysisResponse
)
from app.services.rag_service import generate_mcqs, analyze_performance
from app.services.user_profile_service import award_model_paper_xp

router = APIRouter(prefix="/modelpapers", tags=["modelpapers"])

@router.post("/generate")
async def generate_modelpapers(req: GenerateModelPaperRequest):
    # Validate logic based on paper_type requirements
    if req.paper_type == "Subject":
        if not req.grade or not req.term or not req.topic:
            raise HTTPException(status_code=400, detail="Grade, term, and topic (subject) are all required when paper_type is Subject")
    elif req.paper_type == "Term":
        if not req.grade or not req.term:
            raise HTTPException(status_code=400, detail="Grade and term are required when paper_type is Term")
        req.topic = None # Clear topic if wrongly sent
    elif req.paper_type == "Final":
        # Final paper conceptually covers everything, so specific grades/terms/topics aren't targeted individually.
        # We default the backend generator to full "13" logic which natively scans both 12 and 13.
        req.grade = "13"
        req.term = None
        req.topic = None
    created_papers = []

    total_existing = await model_papers_col.count_documents({})

    for i in range(req.count):
        questions = await generate_mcqs(
            grade=req.grade,
            paper_type=req.paper_type,
            term=req.term,
            difficulty=req.difficulty,
            mcq_count=req.mcq_count,
            topic=req.topic,
        )

        num = total_existing + i + 1
        if req.paper_type == "Final":
            title = f"Model Paper {num} (Final)"
        elif req.paper_type == "Term":
            title = f"Model Paper {num} ({req.term} - Grade {req.grade})"
        elif req.paper_type == "Subject":
            title = f"Model Paper {num} ({req.topic})"
        else:
            title = f"Model Paper {num} ({req.paper_type})"

        doc = {
            "title": title,
            "paper_type": req.paper_type,
            "grade": req.grade,
            "difficulty": req.difficulty,
            "term": req.term,
            "topic": req.topic,
            "duration_min": 120,
            "user_id": req.user_id,
            "questions": questions,
        }

        result = await model_papers_col.insert_one(doc)
        doc["id"] = str(result.inserted_id)
        doc["created_at"] = result.inserted_id.generation_time.isoformat()
        if "_id" in doc:
            del doc["_id"]  # Remove the non-serializable ObjectId
        created_papers.append(doc)

    return {"created": created_papers}

@router.get("", response_model=list[ModelPaperListItem])
async def list_modelpapers(
    grade: Optional[str] = None, 
    term: Optional[str] = None, 
    paper_type: Optional[str] = None,
    year: Optional[int] = None,
    user_id: Optional[str] = None
):
    from typing import Any
    query: dict[str, Any] = {}
    if grade:
        query["grade"] = grade.replace("Grade-", "")
    if term:
        if "1st" in term: query["term"] = "Term 1"
        elif "2nd" in term: query["term"] = "Term 2"
        elif "3rd" in term: query["term"] = "Term 3"
        else: query["term"] = term
    if year:
        query["year"] = int(year)
    if paper_type:
        if "Term" in paper_type: query["paper_type"] = "Term"
        elif "Final" in paper_type: query["paper_type"] = "Final"
        elif "Subject" in paper_type: query["paper_type"] = "Subject"
        elif "Past" in paper_type: query["paper_type"] = "Past Paper"
        else: query["paper_type"] = paper_type
    
    if user_id:
        query["user_id"] = user_id

    cursor = model_papers_col.find(query).sort("_id", -1).limit(50)
    items = []
    async for p in cursor:
        items.append({
            "id": str(p["_id"]),
            "title": p.get("title", "Untitled"),
            "paper_type": p["paper_type"],
            "grade": p.get("grade", "13"),
            "difficulty": p.get("difficulty", "Medium"),
            "term": p.get("term"),
            "topic": p.get("topic"),
            "year": p.get("year"),
            "duration_min": p.get("duration_min", 120),
            "created_at": p["_id"].generation_time.isoformat(),
        })
    return items

@router.get("/{paper_id}")
async def get_modelpaper(paper_id: str):
    p = None
    # Try fetching by ObjectId first
    try:
        oid = ObjectId(paper_id)
        p = await model_papers_col.find_one({"_id": oid})
    except Exception:
        # Fallback to fetching by title if not a valid ObjectId
        p = await model_papers_col.find_one({"title": paper_id})

    if not p:
        raise HTTPException(status_code=404, detail="Model paper not found")

    p["id"] = str(p["_id"])
    if "_id" in p:
        del p["_id"]
    return p

@router.post("/analyze", response_model=PerformanceAnalysisResponse)
async def analyze_results(req: PerformanceAnalysisRequest):
    # Convert Pydantic models to dicts for the service
    results_list = [r.model_dump() for r in req.results]
    analysis = await analyze_performance(results_list)

    xp_awarded = 0
    total_xp = None

    if req.user_id and req.submission_id:
        submission_doc = {
            "user_id": req.user_id,
            "paper_id": req.paper_id or "model_paper",
            "submission_id": req.submission_id,
            "score": analysis["score"],
            "total": analysis["total"],
            "percentage": analysis["percentage"],
        }
        await model_paper_submissions_col.update_one(
            {
                "user_id": req.user_id,
                "submission_id": req.submission_id,
            },
            {"$setOnInsert": submission_doc},
            upsert=True,
        )
        xp_result = await award_model_paper_xp(
            req.user_id,
            paper_id=req.paper_id or "model_paper",
            submission_id=req.submission_id,
            score=analysis["score"],
        )
        xp_awarded = xp_result["xp_awarded"]
        total_xp = xp_result["profile"]["total_xp"]

    return {
        **analysis,
        "xp_awarded": xp_awarded,
        "total_xp": total_xp,
    }

