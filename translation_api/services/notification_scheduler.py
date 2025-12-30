import os
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import firebase_admin
from firebase_admin import credentials, messaging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from core.pocketbase_client import pocketbase
from core.config import settings


class NotificationScheduler:
    def __init__(self):
        self.scheduler = AsyncIOScheduler()
        self._firebase_initialized = False

    async def start(self):
        """Start the notification scheduler."""
        await self._initialize_firebase()
        await self._authenticate_pocketbase()

        # Schedule daily notification check
        self.scheduler.add_job(
            self._send_scheduled_notifications,
            CronTrigger(hour=9, minute=0),  # Run daily at 9 AM
            id='daily_notifications',
            name='Send scheduled notifications',
            replace_existing=True
        )

        self.scheduler.start()
        print("Notification scheduler started")

    async def stop(self):
        """Stop the notification scheduler."""
        if self.scheduler.running:
            self.scheduler.shutdown()
            print("Notification scheduler stopped")

    async def _initialize_firebase(self):
        """Initialize Firebase Admin SDK."""
        if self._firebase_initialized:
            return

        try:
            # For now, we'll use default credentials
            # In production, you'd set GOOGLE_APPLICATION_CREDENTIALS
            # or provide the service account key path
            firebase_admin.initialize_app()
            self._firebase_initialized = True
            print("Firebase Admin SDK initialized")
        except Exception as e:
            print(f"Failed to initialize Firebase: {e}")
            # For development, we'll continue without Firebase
            # In production, this should raise an error

    async def _authenticate_pocketbase(self):
        """Authenticate with PocketBase."""
        try:
            async with pocketbase:
                await pocketbase.authenticate_admin()
                print("PocketBase authentication successful")
        except Exception as e:
            print(f"Failed to authenticate with PocketBase: {e}")

    async def _send_scheduled_notifications(self):
        """Send notifications to users based on their preferences."""
        print("Checking for users who need notifications...")

        try:
            async with pocketbase:
                await pocketbase.authenticate_admin()

                # In a real implementation, you would:
                # 1. Query users from PocketBase who have FCM tokens
                # 2. Check their notification preferences
                # 3. Send appropriate notifications

                # For now, we'll simulate this process
                print("Notification check completed (simulated)")

                # Example of how you would send a notification:
                # await self._send_notification_to_user(
                #     fcm_token="user_fcm_token",
                #     title="Your Daily Language Summary",
                #     body="You've translated 5 words today!",
                #     data={"type": "daily_summary"}
                # )

        except Exception as e:
            print(f"Error sending scheduled notifications: {e}")

    async def send_notification_to_user(
        self,
        user_id: str,
        notification_type: str,  # 'daily', 'two_day', 'weekly'
        summary_data: Dict
    ):
        """Send a notification to a specific user."""
        try:
            async with pocketbase:
                await pocketbase.authenticate_admin()

                # Get user FCM token (in real implementation, this would be stored)
                # For now, we'll skip the actual sending

                title, body = self._create_notification_content(notification_type, summary_data)

                print(f"Would send notification to user {user_id}: {title} - {body}")

                # Uncomment when FCM token storage is implemented:
                # await self._send_fcm_notification(
                #     fcm_token=fcm_token,
                #     title=title,
                #     body=body,
                #     data={"type": notification_type, "user_id": user_id}
                # )

        except Exception as e:
            print(f"Error sending notification to user {user_id}: {e}")

    def _create_notification_content(self, notification_type: str, summary_data: Dict) -> tuple[str, str]:
        """Create notification title and body based on type and data."""
        total_translations = summary_data.get('total_translations', 0)
        unique_words = summary_data.get('unique_words', 0)

        if notification_type == 'daily':
            title = "Your Daily Language Summary"
            body = f"You've translated {total_translations} items and learned {unique_words} new words today!"
        elif notification_type == 'two_day':
            title = "Your 2-Day Language Progress"
            body = f"Over the last 2 days, you've translated {total_translations} items and learned {unique_words} new words!"
        elif notification_type == 'weekly':
            title = "Your Weekly Language Summary"
            body = f"This week, you've translated {total_translations} items and learned {unique_words} new words!"
        else:
            title = "Language Learning Update"
            body = f"You've made progress! {total_translations} translations, {unique_words} unique words."

        return title, body

    async def _send_fcm_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: Dict = {}
    ):
        """Send FCM notification."""
        if not self._firebase_initialized:
            print("Firebase not initialized, skipping notification")
            return

        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data,
                token=fcm_token,
            )

            response = messaging.send(message)
            print(f"Successfully sent message: {response}")
        except Exception as e:
            print(f"Error sending FCM message: {e}")

    async def get_user_summary(self, user_id: str, summary_type: str) -> Dict:
        """Get summary data for a user."""
        try:
            async with pocketbase:
                await pocketbase.authenticate_admin()

                # Get appropriate summary based on type
                if summary_type == 'daily':
                    summary = await pocketbase.get_user_daily_summary(user_id)
                elif summary_type == 'two_day':
                    summary = await pocketbase.get_user_two_day_summary(user_id)
                elif summary_type == 'weekly':
                    summary = await pocketbase.get_user_weekly_summary(user_id)
                else:
                    summary = await pocketbase.get_user_weekly_summary(user_id)

                return summary

        except Exception as e:
            print(f"Error getting {summary_type} summary for user {user_id}: {e}")
            return {"total_translations": 0, "unique_words": 0, "most_frequent_words": []}


# Global scheduler instance
notification_scheduler = NotificationScheduler()
