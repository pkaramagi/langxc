from pydantic import BaseModel, EmailStr


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    email: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: str | None = None


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    display_name: str | None = None


class UserResponse(BaseModel):
    id: str
    email: str
    display_name: str | None = None
    is_active: bool = True
    created: str
    updated: str
