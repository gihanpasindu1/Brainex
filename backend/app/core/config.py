from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGO_URI: str 
    DB_NAME: str = "brainex"
    GEMINI_API_KEY: str = "AIzaSyAQ2NsnsRE8w7mW3m6XzOfPph3Tp4pcQc0"
    GEMINI_MODEL: str = "gemini-3.1-pro-preview"
    openrouter_api_key: str | None = None
    github_token: str | None = None

    class Config:
        env_file = ".env"

settings = Settings()
