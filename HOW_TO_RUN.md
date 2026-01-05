
# 🚀 How to Run LangXC

This guide will walk you through setting up and running the **LangXC** application locally. The app consists of three components that must run simultaneously:

1.  **PocketBase** – Database & Authentication (Port 8090)
2.  **FastAPI** – Backend API / Middleware (Port 8000)
3.  **Flutter** – Mobile/Web Frontend

---

## 📋 Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| **Flutter SDK** | 3.10.0+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| **Python** | 3.10+ | [python.org](https://www.python.org/downloads/) |
| **Git** | Latest | [git-scm.com](https://git-scm.com/downloads) |

---

## ⚙️ Step 1: Configuration (Crucial!)

**You must configure the environment variables correctly or the backend will fail to connect.**

1.  Navigate to `translation_api/`.
2.  Copy the example file:
    ```bash
    cp .env.example .env
    ```
3.  **Edit `.env`** and fill in the following:

    ```ini
    # App Security
    SECRET_KEY=change-this-to-a-long-random-string
    DEBUG=True

    # PocketBase Admin Credentials
    # IMPORTANT: These MUST match the Admin account you create in Step 2.
    POCKETBASE_EMAIL=admin@example.com
    POCKETBASE_PASSWORD=your-secure-password
    POCKETBASE_URL=http://localhost:8090
    ```

---

## 🛠️ Step 2: Start PocketBase (Database)

Open **Terminal 1**:

```bash
cd translation_api/pocketbase
./pocketbase.exe serve
```

1.  Go to **[http://127.0.0.1:8090/_/](http://127.0.0.1:8090/_/)** in your browser.
2.  **Create your Admin Account** (email/password).
3.  **UPDATE YOUR `.env` FILE** (from Step 1) to match this email and password exactly.

---

## 🚀 Step 3: Start FastAPI (Backend)

Open **Terminal 2**:

```bash
cd translation_api

# 1. Create/Activate Virtual Environment
python -m venv .venv
.\.venv\Scripts\activate  # Windows
# or: source .venv/bin/activate  # Mac/Linux

# 2. Install Dependencies
pip install -r requirements.txt

# 3. Run Server
# Development (Auto-reload):
python -m uvicorn main:app --reload

# Production (Gunicorn):
# gunicorn -c gunicorn_conf.py main:app
```

> **Verify:** Open [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs). You should see the Swagger UI.

---

## 📱 Step 4: Start Flutter (Frontend)

Open **Terminal 3**:

```bash
# 1. Install Dependencies
flutter pub get

# 2. Run on Chrome (Recommended for Dev)
flutter run -d chrome
```

---

## 🐛 Troubleshooting

### ❌ Backend Connection Error (404 / Client Error)
*   **Cause:** Your `.env` credentials do not match the PocketBase Admin account.
*   **Fix:** Check `POCKETBASE_EMAIL` and `POCKETBASE_PASSWORD` in `.env`. Restart the backend after changing.

### ❌ Registration Failed with "Status 200"
*   **Cause:** Frontend expecting 201 but Backend returning 200.
*   **Fix:** This was fixed in the latest update. Ensure you are on the latest `main` branch.

### ❌ "Client has been closed" Error
*   **Cause:** Old PocketBase client code prematurely closing connections.
*   **Fix:** Update repository used the fixed `PocketBaseClient` class.

### ❌ Android Emulator Connection Refused
*   **Fix:** Android emulators cannot use `localhost`.
    *   Change `baseUrl` in `lib/core/services/backend_api_service.dart` to `http://10.0.2.2:8000`.

---

## 🔗 Service URLs

| Service | URL | Description |
|---------|-----|-------------|
| **Flutter Web** | `http://localhost:8080` | Frontend application |
| **FastAPI** | `http://127.0.0.1:8000` | Backend API |
| **PocketBase Admin** | `http://127.0.0.1:8090/_/` | Database Dashboard |
