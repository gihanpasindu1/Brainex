from fastapi import APIRouter, HTTPException, Depends
from typing import List
from ..schemas.short_note import ShortNoteCreate, ShortNoteDB, ShortNoteGenerateRequest
from ..db.mongo import short_notes_col, predefined_notes_col
from ..services.gemini_service import generate_short_note_with_gemini
import uuid
from datetime import datetime

router = APIRouter(prefix="/short_notes", tags=["Short Notes"])

@router.post("/generate")
def generate_note(request: ShortNoteGenerateRequest):
    try:
        if not request.ocr_text.strip():
            raise HTTPException(status_code=400, detail="OCR text is empty.")
        
        result = generate_short_note_with_gemini(request.ocr_text)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{user_uid}")
async def create_note(user_uid: str, note: ShortNoteCreate):
    try:
        note_id = str(uuid.uuid4())
        date_str = datetime.now().strftime("%b %d, %Y")
        
        note_dict = {
            "_id": note_id,
            "title": note.title,
            "desc": note.desc,
            "content": note.content,
            "user_uid": user_uid,
            "date": date_str
        }
        
        await short_notes_col.insert_one(note_dict)
        return note_dict
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/predefined/all")
async def get_predefined_notes():
    try:
        cursor = predefined_notes_col.find({})
        notes = await cursor.to_list(length=100)
        for note in notes:
            note["_id"] = str(note.get("_id", ""))
        return notes
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{user_uid}", response_model=List[ShortNoteDB])
async def get_notes(user_uid: str):
    try:
        cursor = short_notes_col.find({"user_uid": user_uid})
        notes = await cursor.to_list(length=100)
        return notes
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
