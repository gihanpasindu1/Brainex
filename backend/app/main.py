import asyncio

from fastapi import FastAPI
from .routes.chat import router as chat_router
from .routes.chatbot import router as chatbot_router
from app.routes.modelpapers import router as modelpapers_router
from app.routes.friend_challenges import router as friend_challenges_router
from app.routes.global_challenges import router as global_challenges_router
from app.routes.users import router as users_router
from app.services.global_challenge_service import (
    preload_weekly_challenge_docs,
    run_global_challenge_maintenance_pass,
)
from .routes.planner import router as planner_router
from .routes.short_notes import router as short_notes_router
from app.routes.pastpapers import router as pastpapers_router
from app.routes.admin import router as admin_router
from dotenv import load_dotenv
load_dotenv()


app = FastAPI()


async def _global_challenge_maintenance_loop() -> None:
    while True:
        try:
            await run_global_challenge_maintenance_pass()
        except Exception:
            pass
        await asyncio.sleep(60)


@app.on_event("startup")
async def startup_global_challenge_maintenance() -> None:
    await preload_weekly_challenge_docs()
    asyncio.create_task(_global_challenge_maintenance_loop())

@app.get("/")
def root():
    return {"message": "Backend is running"}

# Include the new chat router
app.include_router(chat_router)


app.include_router(modelpapers_router)
app.include_router(friend_challenges_router)
app.include_router(global_challenges_router)
app.include_router(users_router)
# Include the old chatbot router (optional, keeping for safety if user wants both, or I could comment it out)
# app.include_router(chatbot_router) 

app.include_router(planner_router)
app.include_router(short_notes_router)
app.include_router(pastpapers_router)
app.include_router(admin_router)
