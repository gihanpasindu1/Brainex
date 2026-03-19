import os
from google import genai
import json
from google import genai
from google.genai import types
from app.core.config import settings


SYSTEM_PROMPT = """
always remember u explain things to grade one student
"""

def ask_gemini(question: str) -> str:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return "GEMINI_API_KEY not found."

    client = genai.Client(api_key=api_key)

    full_prompt = f"""
{SYSTEM_PROMPT}

Student question:
{question}
"""

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=full_prompt
    )

    return response.text or "No response from Gemini."


def _extract_json(text: str) -> dict:
    # Gemini sometimes returns extra text; safely extract JSON object
    try:
        return json.loads(text)
    except Exception:
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise ValueError("Gemini did not return JSON.")
        return json.loads(text[start:end+1])
    
def generate_mcqs_with_gemini(context: str, topic: str, grade: str, term: str | None, difficulty: str, mcq_count: int) -> list[dict]:
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY missing in .env")

    client = genai.Client(api_key=settings.GEMINI_API_KEY)

    term_line = f"Term: {term}" if term else "Term: (Final/Full syllabus)"
    prompt = f"""
You are an A/L ICT MCQ paper setter (Sri Lanka).

Generate {mcq_count} MCQs.
Topic: {topic}
Grade: {grade}
{term_line}
Difficulty: {difficulty}

Rules:
- 4 options A,B,C,D
- Only ONE correct answer
- Return ONLY valid JSON (no markdown, no explanation outside JSON)
- STRICT RULE: Do NOT use ANY double quotes (") inside the question text, options, or explanations. Use single quotes (') instead.
- STRICT RULE: Do NOT include literal newlines inside strings. If you need a newline, use \\n.

JSON format:
{{
  "questions": [
    {{
      "question": "...",
      "options": {{"A":"...","B":"...","C":"...","D":"..."}},
      "correct_answer": "A",
      "explanation": "short explanation",
      "topic": "{topic}",
      "difficulty": "{difficulty}"
    }}
  ]
}}

Context (use only this):
{context}
""".strip()

    resp = client.models.generate_content(
        model="gemini-3.1-pro-preview",
        contents=types.Part.from_text(text=prompt),
        config=types.GenerateContentConfig(
            temperature=0.6,
            max_output_tokens=2048
        ),
    )

    data = _extract_json(resp.text)
    return data["questions"]


def generate_short_note_with_gemini(ocr_text: str) -> dict:
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY missing in .env")

    client = genai.Client(api_key=settings.GEMINI_API_KEY)

    prompt = f"""
You are an expert tutor. Please take the following raw OCR text and structure it into a clean, easy-to-read Short Note.
Extract a suitable "title" for the note, and rewrite the text into a well-formatted "desc" (description) that summarizes and organizes the key points.

Rules:
- Return ONLY valid JSON (no markdown, no explanation outside JSON).
- The JSON must have exactly two string keys: "title" and "desc".
- Do NOT use ANY double quotes (") inside the title or description strings. Use single quotes (') instead.
- Do NOT include literal newlines inside strings. If you need a newline, use \\n.

Raw OCR Text:
{ocr_text}
""".strip()

    resp = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=types.Part.from_text(text=prompt),
        config=types.GenerateContentConfig(
            temperature=0.4,
            max_output_tokens=2048
        ),
    )

    data = _extract_json(resp.text)
    return data
