from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
from datetime import datetime, timedelta
from app.services.pdf_service import extract_pdf_text
from app.services.arcee_service import ask_ai

router = APIRouter()

# Define the path to the PDF file
# Assuming the script is run from 'backend' directory, the path should be relative to it
# or absolute.
# Define the path to the PDF directory
# Assuming the script is run from 'backend' directory
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PDF_DIR = os.path.join(BASE_DIR, "app", "data", "subject_pdfs")

class ChatRequest(BaseModel):
    session_id: str
    message: str


class ClearRequest(BaseModel):
    session_id: str


class ChatResponse(BaseModel):
    answer: str

# Cache for individual files: filename -> text
PDF_CACHE = {}

# In-memory session store
# session_id -> {"messages": [ {"role":"user"|"assistant","text":...}, ... ], "last_active": datetime }
SESSION_STORE: dict[str, dict] = {}

# Session config
SESSION_MAX_MESSAGES = 15
SESSION_INACTIVITY_MINUTES = 30

def get_cached_pdf_content(filename: str) -> str:
    """Lazy load and cache PDF content."""
    if filename in PDF_CACHE:
        return PDF_CACHE[filename]
    
    path = os.path.join(PDF_DIR, filename)
    if os.path.exists(path):
        print(f"Caching PDF: {filename}")
        text = extract_pdf_text(path)
        PDF_CACHE[filename] = text
        return text
    return ""


def _cleanup_sessions() -> None:
    """Remove sessions inactive for more than SESSION_INACTIVITY_MINUTES."""
    now = datetime.utcnow()
    to_delete = []
    for sid, info in list(SESSION_STORE.items()):
        last = info.get("last_active")
        if not last:
            to_delete.append(sid)
            continue
        if now - last > timedelta(minutes=SESSION_INACTIVITY_MINUTES):
            to_delete.append(sid)
    for sid in to_delete:
        print(f"Cleaning up session: {sid}")
        del SESSION_STORE[sid]

@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Endpoint that maintains in-memory session conversation history and
    forwards the full history to the AI service so the model can remember.
    """
    # Cleanup old sessions on each call (simple strategy)
    _cleanup_sessions()

    # Ensure session exists
    sid = request.session_id
    if sid not in SESSION_STORE:
        SESSION_STORE[sid] = {"messages": [], "last_active": datetime.utcnow()}

    session = SESSION_STORE[sid]

    # Append user message to session history
    session["messages"].append({"role": "user", "text": request.message})

    # Trim history to last N messages
    if len(session["messages"]) > SESSION_MAX_MESSAGES:
        session["messages"] = session["messages"][-SESSION_MAX_MESSAGES:]

    # Build a context string for classification using recent messages
    context_for_classify = " \n ".join([m.get("text", "") for m in session["messages"][-6:]])

    # 1. Classify subject (use recent conversation for context)
    from app.services.arcee_service import classify_subject
    subject_filenames = classify_subject(context_for_classify)

    # 2. Load text for those subjects
    print(f"\n[DEBUG] Message: {request.message}")
    print(f"[DEBUG] Classification input: {context_for_classify}")
    print(f"[DEBUG] Selected PDFs: {subject_filenames}")

    combined_text_parts = []
    for fname in subject_filenames:
        content = get_cached_pdf_content(fname)
        if content:
            combined_text_parts.append(f"--- SOURCE: {fname} ---\n{content}")

    final_pdf_text = "\n\n".join(combined_text_parts)

    # Convert history to Gemini format: user -> "user", assistant -> "model"
    history_for_ai = []
    for m in session["messages"]:
        role = "user" if m.get("role") == "user" else "model"
        history_for_ai.append({"role": role, "content": m.get("text", "")})

    # 3. Ask AI with history and optional pdf text
    response_data = await ask_ai(request.message, final_pdf_text, history=history_for_ai)

    # Extract answer
    answer = response_data.get("answer", "")

    # Append assistant reply to session history
    session["messages"].append({"role": "assistant", "text": answer})

    # Trim again if needed
    if len(session["messages"]) > SESSION_MAX_MESSAGES:
        session["messages"] = session["messages"][-SESSION_MAX_MESSAGES:]

    # Update last active
    session["last_active"] = datetime.utcnow()

    return {"answer": answer}


@router.post("/chat/clear")
async def clear_session(request: ClearRequest):
    """Clear a session by `session_id` from in-memory store."""
    sid = request.session_id
    if sid in SESSION_STORE:
        del SESSION_STORE[sid]
        return {"status": "cleared"}
    return {"status": "not_found"}
