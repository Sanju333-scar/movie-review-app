from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from database import get_db, Base, engine
from sqlalchemy import text
import requests  # ✅ NEW
from auth import create_access_token
from models import User

app = FastAPI(title="CineRev Login API")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ✅ Pydantic Model
class LoginRequest(BaseModel):
    email: str
    password: str

# ✅ Google Request Model (FIXED)
class GoogleLoginRequest(BaseModel):
    access_token: str


# ✅ Create tables
Base.metadata.create_all(bind=engine)


# =========================================================
# NORMAL EMAIL LOGIN
# =========================================================
@app.post("/login")
def login_user(request: LoginRequest, db: Session = Depends(get_db)):

    result = db.execute(
        text("SELECT id, name, email, password FROM users WHERE email=:email"),
        {"email": request.email}
    )
    user = result.fetchone()

    if not user:
        raise HTTPException(status_code=400, detail="Email not found")

    user_id, name, email, hashed_password = user

    if not pwd_context.verify(request.password, hashed_password):
        raise HTTPException(status_code=400, detail="Invalid password")

    # ✅ Issue JWT (recommended for consistency)
    access_token = create_access_token(
        data={"sub": str(user_id)}
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user_id,
        "name": name,
        "email": email
    }


