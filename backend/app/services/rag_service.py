import json, random, logging, os
from typing import Optional, List
from app.core.config import settings
from app.db.mongo import syllabus_chunks_col, mcq_bank_col

logger = logging.getLogger(__name__)

SYLLABUS_MAP = {
    "12": {
        "Term 1": [
            "Unit 1: Basic Concepts of ICT",
            "Unit 2: Introduction to Computer",
            "Unit 3: Data Representation"
        ],
        "Term 2": [
            "Unit 4: Digital Circuits",
            "Unit 5: Operating Systems",
            "Unit 6: Data Communication & Networking"
        ],
        "Term 3": [
            "Unit 7: System Analysis & Design",
            "Unit 8: Database Management"
        ]
    },
    "13": {
        "Term 1": ["Unit 9: Programming"],
        "Term 2": ["Unit 10: Web Development", "Unit 11: Internet of Things (IoT)"],
        "Term 3": ["Unit 12: ICT in Business", "Unit 13: New Trends in ICT"]
    }
}

PDF_MAP = {
    "13": {
        "Term 1": [
            "03_Algorithms_and_Theory.pdf",
            "04_Python_Basics.pdf",
            "05_Python_Control_Structures.pdf",
            "06_Python_Functions.pdf",
            "07_Python_Data_Structures.pdf",
            "08_Python_File_Handling.pdf",
            "09_Python_Database_MySQL.pdf"
        ],
        "Term 2": [
            "10_HTML.pdf",
            "11_CSS.pdf",
            "12_PHP_and_Dynamic_Web.pdf",
            "01_Embedded_Systems.pdf",
            "02_IoT.pdf"
        ],
        "Term 3": [
            "13_E_Commerce.pdf",
            "14_Future_Trends_ICT.pdf"
        ]
    }
}

def _get_query_and_topics(grade: str, paper_type: str, term: Optional[str], specific_topic: Optional[str]):
    q = {}
    target_topics = []
    target_pdfs = []
    
    if paper_type == "Final":
        if grade == "12":
            q["grade"] = "12"
            for t in ["Term 1", "Term 2", "Term 3"]:
                target_topics.extend(SYLLABUS_MAP["12"].get(t, []))
        elif grade == "13":
            q["grade"] = {"$in": ["12", "13"]}
            for t in ["Term 1", "Term 2", "Term 3"]:
                target_topics.extend(SYLLABUS_MAP["12"].get(t, []))
                target_topics.extend(SYLLABUS_MAP["13"].get(t, []))
                target_pdfs.extend(PDF_MAP["13"].get(t, []))
    else:
        q["grade"] = grade
        if term:
            q["term"] = term
            target_topics = SYLLABUS_MAP.get(grade, {}).get(term, [])
            if grade == "13":
                target_pdfs = PDF_MAP["13"].get(term, [])
            
    if specific_topic:
        import re
        q["topic"] = {"$regex": re.escape(specific_topic), "$options": "i"}
        target_topics = [specific_topic]

    return q, target_topics, target_pdfs

def _extract_json(text: str) -> dict:
    try:
        return json.loads(text)
    except Exception:
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise ValueError("Model did not return JSON.")
        return json.loads(text[start:end+1])

async def _retrieve_pdf_context(pdfs: List[str], max_chars: int = 15000) -> str:
    if not pdfs:
        return ""
    try:
        from pypdf import PdfReader
    except ImportError:
        logger.warning("pypdf not installed, skipping PDF context.")
        return ""

    pdf_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "subject_pdfs"))
    text_chunks = []
    
    for pdf_name in pdfs:
        pdf_path = os.path.join(pdf_dir, pdf_name)
        if not os.path.exists(pdf_path):
            continue
        try:
            reader = PdfReader(pdf_path)
            pages = list(range(len(reader.pages)))
            random.shuffle(pages)
            for p_num in pages[:2]:
                t =  reader.pages[p_num].extract_text()
                if t:
                    text_chunks.append(t)
        except Exception as e:
            logger.error(f"Error reading PDF {pdf_name}: {e}")
            
    random.shuffle(text_chunks)
    combined = "\n\n".join(text_chunks)
    return combined[:max_chars]

async def _retrieve_db_context(query: dict, limit: int = 40) -> str:
    chunks = []
    cursor = syllabus_chunks_col.find(query).limit(limit)
    async for c in cursor:
        txt = (c.get("text") or "").strip()
        if txt:
            chunks.append(txt)
    random.shuffle(chunks)
    return "\n\n".join(chunks)

async def _retrieve_context(query: dict, target_pdfs: List[str]) -> str:
    pdf_text = await _retrieve_pdf_context(target_pdfs)
    db_text = await _retrieve_db_context(query)
    
    combined = f"{pdf_text}\n\n{db_text}"
    return combined.strip()

async def _bank_question_texts(query: dict) -> set[str]:
    texts = set()
    cursor = mcq_bank_col.find(query, {"question": 1}).limit(3000)
    async for m in cursor:
        t = (m.get("question") or "").strip().lower()
        if t:
            texts.add(t)
    return texts

