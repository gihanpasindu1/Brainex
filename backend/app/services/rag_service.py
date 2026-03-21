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

# ---------------------------------------------------------------------------
# TOPIC WEIGHTAGE TABLE  (source: official A/L ICT final exam weight table)
# Keys must match the unit strings used in SYLLABUS_MAP exactly.
# Weights do NOT need to sum to 100 — they are normalised at runtime.
# ---------------------------------------------------------------------------
TOPIC_WEIGHTS: dict[str, int] = {
    "Unit 1: Basic Concepts of ICT":          5,
    "Unit 2: Introduction to Computer":       4,
    "Unit 3: Data Representation":             6,
    "Unit 4: Digital Circuits":                8,
    "Unit 5: Operating Systems":               7,
    "Unit 6: Data Communication & Networking": 10,
    "Unit 7: System Analysis & Design":        20,
    "Unit 8: Database Management":             12,
    "Unit 9: Programming":                     25,
    "Unit 10: Web Development":                18,
    "Unit 11: Internet of Things (IoT)":       5,
    "Unit 12: ICT in Business":                3,
    "Unit 13: New Trends in ICT":              4,
}


def _compute_topic_distribution(topics: List[str], total: int) -> dict:
    """
    Distribute `total` questions across `topics` proportionally by TOPIC_WEIGHTS.
    Uses the largest-remainder (Hamilton) method so the sum equals `total` exactly.
    Topics absent from TOPIC_WEIGHTS receive equal weight = 1 (uniform fallback).
    """
    if not topics or total <= 0:
        return {}

    weights = {t: TOPIC_WEIGHTS.get(t, 1) for t in topics}
    total_weight = sum(weights.values())

    dist: dict[str, int] = {}
    allocated = 0
    remainders: list[tuple[float, str]] = []

    for topic, w in weights.items():
        exact = (w / total_weight) * total
        floor_val = int(exact)
        dist[topic] = floor_val
        allocated += floor_val
        remainders.append((exact - floor_val, topic))

    # Award leftover slots to topics with the largest fractional remainders
    leftover = total - allocated
    remainders.sort(key=lambda x: -x[0])
    for i in range(leftover):
        dist[remainders[i % len(remainders)][1]] += 1

    return dist


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
        
        # If it's a specific topic (Subject wise paper), fetch the correct PDF for it
        if grade in PDF_MAP:
            # Search all terms in grade PDF mapping to find the matching module
            for term_name, term_pdfs in PDF_MAP[grade].items():
                if term_name in SYLLABUS_MAP.get(grade, {}):
                    term_topics = SYLLABUS_MAP[grade][term_name]
                    if specific_topic in term_topics:
                        # Find index of topic to guess corresponding PDF
                        topic_idx = term_topics.index(specific_topic)
                        if topic_idx < len(term_pdfs):
                            target_pdfs = [term_pdfs[topic_idx]]
                            break

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

async def _retrieve_teacher_guide_context(target_topics: List[str], max_chars: int = 15000) -> str:
    if not target_topics:
        return ""
    try:
        from pypdf import PdfReader
    except ImportError:
        logger.warning("pypdf not installed, skipping Teacher Guide context.")
        return ""

    teacher_guide_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "teacher_guides"))
    text_chunks = []
    
    grade_dirs = ["grade12_teacher_guide.pdf", "grade13_teacher_guide.pdf"]
    
    for topic in target_topics:
        safe_topic_name = topic.replace(":", "") + ".pdf"
        
        pdf_path = None
        for g_dir in grade_dirs:
            potential_path = os.path.join(teacher_guide_dir, g_dir, safe_topic_name)
            if os.path.exists(potential_path):
                pdf_path = potential_path
                break
                
        if not pdf_path:
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
            logger.error(f"Error reading Teacher Guide for {topic}: {e}")
            
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

async def _retrieve_context(query: dict, target_pdfs: List[str], target_topics: List[str] = None) -> str:
    pdf_text = await _retrieve_pdf_context(target_pdfs)
    guide_text = await _retrieve_teacher_guide_context(target_topics or [])
    
    combined = f"{pdf_text}\n\n{guide_text}"
    return combined.strip()

async def _bank_question_texts(query: dict) -> set[str]:
    texts = set()
    cursor = mcq_bank_col.find(query, {"question": 1}).limit(3000)
    async for m in cursor:
        t = (m.get("question") or "").strip().lower()
        if t:
            texts.add(t)
    return texts

