# Backend Integration Guide

We have successfully integrated the Flutter frontend with the FastAPI + PocketBase backend.

## 🏗️ Architecture

1.  **PocketBase**: Acts as the Database and Auth Provider.
2.  **FastAPI**: Acts as the Middleware (API) that handles business logic (NLP) and proxies requests to PocketBase.
3.  **Flutter**: The UI that talks **only** to FastAPI.

## 🔄 Changes Made

### 1. Backend (FastAPI)
- **Fixed Auth Bug**: The FastAPI backend now correctly handles PocketBase authentication.
- **Token Handling**: When you login via FastAPI, it authenticates with PocketBase, gets a session token, and embeds it into the FastAPI JWT.
- **Request Proxying**: All requests to the database now use the authenticated user's token, ensuring security and correct data access.

### 2. Frontend (Flutter)
- **AuthProvider**: Switched from Firebase Auth to `BackendApiService`. Now uses your custom backend for login/register.
- **HistoryProvider**: Switched from local storage to `BackendApiService`. Now fetches translations and vocabulary from the cloud.
- **BackendApiService**: Upgraded to a Singleton to share auth state across the app. Fixed ID types (String vs Int).

## 🚀 How to Run

You need to run 3 terminals:

### Terminal 1: PocketBase (Database)
```bash
cd translation_api/pocketbase
./pocketbase.exe serve
```
*Admin UI: http://127.0.0.1:8090/_/*

### Terminal 2: FastAPI (Backend API)
```bash
cd translation_api
uvicorn main:app --reload
```
*API Docs: http://127.0.0.1:8000/docs*

### Terminal 3: Flutter (App)
```bash
flutter run
```

## ⚠️ Important Notes

- **Firebase**: Firebase Auth is now **disabled** in the UI (replaced by custom auth). Firebase Core is still initialized for potential future use (Notifications).
- **Data**: Your old local data will not appear in the new backend. You start fresh.
- **Emulators**: If running on Android Emulator, you might need to change `localhost` to `10.0.2.2` in `lib/core/services/backend_api_service.dart`.
