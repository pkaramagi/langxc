import httpx
from typing import Dict, List, Optional, Any
from core.config import settings


class PocketBaseClient:
    def __init__(self):
        self.base_url = settings.POCKETBASE_URL.rstrip('/')
        self.client = httpx.AsyncClient(timeout=30.0)
        self.admin_token: Optional[str] = None

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()

    async def authenticate_admin(self) -> str:
        """Authenticate as admin and return token."""
        response = await self.client.post(
            f"{self.base_url}/api/admins/auth-with-password",
            json={
                "identity": settings.POCKETBASE_EMAIL,
                "password": settings.POCKETBASE_PASSWORD
            }
        )
        response.raise_for_status()
        data = response.json()
        self.admin_token = data["token"]
        return self.admin_token

    async def _get_headers(self, user_token: Optional[str] = None) -> Dict[str, str]:
        """Get headers for requests."""
        headers = {"Content-Type": "application/json"}
        if user_token:
            headers["Authorization"] = f"Bearer {user_token}"
        elif self.admin_token:
            headers["Authorization"] = f"Bearer {self.admin_token}"
        return headers

    # Users collection methods
    async def create_user(self, email: str, password: str, display_name: str = "") -> Dict[str, Any]:
        """Create a new user."""
        response = await self.client.post(
            f"{self.base_url}/api/collections/users/records",
            json={
                "email": email,
                "password": password,
                "passwordConfirm": password,
                "name": display_name
            },
            headers=await self._get_headers()
        )
        response.raise_for_status()
        return response.json()

    async def authenticate_user(self, email: str, password: str) -> Dict[str, Any]:
        """Authenticate user and return token."""
        response = await self.client.post(
            f"{self.base_url}/api/collections/users/auth-with-password",
            json={
                "identity": email,
                "password": password
            }
        )
        response.raise_for_status()
        return response.json()

    async def get_user(self, user_id: str, token: str) -> Dict[str, Any]:
        """Get user by ID."""
        response = await self.client.get(
            f"{self.base_url}/api/collections/users/records/{user_id}",
            headers=await self._get_headers(token)
        )
        response.raise_for_status()
        return response.json()

    # Translations collection methods
    async def create_translation(self, user_id: str, source_text: str, translated_text: str, 
                               source_lang: str, target_lang: str, token: str) -> Dict[str, Any]:
        """Create a new translation."""
        response = await self.client.post(
            f"{self.base_url}/api/collections/translations/records",
            json={
                "user": user_id,
                "source_text": source_text,
                "translated_text": translated_text,
                "source_lang": source_lang,
                "target_lang": target_lang
            },
            headers=await self._get_headers(token)
        )
        response.raise_for_status()
        return response.json()

    async def get_user_translations(self, user_id: str, token: str, page: int = 1, per_page: int = 50) -> Dict[str, Any]:
        """Get user's translations with pagination."""
        response = await self.client.get(
            f"{self.base_url}/api/collections/translations/records",
            params={
                "filter": f"user.id='{user_id}'",
                "sort": "-created",
                "page": page,
                "perPage": per_page
            },
            headers=await self._get_headers(token)
        )
        response.raise_for_status()
        return response.json()

    async def delete_translation(self, translation_id: str, token: str) -> bool:
        """Delete a translation."""
        response = await self.client.delete(
            f"{self.base_url}/api/collections/translations/records/{translation_id}",
            headers=await self._get_headers(token)
        )
        return response.status_code == 204

    # Vocabulary collection methods
    async def create_or_update_vocabulary(self, user_id: str, word: str, translation: str,
                                        source_lang: str, target_lang: str, token: str) -> Dict[str, Any]:
        """Create or increment existing vocabulary item."""
        # Check if vocabulary item exists
        response = await self.client.get(
            f"{self.base_url}/api/collections/vocabulary/records",
            params={
                "filter": f"user.id='{user_id}' && word='{word}' && source_lang='{source_lang}' && target_lang='{target_lang}'"
            },
            headers=await self._get_headers(token)
        )
        
        if response.status_code == 200 and response.json()["items"]:
            # Update existing
            item = response.json()["items"][0]
            from datetime import datetime, timezone
            now_iso = datetime.now(timezone.utc).isoformat()
            update_response = await self.client.patch(
                f"{self.base_url}/api/collections/vocabulary/records/{item['id']}",
                json={
                    "count": item["count"] + 1,
                    "last_reviewed": now_iso
                },
                headers=await self._get_headers(token)
            )
            update_response.raise_for_status()
            return update_response.json()
        else:
            # Create new
            from datetime import datetime, timezone
            now_iso = datetime.now(timezone.utc).isoformat()
            create_response = await self.client.post(
                f"{self.base_url}/api/collections/vocabulary/records",
                json={
                    "user": user_id,
                    "word": word,
                    "translation": translation,
                    "source_lang": source_lang,
                    "target_lang": target_lang,
                    "count": 1,
                    "is_mastered": False,
                    "first_seen": now_iso,
                    "last_reviewed": now_iso
                },
                headers=await self._get_headers(token)
            )
            create_response.raise_for_status()
            return create_response.json()

    async def get_user_vocabulary(self, user_id: str, token: str, page: int = 1, per_page: int = 50) -> Dict[str, Any]:
        """Get user's vocabulary."""
        response = await self.client.get(
            f"{self.base_url}/api/collections/vocabulary/records",
            params={
                "filter": f"user.id='{user_id}'",
                "sort": "-last_reviewed",
                "page": page,
                "perPage": per_page
            },
            headers=await self._get_headers(token)
        )
        response.raise_for_status()
        return response.json()

    async def update_vocabulary_mastered(self, vocab_id: str, is_mastered: bool, token: str) -> Dict[str, Any]:
        """Update vocabulary mastery status."""
        from datetime import datetime, timezone
        now_iso = datetime.now(timezone.utc).isoformat()
        response = await self.client.patch(
            f"{self.base_url}/api/collections/vocabulary/records/{vocab_id}",
            json={
                "is_mastered": is_mastered,
                "last_reviewed": now_iso
            },
            headers=await self._get_headers(token)
        )
        response.raise_for_status()
        return response.json()

    async def delete_vocabulary(self, vocab_id: str, token: str) -> bool:
        """Delete vocabulary item."""
        response = await self.client.delete(
            f"{self.base_url}/api/collections/vocabulary/records/{vocab_id}",
            headers=await self._get_headers(token)
        )
        return response.status_code == 204


# Global client instance
pocketbase = PocketBaseClient()
