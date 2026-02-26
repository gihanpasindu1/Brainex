from pydantic import BaseModel, Field
from typing import Dict, List, Literal, Optional

PaperType = Literal["Term", "Final"]
TermType = Literal["Term 1", "Term 2", "Term 3"]
GradeType = Literal["12", "13"]
DifficultyType = Literal["Easy", "Medium", "Hard"]

class MCQ(BaseModel):
    question: str
    options: Dict[str, str]  # {"A":"...","B":"...","C":"...","D":"..."}
    correct_answer: Literal["A", "B", "C", "D"]
    explanation: Optional[str] = None
    topic: Optional[str] = None

class GenerateModelPaperRequest(BaseModel):
    paper_type: PaperType
    grade: GradeType
    difficulty: DifficultyType
    term: Optional[TermType] = None   # required only when paper_type="Term"
    count: int = Field(default=1, ge=1, le=10)
    mcq_count: int = Field(default=30, ge=5, le=60)

class ModelPaperListItem(BaseModel):
    id: str
    title: str
    paper_type: PaperType
    grade: GradeType
    difficulty: DifficultyType
    term: Optional[TermType] = None
    duration_min: int
