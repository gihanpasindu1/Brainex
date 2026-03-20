from app.db.mongo import past_papers_col, mcq_bank_col
from typing import List, Dict, Any, Optional
import re

async def get_question_by_year_and_number(year: int | str, question_number: int | str) -> Optional[Dict[str, Any]]:
    """
    Fetch a specific MCQ question from mcq_bank_col.
    """
    try:
        y_int = int(year)
        q_int = int(question_number)
    except (ValueError, TypeError):
        return None

    query = {
        "year": {"$in": [y_int, str(y_int)]},
        "$or": [
            {"question_number": {"$in": [q_int, str(q_int)]}},
            {"question_num": {"$in": [q_int, str(q_int)]}}
        ]
    }
    
    question = await mcq_bank_col.find_one(query)
    if not question:
        # Fallback to papers collection if not in mcq_bank
        # NOTE: Papers might store questions as individual docs or in an array
        question = await past_papers_col.find_one(query)
        if not question:
            # Check if it's in a paper document array (old structure)
            paper_query = {"year": {"$in": [y_int, str(y_int)]}, "questions": {"$exists": True}}
            async for paper in past_papers_col.find(paper_query):
                for q in paper.get("questions", []):
                    if str(q.get("question_number")) == str(q_int) or str(q.get("question_num")) == str(q_int):
                        return q
    return question

async def get_questions_by_unit(unit_query: str) -> List[Dict[str, Any]]:
    """
    Fetch all questions for a specific unit from mcq_bank_col.
    Handles various unit formats like 'Unit 10', 'Unit 9', etc.
    """
    # Extract unit number if possible
    match = re.search(r"unit\s*(\d+)", unit_query.lower())
    if match:
        unit_num = match.group(1)
        # Search for units starting with 'Unit X'
        regex = re.compile(fr"^Unit {unit_num}(\D|$)", re.IGNORECASE)
        query = {"unit": regex}
    else:
        # Generic search
        query = {"unit": {"$regex": unit_query, "$options": "i"}}
    
    cursor = mcq_bank_col.find(query).sort([("year", -1), ("question_number", 1)])
    questions = []
    async for q in cursor:
        questions.append(q)
    
    return questions
