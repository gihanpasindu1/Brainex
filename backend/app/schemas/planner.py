from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

# --- Incoming Request Models ---
class StudyPlanRequest(BaseModel):
    user_id: str
    exam_type: str = Field(..., description="'Final Exam' or 'Term Exam'")
    grade: str = Field(..., description="'Grade 12' or 'Grade 13'")
    term_number: Optional[int] = Field(None, description="1, 2, or 3 (if Term Exam)")
    weak_topics: List[str] = Field(default_factory=list, description="Topics user struggles with")
    weeks_to_exam: int = Field(..., ge=1, description="Number of weeks until the exam")

# --- AI Response / Sub-models ---
class WeeklyPlan(BaseModel):
    week_number: int
    focus_area: str
    topics_to_cover: List[str]
    suggested_hours_per_day: int
    study_advice: str

# --- Database Model ---
class StudyPlanDB(BaseModel):
    user_id: str
    exam_type: str
    grade: str
    term_number: Optional[int]
    created_at: datetime = Field(default_factory=datetime.utcnow)
    weeks: List[WeeklyPlan]
    ai_advice: str

class StudyPlanResponse(BaseModel):
    id: str
    plan: StudyPlanDB