from fastapi import APIRouter
from pydantic import BaseModel
from app.services.gemini_service import ask_gemini

router = APIRouter(prefix="/chat", tags=["Chatbot"])

# This defines what data the user sends
class ChatRequest(BaseModel):
    question: str

# This is our chatbot API 
@router.post("/")
def chatbot(req: ChatRequest):
    answer = ask_gemini(req.question)
    return {
        "answer": answer,
        "sources": []
    }
