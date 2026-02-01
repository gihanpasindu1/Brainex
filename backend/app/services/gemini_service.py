import os
from google import genai


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
