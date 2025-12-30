# Translation Learning API

A production-ready FastAPI backend for Korean-English translation learning app.

## Features

- ✅ **User Authentication** - JWT-based auth with bcrypt password hashing
- ✅ **Translation Storage** - Store and retrieve translation history
- ✅ **Vocabulary Extraction** - Auto-extract Korean vocabulary using NLP
- ✅ **Weekly Summary** - Get most frequent words and learning statistics
- ✅ **Rate Limiting** - Protect API from abuse
- ✅ **CORS Enabled** - Ready for Flutter web/mobile apps
- ✅ **OpenAPI Docs** - Interactive documentation at `/docs`

## Tech Stack

- **FastAPI** 0.109+ - Modern Python web framework
- **SQLAlchemy** 2.0 - Async ORM
- **PostgreSQL** - Primary database
- **Pydantic** v2 - Data validation
- **JWT** - Token-based authentication
- **KoNLPy** - Korean NLP for vocabulary extraction

## Quick Start

### 1. Prerequisites

- Python 3.11+
- PostgreSQL 14+
- (Optional) Java JDK for KoNLPy

### 2. Install Dependencies

```bash
cd translation_api
pip install -r requirements.txt
```

### 3. Setup Database

Create a PostgreSQL database:

```sql
CREATE DATABASE translation_db;
```

### 4. Configuration

Copy `.env.example` to `.env` and update:

```bash
cp .env.example .env
```

Edit `.env`:
```env
SECRET_KEY=your-super-secret-key-min-32-characters
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/translation_db
```

### 5. Run Server

```bash
uvicorn main:app --reload
```

Server starts at: `http://localhost:8000`

- **Swagger Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## API Endpoints

### Authentication

```http
POST /auth/register
POST /auth/login
GET  /auth/me
```

### Translations

```http
POST   /translations          # Create translation
GET    /translations          # List translations
GET    /translations/stats    # Get statistics
GET    /translations/weekly-summary  # Weekly vocab summary
DELETE /translations/{id}     # Delete translation
```

### Vocabulary

```http
GET    /vocabulary            # List vocabulary
GET    /vocabulary/{id}       # Get vocabulary item
PATCH  /vocabulary/{id}       # Update (mark mastered)
DELETE /vocabulary/{id}       # Delete vocabulary item
```

## Usage Examples

### 1. Register User

```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepass123",
    "display_name": "John Doe"
  }'
```

Response:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer"
}
```

### 2. Create Translation

```bash
curl -X POST "http://localhost:8000/translations" \
  -H "Authorization: Bearer YOUR_TOKEN" \
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
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:
```json
{
  "week_start": "2024-01-15T00:00:00Z",
  "week_end": "2024-01-22T00:00:00Z",
  "total_translations": 42,
  "unique_words": 78,
  "most_frequent_words": [
    {
      "word": "안녕하세요",
      "count": 15,
      "translations": ["Hello"],
      "example_sentences": ["안녕하세요, 만나서 반갑습니다"]
    }
  ]
}
```

## Flutter Integration

### Setup in Flutter

```dart
class ApiService {
  static const baseUrl = 'http://localhost:8000';
  String? _token;

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      _token = data['access_token'];
    }
  }

  Future<void> saveTranslation(Translation translation) async {
    await http.post(
      Uri.parse('$baseUrl/translations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: json.encode(translation.toJson()),
    );
  }
}
```

## Korean NLP Setup

### Install KoNLPy (Optional but Recommended)

#### macOS/Linux:
```bash
# Install Java first
brew install openjdk@11  # macOS
# or: sudo apt install openjdk-11-jdk  # Ubuntu

# Install KoNLPy
pip install konlpy JPype1
```

#### Windows:
1. Install Java JDK 11+
2. Set `JAVA_HOME` environment variable
3. `pip install konlpy JPype1`

**Note**: If KoNLPy is not available, the API falls back to regex-based extraction (less accurate).

## Database Migrations

This project uses SQLAlchemy's `create_all()` for simplicity. For production, use Alembic:

```bash
# Initialize alembic
alembic init alembic

# Create migration
alembic revision --autogenerate -m "Initial migration"

# Apply migration
alembic upgrade head
```

## Production Deployment

### Environment Variables

Set these in production:

```env
DEBUG=False
SECRET_KEY=<strong-random-key>
DATABASE_URL=postgresql+asyncpg://user:pass@prod-db:5432/db
BACKEND_CORS_ORIGINS=["https://yourdomain.com"]
```

### Run with Gunicorn

```bash
pip install gunicorn
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Docker (Optional)

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest
```

## Security Notes

- ✅ Passwords hashed with bcrypt
- ✅ JWT tokens with 7-day expiry
- ✅ Rate limiting (60 req/min default)
- ✅ SQL injection protection (SQLAlchemy ORM)
- ✅ CORS configured
- ⚠️ Change `SECRET_KEY` in production
- ⚠️ Use HTTPS in production
- ⚠️ Set `DEBUG=False` in production

## Troubleshooting

### KoNLPy Import Error
```
ImportError: cannot import name 'Okt' from 'konlpy.tag'
```
**Solution**: Install Java JDK and set JAVA_HOME

### Database Connection Error
```
asyncpg.exceptions.InvalidPasswordError
```
**Solution**: Check DATABASE_URL in `.env`

### CORS Error in Flutter
```
Access to fetch at ... has been blocked by CORS policy
```
**Solution**: Add your domain to `BACKEND_CORS_ORIGINS` in `.env`

## License

MIT License - Free to use for personal and commercial projects.

## Support

For issues or questions, check the `/docs` endpoint for interactive API documentation.

