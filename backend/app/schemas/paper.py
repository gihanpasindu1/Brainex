from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Literal

Difficulty = Literal["Easy", "Medium", "Hard"]

class MCQ(BaseModel):
    question: str
    options: Dict[str, str]  # {"A":"..","B":"..","C":"..","D":".."}
    correct_answer: str      # "A" / "B" / "C" / "D"
    explanation: Optional[str] = None

class PaperCreateRequest(BaseModel):
    title: str
    difficulty: Difficulty
    duration_min: int = 120
    questions: List[MCQ] = Field(default_factory=list)

class PaperListItem(BaseModel):
    id: str
    title: str
    difficulty: Difficulty
    duration_min: int

class GeneratePaperRequest(BaseModel):
    paper_type: str
    difficulty: Difficulty
    grade: str
    term: str
    count: int = 3
    mcq_count: int = 40

