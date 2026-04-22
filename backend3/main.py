# main.py
from dotenv import load_dotenv
load_dotenv() 
import re
from datetime import datetime, timedelta

from fastapi import FastAPI, Depends, HTTPException, Form, Request
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

# Local imports
import models
import crud
import schemas

from database import SessionLocal, engine, Base
from auth import (
    verify_token,
    get_password_hash,
    create_access_token,
)

# Routers
from routes.movies import router as movies_router
from routes.reviews import router as reviews_router
from routes.events import router as events_router
from routes.lists import router as lists_router
from routes.activity_router import router as activity_router
from routes import ai_recommend
from routes import recommendations
from routes import recommendation_seed
from routes.google_auth import router as google_auth_router
from config import (
    SECRET_KEY,
    ALGORITHM,
    GMAIL_USER,
    GMAIL_APP_PASSWORD,
    RESET_TOKEN_EXPIRE_MINUTES,
    RESET_LINK_HTTP,
    RESET_LINK_DEEP,
    ORIGINS,
)

# ----------------------------------
# Database
# ----------------------------------
Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ----------------------------------
# App init
# ----------------------------------
app = FastAPI(title="🎬 CineRev Backend (Letterboxd Clone)")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------------
# Health check
# ----------------------------------
@app.get("/")
def home():
    return {"message": "🎬 CineRev backend running successfully!"}

# ----------------------------------
# AUTH
# ----------------------------------
@app.post("/signup")
def signup(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if not re.match(r"[^@]+@[^@]+\.[^@]+", user.email):
        raise HTTPException(status_code=400, detail="Invalid email format")

    existing = db.query(models.User).filter(models.User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = crud.create_user(db, user.name, user.email, user.password)
    return {
        "message": "User created successfully",
        "user_id": new_user.id,
    }


@app.post("/login")
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    db_user = crud.authenticate_user(db, user.email, user.password)
    if not db_user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    access_token = create_access_token(
        data={"sub": str(db_user.id)}
    )

    return {
        "status": "success",
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": db_user.id,
        "email": db_user.email,
    }

# ----------------------------------
# REVIEWS (Protected)
# ----------------------------------
@app.post("/review")
def add_review(
    review: schemas.ReviewCreate,
    user_id: str = Depends(verify_token),
    db: Session = Depends(get_db),
):
    new_review = crud.add_review(
        db,
        int(user_id),
        review.movie_id,
        review.rating,
        review.review_text,
    )
    return {
        "message": "Review added successfully",
        "review_id": new_review.id,
    }

# ----------------------------------
# PASSWORD RESET
# ----------------------------------
def send_reset_email(to_email: str, reset_token: str):
    web_link = f"{RESET_LINK_HTTP}{reset_token}"
    deep_link = f"{RESET_LINK_DEEP}{reset_token}"

    subject = "🔐 CineRev Password Reset"
    body = f"""
    <html>
      <body>
        <h2>🔐 CineRev Password Reset</h2>
        <p>Click below to reset your password:</p>
        <a href="{web_link}">Reset Password</a>
        <p>If not opened, use:</p>
        <a href="{deep_link}">{deep_link}</a>
      </body>
    </html>
    """

    try:
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart

        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = GMAIL_USER
        msg["To"] = to_email
        msg.attach(MIMEText(body, "html"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
            smtp.login(GMAIL_USER, GMAIL_APP_PASSWORD)
            smtp.send_message(msg)
    except Exception as e:
        print("❌ Email error:", e)


@app.post("/forgot-password")
def forgot_password(email: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    expire = datetime.utcnow() + timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": str(user.id), "exp": expire}

    reset_token = __import__("jose").jwt.encode(
        payload, SECRET_KEY, algorithm=ALGORITHM
    )

    send_reset_email(user.email, reset_token)
    return {"message": "Password reset email sent successfully"}


@app.post("/reset-password")
def reset_password(
    token: str = Form(...),
    new_password: str = Form(...),
    db: Session = Depends(get_db),
):
    try:
        payload = __import__("jose").jwt.decode(
            token, SECRET_KEY, algorithms=[ALGORITHM]
        )
        user_id = int(payload.get("sub"))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password_hash = get_password_hash(new_password)
    db.commit()
    return {"message": "Password reset successful ✅"}

# ----------------------------------
# ROUTERS
# ----------------------------------
app.include_router(movies_router, prefix="/movies", tags=["Movies"])
app.include_router(reviews_router, prefix="/reviews", tags=["Reviews"])
app.include_router(events_router, prefix="/events", tags=["Events"])
app.include_router(activity_router, prefix="/activity", tags=["Activity"])
app.include_router(lists_router, prefix="/lists", tags=["Lists & Watchlist"])

app.include_router(recommendations.router)
app.include_router(recommendation_seed.router)
app.include_router(google_auth_router)
app.include_router(ai_recommend.router)