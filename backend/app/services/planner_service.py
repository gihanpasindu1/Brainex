import os
import json
from google import genai
from app.schemas.planner import StudyPlanRequest

def generate_study_plan_ai(data: StudyPlanRequest) -> dict:
    """
    Calls Gemini to generate a structured JSON study plan based on user inputs.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found in environment variables.")

    client = genai.Client(api_key=api_key)

    # Calculate total weeks to help the AI structure the response
    #total_weeks = max(1, data.days_to_exam // 7)

    prompt = f"""
    You are an expert Sri Lankan GCE A/L ICT Teacher and supportive Study Coach.
    Create a highly structured, personalized weekly study plan for a student based on these parameters:
    - Target: {data.grade} {data.exam_type} (Term {data.term_number if data.term_number else 'N/A'})
    - Weak Areas to Prioritize: {", ".join(data.weak_topics) if data.weak_topics else 'None specified'}
    - Time Available: {data.weeks_to_exam} weeks

    The syllabus includes: Information Systems, Logic Gates, Computer Architecture, OS, Networking, Python, Database (MySQL), Web Dev (HTML/CSS/PHP), IoT, etc.

    CRITICAL INSTRUCTION FOR DAILY HOURS:
    Do NOT copy the dummy number (0) from the example below. You MUST dynamically calculate a realistic integer between 1 and 4 for "suggested_hours_per_day" for EACH week. Heavy topics (like Python/MySQL) should get more hours, lighter topics should get fewer.

    Respond ONLY with a valid JSON object matching this exact structure. Do not include markdown code blocks, just the raw JSON:
    {{
      "ai_advice": "A short, encouraging message like a supportive coach, focusing on improving their weak topics.",
      "weeks": [
        {{
          "week_number": 1,
          "focus_area": "Main topic for the week",
          "topics_to_cover": ["Subtopic 1", "Subtopic 2", "Subtopic 3"],
          "suggested_hours_per_day": 0,
          "study_advice": "Specific study strategy or tip for this week's content."
        }}
      ]
    }}
    """

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config={
            "response_mime_type": "application/json"
        }
    )

    try:
        plan_dict = json.loads(response.text)
        return plan_dict
    except json.JSONDecodeError:
        raise Exception("Failed to parse AI response into valid JSON.")