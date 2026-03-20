import asyncio
from app.schemas.user_profile import UserOnboardingRequest
from app.services.user_profile_service import complete_user_onboarding
from app.db.mongo import users_col

async def test():
    req = UserOnboardingRequest(
        name="Test",
        grade="A/L",
        exam_year="2026",
        school="",
        district="",
        plan="Free",
        hear_about_us="YouTube"
    )
    res = await complete_user_onboarding("test_user_id", req)
    print("Success:", res)

if __name__ == "__main__":
    asyncio.run(test())
