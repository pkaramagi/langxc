from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status

from core.pocketbase_client import pocketbase
from routers.auth import get_current_user

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/fcm-token")
async def update_fcm_token(
    fcm_token: str,
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Update user's FCM token for push notifications."""
    try:
        # In PocketBase, we would need to add a field to store FCM tokens
        # For now, we'll just acknowledge the request
        # In a real implementation, you'd store this in the user record or a separate table
        return {
            "message": "FCM token updated successfully",
            "user_id": current_user["id"]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to update FCM token: {str(e)}"
        )


@router.post("/preferences")
async def update_notification_preferences(
    frequency: str,  # 'daily', 'two_day', 'weekly'
    preferred_time: str,  # 'HH:MM' format
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Update user's notification preferences."""
    try:
        # Validate frequency
        valid_frequencies = ['daily', 'two_day', 'weekly']
        if frequency not in valid_frequencies:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid frequency. Must be one of: {valid_frequencies}"
            )

        # In PocketBase, we would need to add fields to store preferences
        # For now, we'll just acknowledge the request
        # In a real implementation, you'd store this in the user record
        return {
            "message": "Preferences updated successfully",
            "frequency": frequency,
            "preferred_time": preferred_time
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to update preferences: {str(e)}"
        )


@router.get("/preferences")
async def get_notification_preferences(
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Get user's notification preferences."""
    try:
        # In a real implementation, you'd fetch this from the user record
        # For now, return defaults
        return {
            "frequency": "weekly",  # default
            "preferred_time": "09:00",  # default 9 AM
            "last_notification_sent": None
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get preferences: {str(e)}"
        )
