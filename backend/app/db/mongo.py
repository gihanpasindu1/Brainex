from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

client = AsyncIOMotorClient(settings.MONGO_URI, serverSelectionTimeoutMS=3000)
db = client[settings.DB_NAME]

model_papers_col = db["model_papers"]
mcq_bank_col = db["mcq_bank"]
syllabus_chunks_col = db["syllabus_chunks"]
past_papers_col = db["past_papers"]
friend_challenges_col = db["friend_challenges"]
friend_challenge_participants_col = db["friend_challenge_participants"]
friend_challenge_submissions_col = db["friend_challenge_submissions"]
