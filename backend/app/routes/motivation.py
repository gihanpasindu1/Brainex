from fastapi import APIRouter, Query
import random

router = APIRouter(
    prefix="/motivation",
    tags=["Motivation"],
    responses={404: {"description": "Not found"}},
)

MOTIVATIONAL_QUOTES = [
    {"id": 1, "text": "Focused Learner"},
    {"id": 2, "text": "Brain Architect"},
    {"id": 3, "text": "Exam Conqueror"},
    {"id": 4, "text": "Knowledge Seeker"},
    {"id": 5, "text": "Future Leader"},
    {"id": 6, "text": "Silent Achiever"},
    {"id": 7, "text": "Limitless Mind"},
    {"id": 8, "text": "Goal Digger"},
    {"id": 9, "text": "Daily Scholar"},
    {"id": 10, "text": "Peak Performer"},
    {"id": 11, "text": "Deep Thinker"},
    {"id": 12, "text": "Study Champion"},
    {"id": 13, "text": "Rising Star"},
    {"id": 14, "text": "Relentless Student"},
    {"id": 15, "text": "Smart Worker"}
]

@router.get("/")
def get_random_motivation(last_quote_id: int = Query(default=None, description="The ID of the last quote shown to avoid immediate repetition.")):
    available_quotes = MOTIVATIONAL_QUOTES
    
    if last_quote_id is not None:
        # Filter out the last quote to ensure it changes
        available_quotes = [q for q in MOTIVATIONAL_QUOTES if q['id'] != last_quote_id]
        
        # If somehow all got filtered (e.g., list length 1), fallback to full list
        if not available_quotes:
            available_quotes = MOTIVATIONAL_QUOTES
            
    selected_quote = random.choice(available_quotes)
    return {
        "id": selected_quote["id"],
        "quote": selected_quote["text"]
    }
