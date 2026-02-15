from fastapi import APIRouter, HTTPException
from bson import ObjectId
from app.db.mongo import papers_col
from app.schemas.paper import PaperCreateRequest, PaperListItem
from app.schemas.paper import GeneratePaperRequest
import random


router = APIRouter(prefix="/papers", tags=["papers"])

@router.post("")
async def create_paper(req: PaperCreateRequest):
    doc = req.model_dump()
    result = await papers_col.insert_one(doc)
    return {"id": str(result.inserted_id)}

@router.get("", response_model=list[PaperListItem])
async def list_papers():
    cursor = papers_col.find().limit(50)
    items = []
    async for p in cursor:
        items.append({
            "id": str(p["_id"]),
            "title": p["title"],
            "difficulty": p["difficulty"],
            "duration_min": p.get("duration_min", 120),
        })
    return items

@router.get("/{paper_id}")
async def get_paper(paper_id: str):
    p = await papers_col.find_one({"_id": ObjectId(paper_id)})
    if not p:
        raise HTTPException(status_code=404, detail="Paper not found")
    p["id"] = str(p["_id"])
    del p["_id"]
    return p

def generate_dummy_mcqs(count: int, difficulty: str):
    questions = []
    for i in range(count):
        questions.append({
            "question": f"Sample Question {i+1} ({difficulty})",
            "options": {
                "A": "Option A",
                "B": "Option B",
                "C": "Option C",
                "D": "Option D"
            },
            "correct_answer": random.choice(["A", "B", "C", "D"]),
            "explanation": "This is a sample explanation"
        })
    return questions


@router.post("/generate")
async def generate_papers(req: GeneratePaperRequest):
    created_ids = []

    for i in range(req.count):
        paper_doc = {
            "title": f"Model Paper {i+1:02d} - {req.difficulty}",
            "paper_type": req.paper_type,
            "difficulty": req.difficulty,
            "grade": req.grade,
            "term": req.term,
            "duration_min": 120,
            "questions": generate_dummy_mcqs(req.mcq_count, req.difficulty)
        }

        result = await papers_col.insert_one(paper_doc)
        created_ids.append(str(result.inserted_id))

    return {"created": created_ids}
