from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/chat", tags=["Chatbot"])

# This defines what data the user sends
class ChatRequest(BaseModel):
    question: str

# This is our chatbot API hhhh
@router.post("/")
def chatbot(req: ChatRequest):
    return {
        "answer": f"(mock) You asked: {req.question}",
        "sources": []
    }