async def _count_bank_questions(query: dict) -> int:
    """Return how many VALID (A/B/C/D/E answer) questions exist in the MCQ bank for this query."""
    count = 0
    cursor = mcq_bank_col.find(query, {"answer": 1, "correct_answer": 1}).limit(5000)
    async for m in cursor:
        ans = m.get("answer") or m.get("correct_answer")
        if ans in ["A", "B", "C", "D", "E"]:
            count += 1
    return count


async def _safe_sample_bank(query: dict, needed: int, default_topic: str) -> List[dict]:
    """
    Fetch UP TO `needed` UNIQUE questions from the MCQ bank.
    Unlike the old fallback, we NEVER duplicate raw questions — a unique bank question is
    only ever sent to Gemini once per paper.  If the bank has fewer than `needed`, we just
    return what's available and let the caller shift the deficit to Gemini generation.
    """
    bank: List[dict] = []
    cursor = mcq_bank_col.find(query).limit(5000)
    async for m in cursor:
        ans = m.get("answer") or m.get("correct_answer")
        if ans not in ["A", "B", "C", "D", "E"]:
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
    # Return at most `needed` — never duplicate
    return bank[:needed]


async def _paraphrase_questions(batch: List[dict], grade: str, difficulty: str, batch_size: int = 8) -> List[dict]:
    """Send a batch of raw DB questions to Gemini and return rephrased versions.
    The original DB explanation is stripped before sending so Gemini must write a fresh one.
    Returns only successfully rephrased questions (never the raw originals)."""
    result = []
    for i in range(0, len(batch), batch_size):
        chunk = batch[i:i + batch_size]

        # Strip the original DB explanation so Gemini CANNOT copy it — it must write its own
        chunk_for_gemini = [
            {k: v for k, v in q.items() if k != "explanation"} for q in chunk
        ]
        batch_text = json.dumps(chunk_for_gemini, indent=2)

        prompt_paraphrase = f"""
You are a Sri Lankan A/L ICT MCQ paper setter.
You are given {len(chunk)} existing MCQ questions from a question bank.
Your task is to REWRITE each question in a completely different way — change the scenario, wording, and examples — while still testing the EXACT SAME concept at the same difficulty level.

Grade: {grade}
Difficulty: {difficulty}

QUESTION REWRITING RULES:
- NEVER copy the original question text. Rewrite it entirely with a new scenario or angle.
- Keep exactly 5 options A, B, C, D, E. The correct answer letter may change if you reorder options.
- The rewritten question must feel like a brand new question to a student.

EXPLANATION RULES (critical — this is the most important part):
- Write a completely NEW, detailed explanation from scratch. There is no original explanation provided.
- The explanation MUST clearly state WHY the correct answer is right, using the underlying ICT concept or logic.
- The explanation MUST briefly mention WHY each of the other 4 wrong options is incorrect.
- Write 3 to 5 clear sentences that would genuinely help a Grade {grade} Sri Lankan A/L ICT student understand the concept.
- Use simple, accurate English. Avoid vague phrases like 'it is correct because it is correct'.

OUTPUT RULES:
- Return ONLY valid JSON.
- IMPORTANT JSON RULES:
  1. ALL keys and string values MUST be enclosed in double quotes (").
  2. Do NOT use unescaped double quotes inside strings. If you must use a quote inside a question or explanation, use a single quote (').
  3. Do NOT include literal newlines in strings. Use the exact characters \\n if you need a newline.

Original questions to REWRITE (no explanations provided — you must generate them):
{batch_text}

Required JSON output format:
{{
  "questions": [
    {{
      "question": "completely rewritten question text...",
      "options": {{"A":"...","B":"...","C":"...","D":"...","E":"..."}},
      "correct_answer": "Correct option letter (A/B/C/D/E)",
      "explanation": "WHY the correct answer is right (concept/logic). WHY option X is wrong. WHY option Y is wrong. WHY option Z is wrong. 3-5 sentences total.",
      "topic": "topic from the original question",
      "difficulty": "{difficulty}"
    }}
  ]
}}
""".strip()

        try:
            raw = await _gemini_generate(prompt_paraphrase)
            data = _extract_json(raw)
            for q_obj in data.get("questions", []):
                qt = (q_obj.get("question") or "").strip()
                if not qt:
                    continue
                if q_obj.get("correct_answer") in ["A", "B", "C", "D", "E"]:
                    result.append(q_obj)
        except Exception as e:
            logger.exception("Gemini paraphrase batch failed (chunk %d). Error=%s", i, str(e))
            # Do NOT fall back to raw questions — skip this batch
    return result

import asyncio

