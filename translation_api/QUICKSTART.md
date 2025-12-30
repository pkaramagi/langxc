# 🚀 Translation Learning API - 5 Minute Quickstart

Get your backend running in 5 minutes with PocketBase!

## Step 1: Start PocketBase (2 min)

```bash
cd pocketbase
pocketbase serve
```

PocketBase will start on http://localhost:8090

**First time setup:**
1. Open http://localhost:8090/_/ in your browser
2. Create your admin account
3. Note down your admin email and password

## Step 2: Create Collections (2 min)

In PocketBase admin UI (http://localhost:8090/_/), create these collections:

**users collection** (auth type):
- Set as "Auth Collection"
- Add field: `display_name` (text, optional)

**translations collection** (base type):
- Add fields:
  - `user` (relation to users)
  - `source_text` (text, required)
  - `translated_text` (text, required)
  - `source_lang` (text, required)
  - `target_lang` (text, required)

**vocabulary collection** (base type):
- Add fields:
  - `user` (relation to users)
  - `word` (text, required)
  - `translation` (text, required)
  - `source_lang` (text, required)
  - `target_lang` (text, required)
  - `count` (number, required, default: 1)
  - `is_mastered` (bool, required, default: false)
  - `first_seen` (date, required)
  - `last_reviewed` (date, required)

## Step 3: Install Dependencies (1 min)

```bash
cd translation_api
pip install -r requirements.txt
```

## Step 4: Configure Environment (30 sec)

Create `.env` file:

```env
# PocketBase Configuration
POCKETBASE_URL=http://localhost:8090
POCKETBASE_EMAIL=your-admin-email@example.com
POCKETBASE_PASSWORD=your-admin-password

# FastAPI Configuration
SECRET_KEY=your-secret-key-change-this-in-production
DEBUG=True
BACKEND_CORS_ORIGINS=["http://localhost:61311","http://localhost:8080"]
```

## Step 5: Start FastAPI Server (30 sec)

```bash
uvicorn main:app --reload
```

You should see:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete.
```

## Step 5: Test API (2 min)

**Option A: Run Test Script**
```bash
python test_api.py
```

**Option B: Use Swagger UI**

Open in browser: http://localhost:8000/docs

Try these:
1. Click on `POST /auth/register`
2. Click "Try it out"
3. Fill in:
   ```json
   {
     "email": "test@example.com",
     "password": "test123",
     "display_name": "Test User"
   }
   ```
4. Click "Execute"
5. Copy the `access_token` from response
6. Click "Authorize" button at top (🔒)
7. Paste token and click "Authorize"
8. Now try other endpoints!

## 🎉 That's It!

Your API is running at:
- **Base URL**: http://localhost:8000
- **Swagger Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## Next Steps

### Connect to Your Flutter App

Add this service to your Flutter app:

```dart
// lib/core/services/backend_api_service.dart
class BackendApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  // See flutter_integration_example.dart for full code
}
```

Update your translation provider to save to backend:

```dart
// After translating with Papago
final translated = await papagoService.translate(text);

// Save to backend
await backendApiService.saveTranslation(
  sourceText: text,
  translatedText: translated,
  sourceLang: 'ko',
  targetLang: 'en',
);
```

### Get Weekly Summary in Flutter

```dart
final summary = await backendApiService.getWeeklySummary();

// summary contains:
// - total_translations
// - unique_words
// - most_frequent_words (with counts and examples)
```

## Common Issues

### "Connection refused" to PocketBase
- Make sure PocketBase is running: Check http://localhost:8090/_/
- Verify PocketBase URL in `.env` is correct
- Check that PocketBase admin credentials are correct

### "Collection not found" error
- Make sure you created all required collections in PocketBase admin UI
- Check collection names match exactly (users, translations, vocabulary)

### "ModuleNotFoundError"
- Install dependencies: `pip install -r requirements.txt`

### CORS error from Flutter
- Add your Flutter URL to `.env`:
  ```env
  BACKEND_CORS_ORIGINS=["http://localhost:61311","http://localhost:8080"]
  ```
- Restart server after editing `.env`

### KoNLPy warning
- Optional: Install Java JDK for better Korean NLP
- The API works without it (uses fallback)

## Production Deployment

When ready to deploy:

1. **Update `.env`:**
   ```env
   DEBUG=False
   SECRET_KEY=<generate-a-strong-random-key>
   POCKETBASE_URL=<your-production-pocketbase-url>
   BACKEND_CORS_ORIGINS=["https://yourdomain.com"]
   ```

2. **Deploy PocketBase:**
   - Use PocketBase's deployment guides for production
   - Set up proper backup strategies for the SQLite database

2. **Run with Gunicorn:**
   ```bash
   pip install gunicorn
   gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker
   ```

3. **Use HTTPS** (nginx, Caddy, or cloud load balancer)

## API Cheat Sheet

### Register
```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"pass123"}'
```

### Login
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"pass123"}'
```

### Save Translation
```bash
curl -X POST "http://localhost:8000/translations" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "source_text":"안녕하세요",
    "translated_text":"Hello",
    "source_lang":"ko",
    "target_lang":"en"
  }'
```

### Get Weekly Summary
```bash
curl -X GET "http://localhost:8000/translations/weekly-summary" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Documentation

- **Full README**: See `README.md` for complete API documentation
- **Setup Guide**: See `SETUP.md` for detailed setup instructions
- **Project Structure**: See `PROJECT_STRUCTURE.md` for codebase overview
- **Flutter Integration**: See `flutter_integration_example.dart` for Flutter code

## Support

For issues or questions:
1. Check the interactive docs at http://localhost:8000/docs
2. Review the README.md
3. Make sure PostgreSQL is running and `.env` is configured

---

**Happy Coding!** 🎉

Your backend is now ready to power your Korean-English translation learning app!

