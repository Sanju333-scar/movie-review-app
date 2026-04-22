# routes/google_auth.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import User
from auth import create_access_token
from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import requests
import os

router = APIRouter(tags=["Google Auth"])

GOOGLE_CLIENT_ID = "495284894003-8rfrgebd2cl27k2pdn4m5o5i3cm533rm.apps.googleusercontent.com"


# ✅ Unified Request Model (accepts either token)
class GoogleLoginRequest(BaseModel):
    id_token: str | None = None
    access_token: str | None = None


@router.post("/auth/google")
def google_login(data: GoogleLoginRequest, db: Session = Depends(get_db)):

    email = None
    name = None
    google_id = None

    # ---------------------------------------------------
    # 1️⃣ Try ID TOKEN verification (Mobile flow)
    # ---------------------------------------------------
    if data.id_token:
        try:
            idinfo = id_token.verify_oauth2_token(
                data.id_token,
                google_requests.Request(),
                GOOGLE_CLIENT_ID
            )

            email = idinfo.get("email")
            name = idinfo.get("name", "Google User")
            google_id = idinfo.get("sub")

        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid Google ID token"
            )

    # ---------------------------------------------------
    # 2️⃣ If no ID token, verify ACCESS TOKEN (Web flow)
    # ---------------------------------------------------
    elif data.access_token:
        response = requests.get(
            "https://www.googleapis.com/oauth2/v3/userinfo",
            headers={"Authorization": f"Bearer {data.access_token}"}
        )

        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid Google access token"
            )

        userinfo = response.json()

        email = userinfo.get("email")
        name = userinfo.get("name", "Google User")
        google_id = userinfo.get("sub")

    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No Google token provided"
        )

    # ---------------------------------------------------
    # 3️⃣ Validate Email
    # ---------------------------------------------------
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google account email not available"
        )

    # ---------------------------------------------------
    # 4️⃣ Check if user exists
    # ---------------------------------------------------
    user = db.query(User).filter(User.email == email).first()

    if not user:
        user = User(
            name=name,
            email=email,
            password_hash="GOOGLE_ACCOUNT",
            google_id=google_id
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # ---------------------------------------------------
    # 5️⃣ Create YOUR JWT
    # ---------------------------------------------------
    access_token = create_access_token(
        data={"sub": str(user.id)}
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "name": user.name,
        "email": user.email
    }