from fastapi import FastAPI, Form, Depends, HTTPException
from sqlalchemy.orm import Session
from jose import jwt
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from fastapi.responses import HTMLResponse
from starlette.requests import Request

from database import get_db
from models import User
from config import (
    SECRET_KEY,
    ALGORITHM,
    GMAIL_USER,
    GMAIL_APP_PASSWORD,
    RESET_TOKEN_EXPIRE_MINUTES,
    BACKEND_HOST,
    BACKEND_PORT,
)

app = FastAPI(title="CineRev Password Reset Service")

# ✅ Dynamic link generation using config values
RESET_LINK_HTTP = f"http://{BACKEND_HOST}:{BACKEND_PORT}/reset-password?token="
RESET_LINK_DEEP = "cinirev://reset-password?token="


# --- Helper: Send Reset Email ---
def send_reset_email(to_email: str, token: str):
    deep_link = f"{RESET_LINK_DEEP}{token}"
    web_link = f"{RESET_LINK_HTTP}{token}"

    html = f"""
    <html>
      <body style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px;">
        <div style="background-color: #fff; padding: 20px; border-radius: 10px;">
          <h2>🔐 CineRev Password Reset</h2>
          <p>Hi CineRev user,</p>
          <p>You requested to reset your password.</p>

          <a href="{web_link}"
             style="display:inline-block;
                    background-color:#007bff;
                    color:#fff;
                    padding:10px 20px;
                    text-decoration:none;
                    border-radius:5px;">
             Reset Password
          </a>

          <p style="margin-top:20px;">If the button doesn’t work, copy and paste this link:</p>
          <p><a href="{web_link}">{web_link}</a></p>

          <hr>
          <p style="font-size:12px;color:#666;">If you didn't request this, please ignore this email.</p>
        </div>
      </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "🔐 CineRev Password Reset"
    msg["From"] = GMAIL_USER
    msg["To"] = to_email
    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(GMAIL_USER, GMAIL_APP_PASSWORD)
        smtp.send_message(msg)

    print(f"✅ Password reset email sent to {to_email}")


# --- Forgot Password Endpoint ---
@app.post("/forgot-password")
def forgot_password(email: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Generate JWT reset token
    token_data = {
        "sub": str(user.id),
        "exp": datetime.utcnow() + timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES),
    }
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

    # Send reset email
    send_reset_email(user.email, token)

    return {"message": "Password reset email sent successfully!"}


# --- Clickable Reset Link Page (browser fallback) ---
@app.get("/reset-password", response_class=HTMLResponse)
def reset_password_page(request: Request, token: str | None = None):
    if not token:
        return HTMLResponse("<h3>Invalid or missing token</h3>", status_code=400)

    deep_link = f"{RESET_LINK_DEEP}{token}"

    html = f"""
    <html>
      <head>
        <title>CineRev Redirect</title>
        <meta charset="utf-8">
        <script>
          window.onload = function() {{
            // Try to open app immediately
            window.location = "{deep_link}";
            // If blocked, show fallback button
            setTimeout(function() {{
              document.getElementById('fallback').style.display = 'block';
            }}, 1000);
          }};
        </script>
      </head>
      <body style="background:#111;color:white;text-align:center;font-family:Arial;padding-top:100px;">
        <h2>Opening CineRev App...</h2>
        <div id="fallback" style="display:none;">
          <p>If it doesn't open automatically, tap below:</p>
          <a href="{deep_link}" 
             style="background:#00C853;
                    color:#000;
                    padding:10px 20px;
                    border-radius:8px;
                    text-decoration:none;">
             Open in CineRev
          </a>
        </div>
      </body>
    </html>
    """
    return HTMLResponse(html)