async def _gemini_generate(prompt: str) -> str:
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY missing.")
    from google import genai
    from google.genai import types
    
    def _run():
        client = genai.Client(api_key=settings.GEMINI_API_KEY)
        return client.models.generate_content(
            model="gemini-2.5-flash",
            contents=types.Part.from_text(text=prompt),
            config=types.GenerateContentConfig(
                temperature=0.6,
                max_output_tokens=8192,
                response_mime_type="application/json",
            ),
        )
        
    resp = await asyncio.to_thread(_run)
    return resp.text or ""


async def _gemini_generate_for_topic(
    topic: str,
    count: int,
    grade: str,
    paper_type: str,
    term: Optional[str],
    difficulty: str,
    context: str,
    bank_texts: set,
    batch_size: int = 8,
) -> List[dict]:
    """
    Use Gemini to generate `count` fresh MCQs strictly for one specific topic.
    Enforces the topic label on every returned question.
    """
    result: List[dict] = []
    attempts = 0
    max_attempts = max(3, (count // batch_size + 1) * 3)
    
    while len(result) < count and attempts < max_attempts:
        current_batch = min(batch_size, count - len(result))
        attempts += 1
        prompt = f"""
You are a Sri Lankan A/L ICT MCQ paper setter.

Generate {current_batch} NEW MCQs for ONLY the following topic:
Topic: {topic}

Grade: {grade}
Paper Type: {paper_type}
Term: {term if term else "Final/Full syllabus"}
Difficulty: {difficulty}

Rules:
- Every question MUST be about the topic "{topic}" — no other topics.
- 5 options A, B, C, D, E. Only ONE correct answer.
- Do NOT copy any question verbatim from past papers or question banks.
- Create NEW questions strictly based on the provided context.
- Output ONLY valid JSON.
- IMPORTANT JSON RULES:
  1. ALL keys and string values MUST be enclosed in double quotes (").
  2. Do NOT use unescaped double quotes inside strings. If you must use a quote inside a question or explanation, use a single quote (').
  3. Do NOT include literal newlines in strings. Use the exact characters \\n if you need a newline.

JSON format:
{{
  "questions": [
    {{
      "question": "...",
      "options": {{"A":"...","B":"...","C":"...","D":"...","E":"..."}},
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
        try:
            raw = await _gemini_generate(prompt)
            data = _extract_json(raw)
            for q_obj in data.get("questions", []):
                qt = (q_obj.get("question") or "").strip()
                if not qt or qt.lower() in bank_texts:
                    continue
                if q_obj.get("correct_answer") in ["A", "B", "C", "D", "E"]:
                    q_obj["topic"] = topic  # enforce correct topic label
                    result.append(q_obj)
                    if len(result) >= count:
                        break
        except Exception as e:
            logger.exception("Gemini topic generation failed for '%s'. Error=%s", topic, str(e))
            
    if len(result) < count:
        logger.warning("Failed to generate sufficient questions for topic '%s'. Missing: %d", topic, count - len(result))

    return result[:count]


async def generate_mcqs(
    grade: str,
    paper_type: str,
    term: Optional[str],
    difficulty: str,
    mcq_count: int,
    topic: Optional[str] = None,
) -> List[dict]:
    import re

    db_query, target_topics, target_pdfs = _get_query_and_topics(grade, paper_type, term, topic)
    default_topic = target_topics[0] if target_topics else "General"

    # 1. Retrieve context (shared across all parallel tasks)
    context = await _retrieve_context(db_query, target_pdfs, target_topics)
    bank_texts = await _bank_question_texts(db_query)
    batch_size = 8

    # 2. Compute how many questions each topic should contribute
    topic_distribution = _compute_topic_distribution(target_topics, mcq_count)
    logger.info("Weighted parallel distribution: %s", topic_distribution)

    # 3. Helper function to process each topic concurrently
    # We use a semaphore to manage API concurrency. Increasing to 15 allows 
    # most full-syllabus papers to process all units simultaneously.
    sem = asyncio.Semaphore(15)

    async def _process_topic_parallel(topic_name: str, topic_count: int) -> List[dict]:
        if topic_count == 0:
            return []

        async with sem:
            topic_query = {
                **db_query,
                "topic": {"$regex": re.escape(topic_name), "$options": "i"},
            }

            base_gen = max(1, int(topic_count * 0.4))
            base_bank = topic_count - base_gen
            available_in_bank = await _count_bank_questions(topic_query)

            if available_in_bank == 0:
                gen_count = topic_count
                bank_count = 0
                gemini_extra = 0
            elif available_in_bank < base_bank:
                bank_count = available_in_bank
                gemini_extra = base_bank - available_in_bank
                gen_count = base_gen
            else:
                gen_count = base_gen
                bank_count = base_bank
                gemini_extra = 0

            topic_questions: List[dict] = []

            # Step 1 — Fresh Gemini questions
            gemini_qs = await _gemini_generate_for_topic(
                topic_name, gen_count, grade, paper_type, term,
                difficulty, context, bank_texts, batch_size,
            )
            topic_questions.extend(gemini_qs)

            # Step 2a — Paraphrase unique bank questions
            if bank_count > 0:
                bank_qs = await _safe_sample_bank(topic_query, bank_count, topic_name)
                paraphrased = await _paraphrase_questions(bank_qs, grade, difficulty, batch_size)
                topic_questions.extend(paraphrased)

            # Step 2b — Fill bank shortfall with extra Gemini (Tier 2 / Tier 3)
            if gemini_extra > 0:
                extra_qs = await _gemini_generate_for_topic(
                    topic_name, gemini_extra, grade, paper_type, term,
                    difficulty, context, bank_texts, batch_size,
                )
                topic_questions.extend(extra_qs)

            # Topic-level failsafe
            topic_shortfall = topic_count - len(topic_questions)
            if topic_shortfall > 0:
                topic_failsafe_qs = await _gemini_generate_for_topic(
                    topic_name, topic_shortfall, grade, paper_type, term,
                    difficulty, context, bank_texts, batch_size,
                )
                topic_questions.extend(topic_failsafe_qs)

            return topic_questions[:topic_count]

    # Spawn all topic generation tasks in parallel
    tasks = [
        _process_topic_parallel(name, count) 
        for name, count in topic_distribution.items()
    ]
    
    topic_results = await asyncio.gather(*tasks)
    
    all_questions = []
    for qr in topic_results:
        all_questions.extend(qr)

    # 4. Final Failsafe
    final_missing = mcq_count - len(all_questions)
    if final_missing > 0:
        logger.warning("Still short by %d Qs after parallel gen. Final failsafe.", final_missing)
        async with sem:
            failsafe_qs = await _gemini_generate_for_topic(
                default_topic, final_missing, grade, paper_type, term,
                difficulty, context, bank_texts, batch_size,
            )
            all_questions.extend(failsafe_qs)

    random.shuffle(all_questions)
    return all_questions[:mcq_count]


async def analyze_performance(results: List[dict]) -> dict:
    """
    Analyze the user's performance and provide feedback using Gemini.
    results: list of { "question": str, "topic": str, "is_correct": bool }
    """
    # Group results by topic
    topic_stats = {}
    total_correct = 0
    total_questions = len(results)

    for r in results:
        topic = r.get("topic", "General")
        if topic not in topic_stats:
            topic_stats[topic] = {"correct": 0, "total": 0}
        topic_stats[topic]["total"] += 1
        if r["is_correct"]:
            topic_stats[topic]["correct"] += 1
            total_correct += 1

    prompt = f"""
You are an expert A/L ICT teacher. Analyze the following student performance data and provide constructive feedback.

Performance Data:
{json.dumps(topic_stats, indent=2)}

Rules:
1. Identify "strong_areas": topics where the student got most questions correctly (e.g., > 70%).
2. Identify "improvement_areas": topics where the student lost major marks (e.g., < 60%).
3. provide "suggestions": 3-4 specific, actionable bullet points on how to improve.
4. Output ONLY valid JSON in the following format:
{{
  "strong_areas": ["Topic 1", "Topic 2"],
  "improvement_areas": ["Topic 3", "Topic 4"],
  "suggestions": ["suggestion 1", "suggestion 2", "suggestion 3"]
}}
"""
    try:
        raw = await _gemini_generate(prompt)
        analysis = _extract_json(raw)
    except Exception as e:
        logger.error(f"Failed to analyze performance with Gemini: {e}")
        # Build a very basic fallback analysis
        strong = [t for t, s in topic_stats.items() if s["total"] > 0 and s["correct"]/s["total"] >= 0.7]
        improve = [t for t, s in topic_stats.items() if s["total"] > 0 and s["correct"]/s["total"] < 0.7]
        analysis = {
            "strong_areas": strong[:3],
            "improvement_areas": improve[:3],
            "suggestions": [f"Review {t} concepts" for t in improve[:2]] or ["Review all chapters carefully"]
        }

    return {
        "score": total_correct,
        "total": total_questions,
        "percentage": round((total_correct / total_questions) * 100, 1) if total_questions > 0 else 0,
        **analysis
    }


