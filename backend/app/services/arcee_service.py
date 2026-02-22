from openai import OpenAI
import os
import re
from dotenv import load_dotenv

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

def ask_ai(question: str, pdf_text: str | None = None, history: list[dict] | None = None) -> dict:
    """
    A/L ICT Tutor Bot

    - AI decides syllabus boundaries
    - Answers use-case questions
    - PDF is OPTIONAL
    - If NOT in syllabus → NO evidence
    """

    # ✅ Exact solver for number system questions
    solved = _solve_number_system(question)
    if solved:
        return {"answer": solved, "evidence": [], "used_pdf": False}

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

DEPTH LIMIT RULE (CRITICAL):
- Answer ONLY to the depth expected in the GCE A/L ICT syllabus.
- If a question asks about internal electronics, memory cells,
  transistors, voltages, charge storage, algorithms, or low-level
  implementation details, it is OUTSIDE the syllabus.

IMPORTANT:
- Scenario / use-case questions ARE allowed.
- The exact wording does NOT need to appear in the textbook.
- Stay strictly within ICT.

PDF RULE:
- PDF text is OPTIONAL.
- Evidence is NOT REQUIRED.
- If PDF is irrelevant or empty, still answer if within syllabus.

FORMAT (MUST FOLLOW EXACTLY):

ANSWER: <your answer OR 'Not in the GCE A/L ICT syllabus.'>
""".strip()

    user_content = f"""
QUESTION:
{question}

PDF TEXT (optional):
{pdf_text or ""}
""".strip()

    # Build messages for the chat API, including optional conversation history.
    messages = [{"role": "system", "content": system_prompt}]

    if history:
        # history items are dicts: {"role": "user"|"assistant", "text": "..."}
        for h in history:
            h_role = h.get("role")
            if h_role == "user":
                messages.append({"role": "user", "content": h.get("text", "")})
            else:
                # assistant stored messages should be sent as assistant role
                messages.append({"role": "assistant", "content": h.get("text", "")})

    # Append current user message last
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

    # ❗ If NOT in syllabus → return NO evidence
    if answer.strip() == "Not in the GCE A/L ICT syllabus.":
        return {
            "answer": answer,
            "evidence": [],
            "used_pdf": False
        }

    return {
        "answer": answer,
        "evidence": [],   # evidence intentionally empty
        "used_pdf": bool(pdf_text)
    }
