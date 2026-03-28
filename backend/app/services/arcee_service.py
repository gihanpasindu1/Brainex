from openai import OpenAI
import os
import re
from dotenv import load_dotenv
from typing import Optional, Dict, Any
from app.services.past_paper_service import get_question_by_year_and_number, get_questions_by_unit

load_dotenv()

# ----------------------------------
# CONFIG
# ----------------------------------

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")

client = OpenAI(
    base_url="https://models.inference.ai.azure.com",
    api_key=GITHUB_TOKEN,
)

# ----------------------------------
# HELPERS
# ----------------------------------

def _decimal_to_binary_with_fraction(x: float, frac_bits: int = 16) -> str:
    if x < 0:
        return "-" + _decimal_to_binary_with_fraction(-x, frac_bits)

    int_part = int(x)
    frac_part = x - int_part

    int_bin = bin(int_part)[2:]

    if frac_part == 0:
        return int_bin

    bits = []
    count = 0
    while frac_part > 0 and count < frac_bits:
        frac_part *= 2
        bit = int(frac_part)
        bits.append(str(bit))
        frac_part -= bit
        count += 1

    return int_bin + "." + "".join(bits)


def _solve_number_system(question: str) -> str | None:
    q = (question or "").lower().strip()

    m = re.search(r"(decimal|base\s*10)\s*([0-9]+(?:\.[0-9]+)?)", q)
    wants_binary = ("binary" in q) or ("base 2" in q)

    if wants_binary and m:
        num = float(m.group(2))
        b = _decimal_to_binary_with_fraction(num)
        return f"The binary equivalent of decimal {m.group(2)} is {b}."

    m2 = re.search(r"convert\s*([0-9]+(?:\.[0-9]+)?)\s*to\s*(binary|base\s*2)", q)
    if m2:
        num = float(m2.group(1))
        b = _decimal_to_binary_with_fraction(num)
        return f"The binary equivalent of decimal {m2.group(1)} is {b}."

    return None


def _extract_answer(text: str) -> str:
    if "ANSWER:" in text:
        return text.split("ANSWER:", 1)[1].strip()
    return text.strip()


async def _detect_past_paper_intent(question: str) -> Optional[Dict[str, Any]]:
    """
    Detects if the user is asking for a specific past paper question or unit-wise questions.
    Returns a dict with intent 'specific_question' or 'unit_questions' and relevant data.
    """
    q_lower = question.lower()
    
    # 1. Specific question: "2018 24th MCQ", "2011 Q5", "Explain 2015 10mcq"
    # Regex for year (4 digits) and question number (1-2 digits), with optional space before suffix
    # Pattern A: year first, then number: "2023 A/L 10th question"
    specific_match = re.search(r"(?P<year>20\d{2})\s+.*?(?P<num>\d{1,2})\s*(?:st|nd|rd|th)?\s*(?:mcq|q|question)", q_lower)
    if not specific_match:
        # Pattern B: "MCQ 24 in 2018"
        specific_match = re.search(r"(?:mcq|q|question)\s*(?P<num>\d{1,2}).*?(?P<year>20\d{2})", q_lower)
    if not specific_match:
        # Pattern C: number first, then year: "10 th question on 2023 A/L exam"
        specific_match = re.search(r"(?P<num>\d{1,2})\s*(?:st|nd|rd|th)?\s*(?:mcq|q|question).*?(?P<year>20\d{2})", q_lower)
    
    if specific_match:
        year = specific_match.group("year")
        num = specific_match.group("num")
        question_data = await get_question_by_year_and_number(year, num)
        if question_data:
            return {
                "intent": "specific_question",
                "year": year,
                "question_number": num,
                "data": question_data,
                "found_in_db": True
            }
        else:
            return {
                "intent": "specific_question",
                "year": year,
                "question_number": num,
                "data": None,
                "found_in_db": False
            }

    # 2. Unit-wise questions: "Unit 10 questions", "Explain questions from unit 9"
    unit_match = re.search(r"unit\s*(?P<unit_num>\d{1,2})\s*questions?", q_lower)
    if unit_match:
        unit_num = unit_match.group("unit_num")
        questions = await get_questions_by_unit(f"Unit {unit_num}")
        if questions:
            return {
                "intent": "unit_questions",
                "unit": unit_num,
                "data": questions,
                "found_in_db": True
            }
        else:
            return {
                "intent": "unit_questions",
                "unit": unit_num,
                "data": None,
                "found_in_db": False
            }
            
    return None


# ----------------------------------
# SUBJECT DEFINITIONS
# ----------------------------------

