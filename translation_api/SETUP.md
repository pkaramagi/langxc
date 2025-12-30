# Translation Learning API - Setup Guide

## Quick Setup (5 minutes)

### 1. Install Python Dependencies

```bash
cd translation_api
pip install -r requirements.txt
```

### 2. Setup PostgreSQL

**Option A: Local PostgreSQL**

Install PostgreSQL and create database:

```bash
# macOS
brew install postgresql
brew services start postgresql

# Windows
# Download from: https://www.postgresql.org/download/windows/

# Create database
psql -U postgres
CREATE DATABASE translation_db;
\q
```

**Option B: Docker (Recommended)**

```bash
docker run --name translation-db \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=translation_db \
  -p 5432:5432 \
  -d postgres:15
```

### 3. Configure Environment

Update `.env` file with your database credentials:

```env
DATABASE_URL=postgresql+asyncpg://postgres:YOUR_PASSWORD@localhost:5432/translation_db
```

### 4. Run the Server

```bash
uvicorn main:app --reload
```

🎉 **Done!** API is running at http://localhost:8000

- **Swagger Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## Optional: Korean NLP Setup

For better vocabulary extraction, install KoNLPy:

### macOS/Linux:

```bash
brew install openjdk@11  # macOS
pip install konlpy JPype1
```

### Windows:

1. Download and install Java JDK 11+
2. Set `JAVA_HOME` environment variable
3. `pip install konlpy JPype1`

**Note**: The API works without KoNLPy (uses fallback), but vocabulary extraction is less accurate.

## Testing the API

### 1. Register a User

```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "display_name": "Test User"
  }'
```

Save the `access_token` from the response.

### 2. Test Translation Endpoint

```bash
curl -X POST "http://localhost:8000/translations" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "source_text": "안녕하세요",
    "translated_text": "Hello",
    "source_lang": "ko",
    "target_lang": "en"
  }'
```

### 3. Get Weekly Summary

```bash
curl -X GET "http://localhost:8000/translations/weekly-summary" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Connect to Flutter App

Update your Flutter app to use this backend:

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String apiRegister = '$apiBaseUrl/auth/register';
  static const String apiLogin = '$apiBaseUrl/auth/login';
  static const String apiTranslations = '$apiBaseUrl/translations';
  static const String apiWeeklySummary = '$apiBaseUrl/translations/weekly-summary';
}
```

Create an API service:

```dart
// lib/core/services/backend_api_service.dart
class BackendApiService {
  final String baseUrl = AppConstants.apiBaseUrl;
  String? _token;

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['access_token'];
      return true;
    }
    return false;
  }

  Future<void> saveTranslation({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/translations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: json.encode({
        'source_text': sourceText,
        'translated_text': translatedText,
        'source_lang': sourceLang,
        'target_lang': targetLang,
      }),
    );
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/translations/weekly-summary'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load weekly summary');
  }
}
```

## Production Deployment

1. **Update `.env`:**
   ```env
   DEBUG=False
   SECRET_KEY=<generate-strong-key>
   DATABASE_URL=postgresql+asyncpg://user:pass@prod-host:5432/db
   BACKEND_CORS_ORIGINS=["https://yourdomain.com"]
   ```

2. **Run with Gunicorn:**
   ```bash
   pip install gunicorn
   gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
   ```

3. **Use HTTPS** (nginx, Caddy, or cloud load balancer)

## Troubleshooting

### "Connection refused" error
- Check PostgreSQL is running: `pg_isready`
- Verify DATABASE_URL in `.env`

### KoNLPy import error
- Install Java JDK 11+
- Set JAVA_HOME environment variable

### CORS error from Flutter
- Add your app's URL to `BACKEND_CORS_ORIGINS` in `.env`
- Restart the server after changing `.env`

## Support

- Check the interactive docs: http://localhost:8000/docs
- Read the main README.md for detailed API documentation

