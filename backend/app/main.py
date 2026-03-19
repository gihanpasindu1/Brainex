from fastapi import FastAPI
from .routes.chat import router as chat_router
from .routes.chatbot import router as chatbot_router
from app.routes.modelpapers import router as modelpapers_router
from app.routes.friend_challenges import router as friend_challenges_router
from .routes.planner import router as planner_router
from .routes.short_notes import router as short_notes_router
from app.routes.pastpapers import router as pastpapers_router
from dotenv import load_dotenv
load_dotenv()


app = FastAPI()

@app.get("/")
def root():
    return {"message": "Backend is running"}

# Include the new chat router
app.include_router(chat_router)


app.include_router(modelpapers_router)
app.include_router(friend_challenges_router)
# Include the old chatbot router (optional, keeping for safety if user wants both, or I could comment it out)
# app.include_router(chatbot_router) 

app.include_router(planner_router)
app.include_router(short_notes_router)
app.include_router(pastpapers_router)