SUBJECT_MAP = {
    "Embedded Systems": "01_Embedded_Systems.pdf",
    "IoT": "02_IoT.pdf",
    "Algorithms & Theory": "03_Algorithms_and_Theory.pdf",
    "Python Basics": "04_Python_Basics.pdf",
    "Python Control Structures": "05_Python_Control_Structures.pdf",
    "Python Functions": "06_Python_Functions.pdf",
    "Python Data Structures": "07_Python_Data_Structures.pdf",
    "Python File Handling": "08_Python_File_Handling.pdf",
    "Python Database": "09_Python_Database_MySQL.pdf",
    "HTML": "10_HTML.pdf",
    "CSS": "11_CSS.pdf",
    "PHP & Dynamic Web": "12_PHP_and_Dynamic_Web.pdf",
    "E-Commerce": "13_E_Commerce.pdf",
    "Future Trends": "14_Future_Trends_ICT.pdf",
}

def classify_subject(question: str) -> list[str]:
    """
    Uses a lightweight LLM call to decide which subjects are relevant.
    Returns a list of filenames (values from SUBJECT_MAP).
    """
    # 1. FAST PATH: Check for greetings or very short queries to skip LLM
    # This avoids the "double LLM" latency for simple "Hi" messages.
    greetings = ["hi", "hello", "hey", "good morning", "good afternoon", "good evening", "how are you"]
    q_lower = question.strip().lower()
    
    # If it's a known greeting or very short (likely not a complex subject question)
    if q_lower in greetings or (len(q_lower) < 10 and "python" not in q_lower and "sql" not in q_lower):
        print("Fast path: Detected greeting/short query. Skipping classification.")
        return []

    subject_list_str = "\n".join([f"- {k}" for k in SUBJECT_MAP.keys()])
    
    system_prompt = f"""
You are an expert librarian for an ICT course.
Available subjects:
{subject_list_str}

Given a user question, return the names of the RELEVANT subjects from the list above.
- If the question specifically asks for Python code, include relevant Python subjects.
- If it's about web dev, include HTML, CSS, PHP, etc.
- If it's general or unclear, you can select multiple.
- If NONE seem relevant or it's a general greeting, return "General".

Output format:
Just the subject names, separated by commas.
Example: Python Basics, Python Functions
""".strip()

    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini", # Fast model for classification
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Question: {question}"},
            ],
            temperature=0.1,
            stream=True
        )

        full_content = ""
        for chunk in completion:
            if chunk.choices and chunk.choices[0].delta.content:
                full_content += chunk.choices[0].delta.content

        content = full_content.strip()
        
        # Parse the output
        relevant_files = []
        for k, filename in SUBJECT_MAP.items():
            if k.lower() in content.lower():
                relevant_files.append(filename)
                
        # Fallback: if "Python" is mentioned but no specific python topic, add Basics
        if "python" in question.lower() and not any("Python" in k for k in SUBJECT_MAP.keys() if k in content):
             relevant_files.append(SUBJECT_MAP["Python Basics"])

        # Deduplicate and return
        return list(set(relevant_files))

    except Exception as e:
        print(f"Classification error: {e}")
        return [] # Return empty list on error (system will use no PDF or all PDFs depending on policy)

# ----------------------------------
# MAIN FUNCTION
# ----------------------------------

