from fastapi import APIRouter, HTTPException
from app.db.mongo import past_papers_col, model_papers_col
from typing import Dict, Any

router = APIRouter(prefix="/pastpapers", tags=["pastpapers"])

@router.get("", response_model=list[Dict[str, Any]])
async def list_available_past_papers():
    """List all years that have questions in the past_papers collection."""
    years = await past_papers_col.distinct("year")
    papers = []
    # Sort years descending
    for y in sorted(years, key=lambda x: str(x), reverse=True):
        papers.append({
            "id": f"past_{y}",  # Virtual ID format
            "title": f"Official G.C.E. A/L {y} Past Paper",
            "paper_type": "Past Paper",
            "year": y,
            "created_at": None,
            "grade": "13",
            "difficulty": "Official",
            "duration_min": 120,
            "is_virtual": True
        })
    return papers

@router.get("/{year_val}")
async def get_past_paper_by_year(year_val: str):
    """Retrieve a complete paper object for a specific year directly from past_papers_col."""
    query = {"$or": [{"year": year_val}]}
    try:
        y_int = int(year_val)
        query["$or"].append({"year": y_int})
    except:
        pass

    cursor = past_papers_col.find(query)
    questions = []
    async for q in cursor:
        q["id"] = str(q["_id"])
        del q["_id"]
        questions.append(q)
    
    if not questions:
        raise HTTPException(status_code=404, detail=f"Paper for year {year_val} not found.")

    return {
        "id": f"past_{year_val}",
        "title": f"Official G.C.E. A/L {year_val} Past Paper",
        "paper_type": "Past Paper",
        "grade": "13",
        "year": year_val,
        "difficulty": "Official",
        "duration_min": 120,
        "questions": questions,
    }

@router.post("/generate")
async def generate_past_paper(req: Dict[str, Any]):
    year_val = req.get("year")
    if not year_val:
        raise HTTPException(status_code=400, detail="Year is required")
    
    # Create flexible query for year as string or integer
    query = {"$or": [{"year": year_val}]}
    try:
        y_int = int(year_val)
        if y_int != year_val:
            query["$or"].append({"year": y_int})
    except:
        pass
        
    try:
        y_str = str(year_val)
        if y_str != year_val:
            query["$or"].append({"year": y_str})
    except:
        pass

    # Find questions for the year in the past_papers collection
    cursor = past_papers_col.find(query)
    questions = []
    async for q in cursor:
        q["id"] = str(q["_id"])
        del q["_id"]
        questions.append(q)
    
    if not questions:
        raise HTTPException(
            status_code=404, 
            detail=f"No questions found for the year {year_val} in the 'past_papers' collection."
        )

    # Wrap as a complete paper document
    doc = {
        "title": f"Official G.C.E. A/L {year_val} Past Paper",
        "paper_type": "Past Paper",
        "grade": "13",
        "difficulty": "Official",
        "year": year_val,
        "duration_min": 120,
        "questions": questions,
    }
    
    # We still insert it to model_papers_col so that the existing papers_screen.dart 
    # fetch logic can find it and list it under "Suggested Papers".
    result = await model_papers_col.insert_one(doc)
    
    return {
        "created": [str(result.inserted_id)],
        "question_count": len(questions)
    }
