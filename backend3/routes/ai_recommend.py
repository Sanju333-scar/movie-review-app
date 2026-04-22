# routes/ai_recommend.py

from fastapi import APIRouter
import requests
import os
import json
import re
from dotenv import load_dotenv
from google import genai   # ✅ NEW SDK

# ✅ LOAD ENV
load_dotenv()

router = APIRouter(prefix="/ai", tags=["AI Recommendation"])

# ✅ DEBUG
print("🔑 GEMINI KEY:", os.getenv("GEMINI_API_KEY"))
print("🔑 TMDB KEY:", os.getenv("TMDB_API_KEY"))

# ✅ NEW CLIENT
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

TMDB_API_KEY = os.getenv("TMDB_API_KEY")


@router.get("/recommend/{movie_id}")
def ai_recommend(movie_id: int):
    try:
        # 🎬 TMDB FETCH
        url = f"https://api.themoviedb.org/3/movie/{movie_id}?api_key={TMDB_API_KEY}&append_to_response=credits"
        res = requests.get(url, timeout=10).json()

        title = res.get("title", "")
        genres = [g["name"] for g in res.get("genres", [])]
        cast = [c["name"] for c in res.get("credits", {}).get("cast", [])[:5]]

        # 🤖 PROMPT
        prompt = f"""
        Recommend 10 movies similar to:
        Title: {title}
        Genres: {genres}
        Cast: {cast}

        STRICT RULE:
        Return ONLY JSON array.
        Example:
        ["Inception", "Interstellar"]
        """

        # 🤖 NEW GEMINI CALL
        response = client.models.generate_content(
            model="gemini-pro",   # ✅ works in NEW SDK
            contents=prompt
        )

        text = response.text
        print("🤖 GEMINI RAW:", text)

        # ✅ JSON EXTRACT
        match = re.search(r"\[.*\]", text, re.DOTALL)

        if not match:
            return []

        movie_names = json.loads(match.group(0))

        # 🎯 TMDB SEARCH
        results = []

        for name in movie_names:
            search_url = f"https://api.themoviedb.org/3/search/movie?api_key={TMDB_API_KEY}&query={name}"
            search_res = requests.get(search_url, timeout=10).json()

            if search_res.get("results"):
                movie = search_res["results"][0]

                results.append({
                    "tmdb_id": movie.get("id"),
                    "title": movie.get("title"),
                    "poster_path": movie.get("poster_path")
                })

        return results

    except Exception as e:
        print("🔥 ERROR:", str(e))
        return {"error": str(e)}