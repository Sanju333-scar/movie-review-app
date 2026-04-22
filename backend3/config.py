import os
from dotenv import load_dotenv

load_dotenv()

# --- Backend Host Config ---
BACKEND_HOST = os.getenv("BACKEND_HOST", "10.59.243.252")
BACKEND_PORT = os.getenv("BACKEND_PORT", "8000")

# --- Security ---
SECRET_KEY = os.getenv("SECRET_KEY", "supersecretkey123")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
RESET_TOKEN_EXPIRE_MINUTES = int(os.getenv("RESET_TOKEN_EXPIRE_MINUTES", 30))

# --- Gmail Config ---
GMAIL_USER = os.getenv("GMAIL_USER", "amazonweb1000@gmail.com")
GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD", "awplgkwunjffkqti")

# --- CORS ---
ORIGINS = [
    "*",
    "http://localhost",
    "http://10.59.243.252:8000",
    f"http://{BACKEND_HOST}:{BACKEND_PORT}",
]

# --- Reset Links ---
RESET_LINK_DEEP = "cinirev://reset-password?token="
RESET_LINK_HTTP = "http://10.59.243.252:8000/reset-password?token="  # your actual IP here

# --- TMDB API ---
TMDB_API_KEY = os.getenv("TMDB_API_KEY", "")
