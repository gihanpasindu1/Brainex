from fastapi import FastAPI
from .routes.chatbot import router as chatbot_router
from dotenv import load_dotenv
from app.routes.modelpapers import router as papers_router
load_dotenv()


app = FastAPI()

@app.get("/")
def root():
    return {"message": "Backend is running"}


app.include_router(chatbot_router)
app.include_router(papers_router)