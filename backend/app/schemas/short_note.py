from pydantic import BaseModel, Field
from typing import Optional

class ShortNoteCreate(BaseModel):
    title: str
    desc: str
    content: str

class ShortNoteDB(ShortNoteCreate):
    id: str = Field(alias="_id")
    user_uid: str
    date: str

class ShortNoteGenerateRequest(BaseModel):
    ocr_text: str
