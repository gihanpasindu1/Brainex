from pydantic import BaseModel, Field, model_validator
from typing import Dict, List, Literal, Optional

PaperType = Literal["Term", "Final", "Subject", "Past Paper"]
TermType = Literal["Term 1", "Term 2", "Term 3"]
GradeType = Literal["12", "13"]
DifficultyType = Literal["Easy", "Medium", "Hard"]

class MCQ(BaseModel):
    question: str
    options: Dict[str, str]  # {"A":"...","B":"...","C":"...","D":"...","E":"..."}
    correct_answer: Literal["A", "B", "C", "D", "E"]
    explanation: Optional[str] = None
    topic: Optional[str] = None

class GenerateModelPaperRequest(BaseModel):
    paper_type: PaperType
    grade: Optional[GradeType] = None
    difficulty: DifficultyType
    term: Optional[TermType] = None   # required only when paper_type="Term"
    topic: Optional[str] = None       # required only when paper_type="Subject"
    count: int = Field(default=1, ge=1, le=10)
    mcq_count: int = Field(default=50, ge=5, le=60)

    @model_validator(mode='before')
    @classmethod
    def clean_empty_strings(cls, values: dict) -> dict:
        for field in ['grade', 'term', 'topic']:
            # If Swagger default "string" or an empty form submission "" is passed, wipe it instantly
            val = values.get(field)
            if val in ["", "string", "none", "null"]:
                values[field] = None
        return values

class ModelPaperListItem(BaseModel):
    id: str
    title: str
    paper_type: PaperType
    grade: GradeType
    difficulty: DifficultyType
    term: Optional[TermType] = None
    topic: Optional[str] = None
    duration_min: int
    year: Optional[int] = None
    created_at: Optional[str] = None

class QuestionResult(BaseModel):
    question: str
    topic: str
    is_correct: bool

class PerformanceAnalysisRequest(BaseModel):
    user_id: Optional[str] = None
    paper_id: Optional[str] = None
    submission_id: Optional[str] = None
    results: List[QuestionResult]

class PerformanceAnalysisResponse(BaseModel):
    score: int
    total: int
    percentage: float
    strong_areas: List[str]
    improvement_areas: List[str]
    suggestions: List[str]
    xp_awarded: int = 0
    total_xp: Optional[int] = None

