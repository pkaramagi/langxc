from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List
import secrets


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    # App
    APP_NAME: str = "Translation Learning API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    # PocketBase Configuration
    POCKETBASE_URL: str = "http://localhost:8090"
    POCKETBASE_EMAIL: str = "admin@example.com"  # Set in PocketBase admin
    POCKETBASE_PASSWORD: str = "your-admin-password"

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:61311",
        "http://localhost",
    ]

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60


settings = Settings()