async def ask_ai(question: str, pdf_text: str | None = None, history: list[dict] | None = None) -> dict:
    """
    A/L ICT Tutor Bot with Past Paper awareness.
    """

    # ✅ Exact solver for number system questions
    solved = _solve_number_system(question)
    if solved:
        return {"answer": solved, "evidence": [], "used_pdf": False}

    # ✅ Past Paper Intent Detection
    past_paper_info = await _detect_past_paper_intent(question)
    
    past_paper_context = ""
    if past_paper_info:
        if past_paper_info["intent"] == "specific_question":
            if past_paper_info["found_in_db"]:
                q_data = past_paper_info["data"]
                # Formatting options broadly to handle different structures
                options_text = ""
                options_dict = q_data.get('options', {})
                if isinstance(options_dict, dict):
                    for k, v in options_dict.items():
                        if isinstance(v, dict):
                            options_text += f"{k}: {v.get('text', '')}\n"
                        else:
                            options_text += f"{k}: {v}\n"
                
                correct_ans = q_data.get('answer') or q_data.get('correct_answer')
                db_exp = q_data.get('explanation') or "No explanation provided in DB."

                past_paper_context = f"""
--- SOURCE: Past Paper {past_paper_info['year']} MCQ {past_paper_info['question_number']} ---
Question: {q_data.get('question')}
Options:
{options_text.strip()}
Correct Answer: {correct_ans}
DB Explanation: {db_exp}

INSTRUCTION: The student is asking you to EXPLAIN this past paper question. You MUST:
1. First, clearly state the question and all the options.
2. Then explain WHY the correct answer is correct, using ICT concepts from the A/L syllabus.
3. Briefly explain why the other options are wrong (if applicable).
4. Provide a clear, detailed, educational explanation. Do NOT just state the answer number.
"""
                print(f"[DEBUG] Found specific past paper question: {past_paper_info['year']} {past_paper_info['question_number']}")
            else:
                past_paper_context = f"""
--- MISSING PAST PAPER QUERY ---
The student is asking about GCE A/L {past_paper_info['year']} MCQ {past_paper_info['question_number']}, but this specific question was NOT found in the database.
You must inform the student that you don't have this specific question in your records right now, and politely ask them to type or upload the question itself so you can help. Do NOT say 'Not in the GCE A/L ICT syllabus'.
"""
                print(f"[DEBUG] Missing specific past paper question: {past_paper_info['year']} {past_paper_info['question_number']}")
            
        elif past_paper_info["intent"] == "unit_questions":
            if past_paper_info["found_in_db"]:
                questions = past_paper_info["data"]
                # User wants exact list, no explanation
                q_list = []
                for i, q in enumerate(questions[:40]): # Limit to first 40 to avoid token blowout
                    q_list.append(f"{i+1}. [{q.get('year')} Q{q.get('question_number')}] {q.get('question')}")
                
                past_paper_context = f"\n--- SOURCE: Unit {past_paper_info['unit']} Questions ---\n" + "\n".join(q_list)
                print(f"[DEBUG] Found {len(questions)} questions for Unit {past_paper_info['unit']}")
            else:
                past_paper_context = f"""
--- MISSING PAST PAPER QUERY ---
The student asked for questions from Unit {past_paper_info['unit']}, but none were found in the database. 
You must inform the student that you don't have questions for this unit in your records right now. Do NOT say 'Not in the GCE A/L ICT syllabus'.
"""
                print(f"[DEBUG] Missing questions for Unit {past_paper_info['unit']}")

    system_prompt = """
You are a Sri Lankan GCE A/L ICT tutor.

BOUNDARY RULE (MOST IMPORTANT):
1. GREETINGS & GENERAL CHAT:
   - If the user sends a greeting (e.g., "Hi", "Hello", "Good morning") or general small talk, reply politely as a helpful tutor.
   - Do NOT apply the syllabus restriction to these interactions.

2. TECHNICAL/SUBJECT QUESTIONS:
   - If the question is about a specific topic, concept, or technical matter:
     - DECIDE: Is this within the GCE A/L ICT syllabus?
     - YES: Answer clearly using ICT concepts.
     - NO: Reply EXACTLY:
       Not in the GCE A/L ICT syllabus.

3. PAST PAPERS & UNITS:
   - If Past Paper context is provided with a specific question:
     - You MUST provide a DETAILED EXPLANATION. Do NOT just say the answer number.
     - First show the question and options clearly.
     - Then explain WHY the correct answer is correct using A/L ICT concepts.
     - Briefly explain why other key options are wrong.
     - Follow the INSTRUCTION block inside the Past Paper context.
   - For unit-based question requests: Provide the list of questions exactly as found in the source. Do not explain them unless asked.
   - If the Past Paper Context says MISSING PAST PAPER QUERY, you MUST follow its instructions exactly (ask the user to provide the question) and DO NOT say 'Not in the GCE A/L ICT syllabus'.


DEPTH LIMIT RULE (CRITICAL):
- Answer ONLY to the depth expected in the GCE A/L ICT syllabus.
- If a question asks about internal electronics, memory cells,
  transistors, voltages, charge storage, algorithms, or low-level
  implementation details, it is OUTSIDE the syllabus.

IMPORTANT:
- Scenario / use-case questions ARE allowed.
- The exact wording does NOT need to appear in the textbook.
- Stay strictly within ICT.

PDF/SOURCE RULE:
- PDF/Past Paper text is OPTIONAL but preferred if provided.
- If context is irrelevant or empty, still answer if within syllabus.

FORMAT (MUST FOLLOW EXACTLY):

ANSWER: <your answer OR 'Not in the GCE A/L ICT syllabus.'>
""".strip()

    user_content = f"""
QUESTION:
{question}

PAST PAPER CONTEXT (optional):
{past_paper_context}

PDF TEXT (optional):
{pdf_text or ""}
""".strip()

    # Build messages for the chat API, including optional conversation history.
    messages = [{"role": "system", "content": system_prompt}]

    if history:
        for h in history:
            h_role = h.get("role")
            content = h.get("content", "") or h.get("text", "") # Handle both
            if h_role == "user":
                messages.append({"role": "user", "content": content})
            else:
                messages.append({"role": "assistant", "content": content})

    messages.append({"role": "user", "content": user_content})

    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
        temperature=0.2,
        stream=True
    )

    full_content = ""
    for chunk in completion:
        if chunk.choices and chunk.choices[0].delta.content:
            full_content += chunk.choices[0].delta.content

    content = full_content.strip()
    answer = _extract_answer(content)

    if answer.strip() == "Not in the GCE A/L ICT syllabus.":
        return {
            "answer": answer,
            "evidence": [],
            "used_pdf": False
        }

    return {
        "answer": answer,
        "evidence": [],
        "used_pdf": bool(pdf_text or past_paper_context)
    }
