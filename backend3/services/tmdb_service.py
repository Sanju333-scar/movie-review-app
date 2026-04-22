import requests
from typing import Optional

TMDB_API_KEY = "1c276cf829ca49b3f730a6bbb4c48635"   # ← PUT YOUR REAL KEY HERE
TMDB_BASE_URL = "https://api.themoviedb.org/3"

HEADERS = {
    "Accept": "application/json",
    "User-Agent": "MovieListApp/1.0"
}

def fetch_movie_from_tmdb(tmdb_id: int) -> Optional[dict]:
    try:
        url = f"{TMDB_BASE_URL}/movie/{tmdb_id}"

        response = requests.get(
            url,
            params={
                "api_key": TMDB_API_KEY,
                "language": "en-US",
            },
            headers=HEADERS,
            timeout=10,
        )

        if response.status_code != 200:
            print("TMDB ERROR:", response.status_code, response.text)
            return None

        data = response.json()

        return {
            "tmdb_id": tmdb_id,
            "title": data.get("title") or "Unknown title",
            "poster_path": data.get("poster_path"),
            "tmdb_popularity": data.get("popularity", 0),
        }

    except requests.RequestException as e:
        print("TMDB CONNECTION ERROR:", e)
        return None
