from fastapi import APIRouter, HTTPException
from bson import ObjectId

from app.db.mongo import model_papers_col
from app.schemas.modelpaper import GenerateModelPaperRequest, ModelPaperListItem
from app.services.rag_service import generate_mcqs

router = APIRouter(prefix="/modelpapers", tags=["modelpapers"])

@router.post("/generate")
async def generate_modelpapers(req: GenerateModelPaperRequest):
    # Validate term logic
    if req.paper_type == "Term" and not req.term:
        raise HTTPException(status_code=400, detail="term is required when paper_type is Term")
    if req.paper_type == "Final":
        req.term = None

    created_ids = []

    for i in range(req.count):
        questions = await generate_mcqs(
            grade=req.grade,
            paper_type=req.paper_type,
            term=req.term,
            difficulty=req.difficulty,
            mcq_count=req.mcq_count,
        )

        doc = {
            "title": f"Model Paper {i+1:02d} - {req.paper_type} - {req.difficulty}",
            "paper_type": req.paper_type,
            "grade": req.grade,
            "difficulty": req.difficulty,
            "term": req.term,
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
            "duration_min": p.get("duration_min", 120),
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
