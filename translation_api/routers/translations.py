from typing import Any, List
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status

from core.pocketbase_client import pocketbase
from routers.auth import get_current_user
from schemas.translation import TranslationCreate, TranslationResponse, TranslationStats, TranslationRequest
import httpx
from core.config import settings

router = APIRouter(prefix="/translations", tags=["translations"])


@router.post("/", response_model=TranslationResponse)
async def create_translation(
    translation: TranslationCreate,
    current_user: dict = Depends(get_current_user)
) -> Any:
    """Create a new translation."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            result = await pocketbase.create_translation(
                user_id=current_user["id"],
                source_text=translation.source_text,
                translated_text=translation.translated_text,
                source_lang=translation.source_lang,
                target_lang=translation.target_lang,
                token=current_user.get("token", "")
            )
            
            # Also create/update vocabulary
            await pocketbase.create_or_update_vocabulary(
                user_id=current_user["id"],
                word=translation.source_text,
                translation=translation.translated_text,
                source_lang=translation.source_lang,
                target_lang=translation.target_lang,
                token=current_user.get("token", "")
            )
            
            return TranslationResponse(**result)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create translation: {str(e)}"
        )



@router.post("/proxy")
async def proxy_translation(
    request: TranslationRequest,
    current_user: dict = Depends(get_current_user)
) -> Any:
    """Proxy translation request to Papago API."""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://openapi.naver.com/v1/papago/n2mt",
                headers={
                    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                    "X-Naver-Client-Id": settings.PAPAGO_CLIENT_ID,
                    "X-Naver-Client-Secret": settings.PAPAGO_CLIENT_SECRET,
                },
                data={
                    "source": request.source_lang,
                    "target": request.target_lang,
                    "text": request.text
                }
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Papago API error: {response.text}"
                )
                
            data = response.json()
            return {
                "translatedText": data["message"]["result"]["translatedText"]
            }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Translation proxy failed: {str(e)}"
        )


@router.get("/", response_model=List[TranslationResponse])
async def get_translations(
    current_user: dict = Depends(get_current_user),
    page: int = 1,
    per_page: int = 50
) -> Any:
    """Get user's translations."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            result = await pocketbase.get_user_translations(
                current_user["id"], 
                current_user.get("token", ""),
                page, 
                per_page
            )
            return [TranslationResponse(**item) for item in result["items"]]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get translations: {str(e)}"
        )


@router.delete("/{translation_id}")
async def delete_translation(
    translation_id: str,
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Delete a translation."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            success = await pocketbase.delete_translation(
                translation_id, 
                current_user.get("token", "")
            )
            if not success:
                raise HTTPException(status_code=404, detail="Translation not found")
            return {"message": "Translation deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to delete translation: {str(e)}"
        )


@router.get("/daily-summary")
async def get_daily_summary(current_user: dict = Depends(get_current_user)) -> dict:
    """Get daily translation summary with vocabulary stats (last 24 hours)."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()

            # Get translations from today
            translations = await pocketbase.get_user_translations(
                current_user["id"],
                current_user.get("token", ""),
                page=1,
                per_page=1000
            )

            # Get vocabulary
            vocabulary = await pocketbase.get_user_vocabulary(
                current_user["id"],
                current_user.get("token", ""),
                page=1,
                per_page=1000
            )

            # Filter for last 24 hours
            now = datetime.now()
            yesterday = now - timedelta(hours=24)

            recent_translations = [
                t for t in translations["items"]
                if datetime.fromisoformat(t["created"][:-1]) > yesterday
            ]

            recent_vocabulary = [
                v for v in vocabulary["items"]
                if datetime.fromisoformat(v["last_reviewed"][:-1]) > yesterday
            ]

            # Calculate stats
            total_translations = len(recent_translations)
            unique_words = len(recent_vocabulary)
            most_frequent = sorted(
                recent_vocabulary,
                key=lambda x: x["count"],
                reverse=True
            )[:10]

            return {
                "total_translations": total_translations,
                "unique_words": unique_words,
                "most_frequent_words": [
                    {
                        "word": item["word"],
                        "count": item["count"],
                        "translation": item["translation"]
                    }
                    for item in most_frequent
                ]
            }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get daily summary: {str(e)}"
        )


@router.get("/two-day-summary")
async def get_two_day_summary(current_user: dict = Depends(get_current_user)) -> dict:
    """Get 2-day translation summary with vocabulary stats (last 48 hours)."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()

            # Get translations from last 2 days
            translations = await pocketbase.get_user_translations(
                current_user["id"],
                current_user.get("token", ""),
                page=1,
                per_page=1000
            )

            # Get vocabulary
            vocabulary = await pocketbase.get_user_vocabulary(
                current_user["id"],
                current_user.get("token", ""),
                page=1,
                per_page=1000
            )

            # Filter for last 48 hours
            now = datetime.now()
            two_days_ago = now - timedelta(hours=48)

            recent_translations = [
                t for t in translations["items"]
                if datetime.fromisoformat(t["created"][:-1]) > two_days_ago
            ]

            recent_vocabulary = [
                v for v in vocabulary["items"]
                if datetime.fromisoformat(v["last_reviewed"][:-1]) > two_days_ago
            ]

            # Calculate stats
            total_translations = len(recent_translations)
            unique_words = len(recent_vocabulary)
            most_frequent = sorted(
                recent_vocabulary,
                key=lambda x: x["count"],
                reverse=True
            )[:10]

            return {
                "total_translations": total_translations,
                "unique_words": unique_words,
                "most_frequent_words": [
                    {
                        "word": item["word"],
                        "count": item["count"],
                        "translation": item["translation"]
                    }
                    for item in most_frequent
                ]
            }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get two-day summary: {str(e)}"
        )


@router.get("/weekly-summary")
async def get_weekly_summary(current_user: dict = Depends(get_current_user)) -> dict:
    """Get weekly translation summary with vocabulary stats."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()

            # Get translations from this week
            translations = await pocketbase.get_user_translations(
                current_user["id"],
                current_user.get("token", ""),
                page=1,
                per_page=1000
            )

            # Get vocabulary
            vocabulary = await pocketbase.get_user_vocabulary(
                current_user["id"],
                current_user.get("token", ""),
                page=1,
                per_page=1000
            )

            # Calculate stats
            total_translations = len(translations["items"])
            unique_words = len(vocabulary["items"])
            most_frequent = sorted(
                vocabulary["items"],
                key=lambda x: x["count"],
                reverse=True
            )[:10]

            return {
                "total_translations": total_translations,
                "unique_words": unique_words,
                "most_frequent_words": [
                    {
                        "word": item["word"],
                        "count": item["count"],
                        "translation": item["translation"]
                    }
                    for item in most_frequent
                ]
            }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get weekly summary: {str(e)}"
        )
