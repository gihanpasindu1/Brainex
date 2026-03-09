from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGO_URI: str 
    DB_NAME: str = "brainex"
    GEMINI_API_KEY: str 
    GEMINI_MODEL: str = "gemini-3.1-pro-preview"
    openrouter_api_key: str | None = None
    github_token: str | None = None

    class Config:
        env_file = ".env"

settings = Settings()