async def _fallback_from_bank(query: dict, mcq_count: int, default_topic: str) -> List[dict]:
    if mcq_count <= 0:
        return []

    bank = []
    cursor = mcq_bank_col.find(query).limit(1000)
    async for m in cursor:
        ans = m.get("answer") or m.get("correct_answer")
        if ans not in ["A", "B", "C", "D"]:
            continue
        bank.append({
            "question": m["question"],
            "options": m["options"],
            "correct_answer": ans,
            "explanation": m.get("explanation", "From question bank."),
            "topic": m.get("topic", default_topic),
            "difficulty": m.get("difficulty", "Medium"),
        })

    random.shuffle(bank)
    if not bank:
        return []
    return bank[:mcq_count] if len(bank) >= mcq_count else (bank * (mcq_count // len(bank) + 1))[:mcq_count]

def _gemini_generate(prompt: str) -> str:
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY missing.")
    from google import genai
    from google.genai import types
    client = genai.Client(api_key=settings.GEMINI_API_KEY)
    resp = client.models.generate_content(
        model="gemini-3.1-pro-preview",
        contents=types.Part.from_text(text=prompt),
        config=types.GenerateContentConfig(
            temperature=0.6,
            max_output_tokens=3000,
            response_mime_type="application/json",
        ),
    )
    return resp.text or ""

async def generate_mcqs(
    grade: str,
    paper_type: str,
    term: Optional[str],
    difficulty: str,
    mcq_count: int,
    topic: Optional[str] = None,
) -> List[dict]:

    gen_count = int(mcq_count * 0.4)
    bank_count = mcq_count - gen_count

    db_query, target_topics, target_pdfs = _get_query_and_topics(grade, paper_type, term, topic)
    topic_str = ", ".join(target_topics) if target_topics else "General IT Syllabus"

    context = await _retrieve_context(db_query, target_pdfs)

    bank_texts = await _bank_question_texts(db_query)

    prompt = f"""
You are a Sri Lankan A/L ICT MCQ paper setter.

Generate {gen_count} NEW MCQs.
Syllabus Units to cover:
{topic_str}

Grade: {grade}
Paper Type: {paper_type}
Term: {term if term else "Final/Full syllabus"}
Difficulty: {difficulty}

Rules:
- 4 options A,B,C,D
- Only ONE correct answer
- Do NOT copy any question verbatim from a question bank or past papers.
- Create NEW questions strictly based on the provided context (change scenarios/numbers/examples).
- Distribute questions evenly across the listed Syllabus Units.
- Output ONLY JSON (no markdown, no extra text)
- VERY IMPORTANT: Escape all double quotes inside strings properly using \". Do not use unescaped " marks inside questions or option strings, otherwise the JSON will break!
- IMPORTANT: DO NOT use any unescaped special characters, Python dictionaries, JSON brackets `{{` `}}` or arrays `[` `]` inside your actual question text or options. Represent code snippets using single quotes.

JSON format:
{{
  "questions": [
    {{
      "question": "...",
      "options": {{"A":"...","B":"...","C":"...","D":"..."}},
      "correct_answer": "A",
      "explanation": "short explanation",
      "topic": "Put the actual Unit name here",
      "difficulty": "{difficulty}"
    }}
  ]
}}

Context (use only this):
{context}
""".strip()

    cleaned = []
    if gen_count > 0:
        try:
            raw = _gemini_generate(prompt)
            data = _extract_json(raw)
            questions = data.get("questions", [])

            for q_obj in questions:
                qt = (q_obj.get("question") or "").strip()
                if not qt:
                    continue
                if qt.lower() in bank_texts:
                    continue
                if q_obj.get("correct_answer") in ["A", "B", "C", "D"]:
                    cleaned.append(q_obj)

            missing = gen_count - len(cleaned)
            if missing > 0:
                extra = await _fallback_from_bank(db_query, missing, target_topics[0] if target_topics else "General")
                cleaned.extend(extra)

        except Exception as e:
            logger.exception("Gemini failed, fallback used. Error=%s", str(e))
            cleaned.extend(await _fallback_from_bank(db_query, gen_count, target_topics[0] if target_topics else "General"))

    if bank_count > 0:
        bank_questions = await _fallback_from_bank(db_query, bank_count, target_topics[0] if target_topics else "General")
        cleaned.extend(bank_questions)

    # FINAL FAILSAFE: If the MCQ bank didn't have enough questions to fulfill bank_count,
    # we ask Gemini to dynamically generate the absolute missing difference so we don't return []!
    final_missing = mcq_count - len(cleaned)
    if final_missing > 0:
        prompt_fallback = prompt.replace(f"Generate {gen_count} NEW MCQs.", f"Generate {final_missing} NEW MCQs.")
        try:
            raw = _gemini_generate(prompt_fallback)
            data = _extract_json(raw)
            for q_obj in data.get("questions", []):
                qt = (q_obj.get("question") or "").strip()
                if not qt or qt.lower() in bank_texts:
                    continue
                if q_obj.get("correct_answer") in ["A", "B", "C", "D"]:
                    cleaned.append(q_obj)
        except Exception as e:
            logger.exception("Final Gemini fallback failed. Error=%s", str(e))

    random.shuffle(cleaned)
    return cleaned[:mcq_count]
