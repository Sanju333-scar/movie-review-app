from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from services.recommendation_service import generate_recommendations

router = APIRouter(
    prefix="/recommendations",
    tags=["Recommendations"]
)


@router.get("/{user_id}")
def recommend_movies(
    user_id: int,
    db: Session = Depends(get_db),
):
    """
    Generate recommendations for a user.
    Automatically reads movies from 'Recommendation Seed' list.
    """

    movies = generate_recommendations(db, user_id)

    # ✅ Handle empty case safely
    if not movies:
        return {
            "status": True,
            "recommendations": [],
            "message": "No recommendations found. Add movies to seed list."
        }

    return {
    "status": True,
    "recommendations": [
        {
            "tmdb_id": m.tmdb_id,
            "title": m.title,
            "poster_path": f"https://image.tmdb.org/t/p/w500{m.poster_path}"
            if m.poster_path else None,
            "tmdb_popularity": m.tmdb_popularity,
        }
        for m in movies
    ]
}