from fastapi import FastAPI
from .routes.chatbot import router as chatbot_router

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Backend is running"}


app.include_router(chatbot_router)