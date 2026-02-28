import json
from google import genai
from google.genai import types
from app.core.config import settings

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
