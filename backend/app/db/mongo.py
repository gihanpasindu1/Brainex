from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings
import certifi

client = AsyncIOMotorClient(settings.MONGO_URI, serverSelectionTimeoutMS=5000, tlsCAFile=certifi.where())
db = client[settings.DB_NAME]

model_papers_col = db["model_papers"]
mcq_bank_col = db["mcq_bank"]
syllabus_chunks_col = db["syllabus_chunks"]
past_papers_col = db["papers"]
friend_challenges_col = db["friend_challenges"]
friend_challenge_participants_col = db["friend_challenge_participants"]
friend_challenge_submissions_col = db["friend_challenge_submissions"]
global_challenges_col = db["global_challenges"]
global_challenge_participants_col = db["global_challenge_participants"]
global_challenge_progress_col = db["global_challenge_progress"]
global_challenge_submissions_col = db["global_challenge_submissions"]
model_paper_submissions_col = db["model_paper_submissions"]
plans_col = db["study_plans"]
short_notes_col = db["short_notes"]
predefined_notes_col = db["predefined_notes"]
users_col = db["users"]
