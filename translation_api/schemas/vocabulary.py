from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List


class VocabularyBase(BaseModel):
    word: str
    translation: str | None = None
    source_lang: str
    target_lang: str


class VocabularyCreate(VocabularyBase):
    pass


class VocabularyResponse(VocabularyBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    user_id: int
    count: int
    is_mastered: bool
    first_seen: datetime
    last_reviewed: datetime


class VocabularyUpdate(BaseModel):
    translation: str | None = None
    is_mastered: bool | None = None


class WordFrequency(BaseModel):
    word: str
    count: int
    translations: List[str]
    example_sentences: List[str]


class WeeklySummary(BaseModel):
    week_start: datetime
    week_end: datetime
    total_translations: int
    unique_words: int
    most_frequent_words: List[WordFrequency]

