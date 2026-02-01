import os
from google import genai

def ask_gemini(question: str) -> str:
    api_key = os.getenv("GEMINI_API_KEY")

    if not api_key:
        return "GEMINI_API_KEY not found. Put it in .env file."

    client = genai.Client(api_key=api_key)

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=question
    )

    # response.text is usually the answer
    return response.text or "Gemini returned empty answer."
