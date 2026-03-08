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
    hours_per_day: int = Field(..., ge=1, le=12)
    days_to_exam: int = Field(..., ge=7)

# --- AI Response / Sub-models ---
class DailyTask(BaseModel):
    day_number: int
    topic: str
    subtopics: List[str]
    estimated_minutes: int
    task_type: str

class WeeklyPlan(BaseModel):
    week_number: int
    focus_area: str
    daily_tasks: List[DailyTask]

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