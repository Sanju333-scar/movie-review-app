from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Review, User, Movie
from datetime import datetime
from schemas import ReviewCreate
from utils.event_logger import log_event

router = APIRouter(tags=["Reviews"])


# --- CREATE REVIEW ---
@router.post("/")
def create_review(review: ReviewCreate, db: Session = Depends(get_db)):

    # ✅ Check user
    user = db.query(User).filter(User.id == review.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # ✅ Check movie using TMDB ID
    movie = db.query(Movie).filter(Movie.tmdb_id == review.movie_id).first()
    if not movie:
        raise HTTPException(status_code=404, detail="Movie not found")

    # ✅ Check duplicate
    existing_review = db.query(Review).filter(
        Review.user_id == review.user_id,
        Review.movie_id == review.movie_id
    ).first()

    if existing_review:
        existing_review.rating = review.rating
        existing_review.review_text = review.review_text
        existing_review.created_at = datetime.utcnow()
        db.commit()
        db.refresh(existing_review)

        return {
            "message": "Review updated",
            "review_id": existing_review.id
        }

    # ✅ Create review (IMPORTANT FIX HERE)
    new_review = Review(
        user_id=review.user_id,
        movie_id=review.movie_id,  # ✅ ALWAYS TMDB ID
        rating=review.rating,
        review_text=review.review_text,
        created_at=datetime.utcnow(),
    )

    db.add(new_review)
    db.commit()
    db.refresh(new_review)

    # ✅ Log event
    log_event(db, review.user_id, review.movie_id, "review")

    return {
        "message": "Review saved",
        "review_id": new_review.id
    }


# --- GET REVIEWS ---
@router.get("/movie/{movie_id}")
def get_movie_reviews(movie_id: int, db: Session = Depends(get_db)):

    reviews = db.query(Review).filter(
        Review.movie_id == movie_id
    ).order_by(Review.created_at.desc()).all()

    return {
        "reviews": [
            {
                "id": r.id,
                "user_id": r.user_id,
                "username": r.user.name,
                "rating": r.rating,
                "review_text": r.review_text,
                "created_at": r.created_at.isoformat()
            }
            for r in reviews
        ]
    }