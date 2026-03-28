from fastapi import APIRouter, Query
import random

router = APIRouter(
    prefix="/motivation",
    tags=["Motivation"],
    responses={404: {"description": "Not found"}},
)

MOTIVATIONAL_QUOTES = [
    {"id": 1, "text": "Academic Warrior"},
    {"id": 2, "text": "Unstoppable Mind"},
    {"id": 3, "text": "Master Scholar"},
    {"id": 4, "text": "Future Legend"},
    {"id": 5, "text": "Brilliant Mind"},
    {"id": 6, "text": "Knowledge Titan"},
    {"id": 7, "text": "Daily Grind"},
    {"id": 8, "text": "Peak Focus"},
    {"id": 9, "text": "Elite Learner"},
    {"id": 10, "text": "Success Magnet"},
    {"id": 11, "text": "Power Student"},
    {"id": 12, "text": "Wisdom Seeker"},
    {"id": 13, "text": "Victory Chaser"},
    {"id": 14, "text": "Infinite Potential"},
    {"id": 15, "text": "Goal Crusher"}
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
