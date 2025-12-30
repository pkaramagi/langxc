# Translation Learning API - Project Structure

```
translation_api/
│
├── main.py                          # FastAPI application entry point
├── requirements.txt                 # Python dependencies
├── .env                            # Environment configuration (create from .env.example)
├── .gitignore                      # Git ignore rules
├── README.md                       # Full documentation
├── SETUP.md                        # Quick setup guide
├── PROJECT_STRUCTURE.md            # This file
├── test_api.py                     # Quick API test script
├── flutter_integration_example.dart # Flutter integration code
│
├── core/                           # Core application modules
│   ├── __init__.py
│   ├── config.py                   # Settings and configuration
│   ├── security.py                 # JWT and password hashing
│   └── database.py                 # Database connection and session
│
├── models/                         # SQLAlchemy database models
│   ├── __init__.py
│   ├── user.py                     # User model
│   ├── translation.py              # Translation model
│   └── vocabulary.py               # Vocabulary model
│
├── schemas/                        # Pydantic schemas for validation
│   ├── __init__.py
│   ├── user.py                     # User schemas
│   ├── translation.py              # Translation schemas
│   ├── vocabulary.py               # Vocabulary schemas
│   └── auth.py                     # Auth schemas (Token, Login, Register)
│
├── routers/                        # API route handlers
│   ├── __init__.py
│   ├── auth.py                     # /auth endpoints
│   ├── translations.py             # /translations endpoints
│   └── vocabulary.py               # /vocabulary endpoints
│
├── services/                       # Business logic services
│   ├── __init__.py
│   └── korean_extractor.py         # Korean NLP vocabulary extraction
│
├── tests/                          # Unit tests
│   ├── __init__.py
│   └── test_auth.py                # Auth endpoint tests
│
├── alembic/                        # Database migrations
│   ├── env.py                      # Alembic environment
│   ├── script.py.mako              # Migration template
│   └── README
│
├── alembic.ini                     # Alembic configuration
├── pytest.ini                      # Pytest configuration
├── Dockerfile                      # Docker image definition
└── docker-compose.yml              # Docker compose for PostgreSQL
```

## Key Files Explained

### Application Core

- **main.py**: The main FastAPI application with middleware, routers, and lifespan events
- **core/config.py**: Centralized configuration using Pydantic Settings
- **core/security.py**: JWT token creation/validation and password hashing
- **core/database.py**: Async SQLAlchemy engine and session management

### Data Layer

- **models/*.py**: SQLAlchemy ORM models (define database tables)
- **schemas/*.py**: Pydantic models for request/response validation
- **services/korean_extractor.py**: NLP service for extracting Korean vocabulary

### API Layer

- **routers/auth.py**: Authentication endpoints (register, login, me)
- **routers/translations.py**: Translation CRUD and weekly summary
- **routers/vocabulary.py**: Vocabulary management endpoints

### Database Migrations

- **alembic/**: Database migration files (use `alembic revision` to create new migrations)
- **alembic.ini**: Configuration for Alembic migrations

### Testing & Deployment

- **test_api.py**: Simple Python script to test all endpoints
- **tests/**: Unit tests using pytest and httpx
- **Dockerfile**: Container image for deployment
- **docker-compose.yml**: Run PostgreSQL in Docker

### Documentation & Examples

- **README.md**: Complete API documentation
- **SETUP.md**: Step-by-step setup instructions
- **flutter_integration_example.dart**: Flutter code examples

## Database Schema

### users
- id (PK)
- email (unique)
- hashed_password
- display_name
- is_active
- created_at
- updated_at

### translations
- id (PK)
- user_id (FK → users)
- source_text
- translated_text
- source_lang ('ko' or 'en')
- target_lang ('ko' or 'en')
- created_at

### vocabulary
- id (PK)
- user_id (FK → users)
- word
- translation
- source_lang
- target_lang
- count (how many times seen)
- is_mastered
- first_seen
- last_reviewed

## API Endpoints

### Authentication
```
POST   /auth/register    # Register new user
POST   /auth/login       # Login and get JWT token
GET    /auth/me          # Get current user info
```

### Translations
```
POST   /translations              # Create new translation
GET    /translations              # List user's translations
GET    /translations/stats        # Get translation statistics
GET    /translations/weekly-summary  # Get weekly vocabulary summary
DELETE /translations/{id}         # Delete translation
```

### Vocabulary
```
GET    /vocabulary          # List vocabulary items
GET    /vocabulary/{id}     # Get specific vocabulary item
PATCH  /vocabulary/{id}     # Update vocabulary (mark mastered)
DELETE /vocabulary/{id}     # Delete vocabulary item
```

### Utility
```
GET    /                    # Root info
GET    /health             # Health check
GET    /docs               # Swagger UI
GET    /redoc              # ReDoc UI
```

## Quick Start Commands

```bash
# Install dependencies
pip install -r requirements.txt

# Start PostgreSQL (Docker)
docker-compose up -d

# Run the server
uvicorn main:app --reload

# Test the API
python test_api.py

# Run unit tests
pytest

# Create database migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head
```

## Environment Variables

Set these in `.env`:

```env
SECRET_KEY=<random-string-min-32-chars>
DATABASE_URL=postgresql+asyncpg://user:pass@host:port/dbname
DEBUG=True
BACKEND_CORS_ORIGINS=["http://localhost:61311"]
```

## Development Workflow

1. **Start PostgreSQL**: `docker-compose up -d`
2. **Run server**: `uvicorn main:app --reload`
3. **Open docs**: http://localhost:8000/docs
4. **Test endpoints**: Use Swagger UI or `python test_api.py`
5. **Make changes**: Edit code, server auto-reloads
6. **Run tests**: `pytest`
7. **Create migration**: `alembic revision --autogenerate -m "message"`
8. **Apply migration**: `alembic upgrade head`

## Production Deployment Checklist

- [ ] Set `DEBUG=False` in `.env`
- [ ] Generate strong `SECRET_KEY`
- [ ] Use production database (not localhost)
- [ ] Set proper `BACKEND_CORS_ORIGINS`
- [ ] Run with Gunicorn + Uvicorn workers
- [ ] Use HTTPS (nginx/Caddy reverse proxy)
- [ ] Set up monitoring and logging
- [ ] Enable database backups
- [ ] Review rate limits
- [ ] Run security audit

## Adding New Features

### Add a new endpoint:

1. Create schema in `schemas/`
2. Add route handler in `routers/`
3. Include router in `main.py`
4. Test in Swagger UI

### Add a new model:

1. Create model in `models/`
2. Import in `alembic/env.py`
3. Create migration: `alembic revision --autogenerate`
4. Apply: `alembic upgrade head`

## Support & Documentation

- **Interactive Docs**: http://localhost:8000/docs
- **API Spec**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health
- **README**: Full documentation and examples
- **SETUP**: Step-by-step setup guide

