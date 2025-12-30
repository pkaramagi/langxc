from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status

from core.pocketbase_client import pocketbase
from routers.auth import get_current_user

router = APIRouter(prefix="/vocabulary", tags=["vocabulary"])


@router.get("/", response_model=List[dict])
async def get_vocabulary(
    current_user: dict = Depends(get_current_user),
    page: int = 1,
    per_page: int = 50
) -> Any:
    """Get user's vocabulary list."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            result = await pocketbase.get_user_vocabulary(
                current_user["id"],
                current_user.get("token", ""),
                page,
                per_page
            )
            return result["items"]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get vocabulary: {str(e)}"
        )


@router.get("/{vocabulary_id}")
async def get_vocabulary_item(
    vocabulary_id: str,
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Get a specific vocabulary item."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            # Get vocabulary by filtering for the specific ID
            result = await pocketbase.get_user_vocabulary(
                current_user["id"],
                current_user.get("token", ""),
                page=1,
                per_page=1000
            )

            # Find the specific item
            for item in result["items"]:
                if item["id"] == vocabulary_id:
                    return item

            raise HTTPException(status_code=404, detail="Vocabulary item not found")

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get vocabulary item: {str(e)}"
        )


@router.patch("/{vocabulary_id}")
async def update_vocabulary_item(
    vocabulary_id: str,
    is_mastered: bool,
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Update vocabulary mastery status."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            result = await pocketbase.update_vocabulary_mastered(
                vocabulary_id,
                is_mastered,
                current_user.get("token", "")
            )
            return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to update vocabulary: {str(e)}"
        )


@router.delete("/{vocabulary_id}")
async def delete_vocabulary_item(
    vocabulary_id: str,
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Delete a vocabulary item."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            success = await pocketbase.delete_vocabulary(
                vocabulary_id,
                current_user.get("token", "")
            )
            if not success:
                raise HTTPException(status_code=404, detail="Vocabulary item not found")
            return {"message": "Vocabulary item deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to delete vocabulary: {str(e)}"
        )
