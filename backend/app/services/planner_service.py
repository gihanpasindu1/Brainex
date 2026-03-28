import os
import json
from google import genai
from app.schemas.planner import StudyPlanRequest

from app.services.rag_service import _get_query_and_topics

def generate_study_plan_ai(data: StudyPlanRequest) -> dict:
    """
    Calls Gemini to generate a structured JSON study plan based on user inputs.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found in environment variables.")

    client = genai.Client(api_key=api_key)

    # 2. Format inputs to match what rag_service expects
    rag_grade = data.grade.replace("Grade ", "")  # Converts "Grade 12" to "12"
    rag_paper_type = "Final" if data.exam_type == "Final Exam" else "Term"
    rag_term = f"Term {data.term_number}" if data.term_number else None

    # 3. Fetch the exact syllabus units for this specific term/grade
    _, target_topics, _ = _get_query_and_topics(
        grade=rag_grade,
        paper_type=rag_paper_type,
        term=rag_term,
        specific_topic=None
    )
    
    # Create a string of the allowed topics
    official_syllabus = ", ".join(target_topics) if target_topics else "Full GCE A/L ICT Syllabus"

    # Calculate total weeks to help the AI structure the response
    #total_weeks = max(1, data.days_to_exam // 7)

    prompt = f"""
    You are an expert Sri Lankan GCE A/L ICT Teacher and supportive Study Coach.
    Create a highly structured, personalized weekly study plan for a student based on these parameters:
    - Target: Grade {rag_grade} {data.exam_type} ({rag_term if rag_term else 'N/A'})
    - Topics to Focus On: {", ".join(data.weak_topics) if data.weak_topics else 'None specified'}
    - Time Available: {data.weeks_to_exam} weeks

    OFFICIAL SYLLABUS BOUNDARIES:
    The official syllabus units available for this specific target are:
    [{official_syllabus}]

    IMPORTANT PLANNING RULE:
    - If "Topics to Focus On" is specified (not 'None specified'), you MUST restrict the entire study plan ONLY to those topics. Do NOT include other units.
    - If "Topics to Focus On" is "None specified", utilize the OFFICIAL SYLLABUS BOUNDARIES provided above.
    - Do NOT invent topics outside of the official Sri Lankan GCE A/L ICT syllabus.

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
          "study_advice": "Specific study strategy or tip for this week's content.",
          "days": [
            {{
              "day_number": 1,
              "topic": "Logic Gates",
              "learning_step": "Read AND, OR, NOT gate definitions",
              "understanding_step": "Look at 3 truth table examples",
              "practice_step": "Answer 15 MCQs on Logic Gates",
              "review_step": "Check wrong answers and read explanations",
              "revision_step": "Revise yesterday's Boolean Algebra notes for 15 minutes",
              "checkpoint": "Did you finish all tasks? Confidence level: Good, Average, Weak"
            }}
          ]
        }}
      ]
    }}
    CRITICAL: YOU MUST generate exactly 7 elements in the "days" array for each week (day_number 1 through 7). Each day MUST have all 7 steps defined.
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