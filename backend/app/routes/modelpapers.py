from fastapi import APIRouter, HTTPException
from bson import ObjectId

from app.db.mongo import model_papers_col
from app.schemas.modelpaper import (
    GenerateModelPaperRequest, 
    ModelPaperListItem, 
    PerformanceAnalysisRequest, 
    PerformanceAnalysisResponse
)
from app.services.rag_service import generate_mcqs, analyze_performance

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
    created_ids = []

    for i in range(req.count):
        questions = await generate_mcqs(
            grade=req.grade,
            paper_type=req.paper_type,
            term=req.term,
            difficulty=req.difficulty,
            mcq_count=req.mcq_count,
            topic=req.topic,
        )
        
        from datetime import datetime
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M")
        
        if req.paper_type == "Final":
            title = f"Final Model Paper ({now_str})"
        elif req.paper_type == "Term":
            title = f"{req.term} - Grade {req.grade} Model Paper ({now_str})"
        elif req.paper_type == "Subject":
            title = f"Subject: {req.topic} (Grade {req.grade}) ({now_str})"
        else:
            title = f"Model Paper - {req.paper_type} ({now_str})"

        doc = {
            "title": title,
            "paper_type": req.paper_type,
            "grade": req.grade,
            "difficulty": req.difficulty,
            "term": req.term,
            "topic": req.topic,
            "duration_min": 120,
            "questions": questions,
        }

        result = await model_papers_col.insert_one(doc)
        created_ids.append(str(result.inserted_id))

    return {"created": created_ids}

@router.get("", response_model=list[ModelPaperListItem])
async def list_modelpapers():
    cursor = model_papers_col.find().sort("_id", -1).limit(50)
    items = []
    async for p in cursor:
        items.append({
            "id": str(p["_id"]),
            "title": p.get("title", "Untitled"),
            "paper_type": p["paper_type"],
            "grade": p["grade"],
            "difficulty": p["difficulty"],
            "term": p.get("term"),
            "topic": p.get("topic"),
            "duration_min": p.get("duration_min", 120),
            "created_at": p["_id"].generation_time.isoformat(),
        })
    return items

@router.get("/{paper_id}")
async def get_modelpaper(paper_id: str):
    try:
        oid = ObjectId(paper_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid paper_id")

    p = await model_papers_col.find_one({"_id": oid})
    if not p:
        raise HTTPException(status_code=404, detail="Model paper not found")

    p["id"] = str(p["_id"])
    del p["_id"]
    return p

@router.post("/analyze", response_model=PerformanceAnalysisResponse)
async def analyze_results(req: PerformanceAnalysisRequest):
    # Convert Pydantic models to dicts for the service
    results_list = [r.model_dump() for r in req.results]
    analysis = await analyze_performance(results_list)
    return analysis

