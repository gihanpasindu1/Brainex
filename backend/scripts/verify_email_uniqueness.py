import asyncio
import os
from dotenv import load_dotenv
# Load environment variables FIRST
load_dotenv("backend/.env")

from app.schemas.user_profile import UserOnboardingRequest
from app.services.user_profile_service import complete_user_onboarding, ensure_user_profile
from app.db.mongo import users_col
import uuid

async def test_unique_email():
    email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    print(f"Testing with email: {email}")

    # Create first user
    user1_id = f"user1_{uuid.uuid4().hex[:8]}"
    req1 = UserOnboardingRequest(
        name="User One",
        email=email,
        grade="A/L",
        exam_year="2026",
        plan="Free",
        hear_about_us="Google"
    )
    
    print(f"Creating first user: {user1_id}")
    await complete_user_onboarding(user1_id, req1)
    
    # Try to create second user with SAME email
    user2_id = f"user2_{uuid.uuid4().hex[:8]}"
    req2 = UserOnboardingRequest(
        name="User Two",
        email=email, # Same email
        grade="A/L",
        exam_year="2027",
        plan="Premium",
        hear_about_us="Friend"
    )

    print(f"Attempting to create second user with same email: {user2_id}")
    try:
        await complete_user_onboarding(user2_id, req2)
        print("FAILURE: Second user was created with a duplicate email!")
    except Exception as e:
        print(f"SUCCESS: Second user creation failed as expected: {e}")

    # Cleanup (optional, but good for tidiness)
    # await users_col.delete_many({"email": email})

if __name__ == "__main__":
    asyncio.run(test_unique_email())
