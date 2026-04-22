from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import Review, Event

router = APIRouter()

@router.get("/user/{user_id}")
def get_user_activity(user_id: int, db: Session = Depends(get_db)):

    reviews = db.query(Review).filter(Review.user_id == user_id).all()

    likes = db.query(Event).filter(
        Event.user_id == user_id, 
        Event.event_type == "like"
    ).all()

    ratings = db.query(Event).filter(
        Event.user_id == user_id, 
        Event.event_type == "rating"
    ).all()

    watchlist = db.query(Event).filter(
        Event.user_id == user_id, 
        Event.event_type == "watchlist"
    ).all()

    return {
        "reviews": reviews,
        "likes": likes,
        "ratings": ratings,
        "watchlist": watchlist
    }
