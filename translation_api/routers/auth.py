from datetime import timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

from core.config import settings
from core.pocketbase_client import pocketbase
from core.security import create_access_token, verify_password
from schemas.auth import Token, UserCreate, UserResponse, LoginRequest

router = APIRouter(prefix="/auth", tags=["authentication"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


@router.post("/register", response_model=Token)
async def register(user_data: UserCreate) -> Any:
    """Register a new user."""
    try:
        async with pocketbase:
            await pocketbase.authenticate_admin()
            # 1. Create the user
            user = await pocketbase.create_user(
                email=user_data.email,
                password=user_data.password,
                display_name=user_data.display_name
            )
            
            # 2. Authenticate to get the token
            auth_data = await pocketbase.authenticate_user(
                email=user_data.email,
                password=user_data.password
            )
            
            # 3. Create JWT with PB token
            access_token = create_access_token(
                data={
                    "sub": user["id"], 
                    "email": user["email"],
                    "pb_token": auth_data["token"]
                },
                expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
            )
            return Token(access_token=access_token, token_type="bearer")
    except Exception as e:
        print(f"Registration failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Registration failed: {str(e)}"
        )


@router.post("/login", response_model=Token)
async def login(
    login_data: LoginRequest,
) -> Any:
    """
    Login user and return JWT token.
    Supports JSON body.
    """
    try:
        print(f"Login via JSON: {login_data.email}")
        email = login_data.email
        password = login_data.password

        async with pocketbase:
            print(f"Attempting to authenticate with PocketBase: {email}")
            auth_data = await pocketbase.authenticate_user(
                email=email,
                password=password
            )
            print("PocketBase authentication successful")
            
            access_token = create_access_token(
                data={
                    "sub": auth_data["record"]["id"], 
                    "email": auth_data["record"]["email"],
                    "pb_token": auth_data["token"]
                },
                expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
            )
            return Token(access_token=access_token, token_type="bearer")
    except Exception as e:
        print(f"Login failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Incorrect email or password. Error: {str(e)}"
        )


async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    """Get current authenticated user."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        pb_token: str = payload.get("pb_token")
        
        if user_id is None or pb_token is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    try:
        async with pocketbase:
            # We use the user's token to get their profile
            # This ensures we respect PocketBase's RLS rules
            user = await pocketbase.get_user(user_id, pb_token)
            
            # Inject the token into the user object so routers can use it
            user["token"] = pb_token
            return user
    except Exception as e:
        print(f"Token validation failed in get_user: {str(e)}")
        raise credentials_exception


@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: dict = Depends(get_current_user)) -> Any:
    """Get current user information."""
    return UserResponse(
        id=current_user["id"],
        email=current_user["email"],
        display_name=current_user.get("display_name", ""),
        is_active=current_user.get("verified", True),
        created=current_user["created"],
        updated=current_user["updated"]
    )
