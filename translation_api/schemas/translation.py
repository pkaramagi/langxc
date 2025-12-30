from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional


class TranslationBase(BaseModel):
    source_text: str
    translated_text: str
    source_lang: str  # 'ko' or 'en'
    target_lang: str  # 'ko' or 'en'


class TranslationCreate(TranslationBase):
    pass


class TranslationRequest(BaseModel):
    text: str
    source_lang: str
    target_lang: str


class TranslationResponse(TranslationBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    user_id: str
    created: str  # PocketBase returns 'created' string, not 'created_at' datetime object directly
    updated: str


class TranslationStats(BaseModel):
    total_translations: int
    this_week: int
    today: int
    korean_to_english: int
    english_to_korean: int
