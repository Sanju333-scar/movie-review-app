from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Event, Review, User
from schemas import EventCreate

router = APIRouter()

VALID_EVENTS = ["view", "like", "rate", "review", "watchlist"]

@router.post("/add")
def add_event(event: EventCreate, db: Session = Depends(get_db)):

    if event.event_type not in VALID_EVENTS:
        raise HTTPException(status_code=400, detail="Invalid event_type")

    new_event = Event(
        user_id=event.user_id,
        tmdb_id=event.tmdb_id,
        event_type=event.event_type,
    )

    db.add(new_event)
    db.commit()
    db.refresh(new_event)

    return {"status": "success", "event": event.event_type}


# GET USER ACTIVITY FOR A MOVIE (Fixed)
@router.get("/user/{user_id}/movie/{tmdb_id}")
def get_user_movie_activity(user_id: int, tmdb_id: int, db: Session = Depends(get_db)):

    # Fetch events
    events = db.query(Event).filter(
        Event.user_id == user_id,
        Event.tmdb_id == tmdb_id
    ).all()

    likes = [e for e in events if e.event_type == "like"]
    watchlist = [e for e in events if e.event_type == "watchlist"]
    rated = [e for e in events if e.event_type == "rate"]

    # Fetch user’s personal review + rating
    my_review = db.query(Review).filter(
        Review.user_id == user_id,
        Review.movie_id == tmdb_id
    ).first()

    return {
        "liked": len(likes) > 0,
        "watchlisted": len(watchlist) > 0,
        "rated": len(rated) > 0,
        "my_review": {
            "id": my_review.id,
            "rating": my_review.rating,
            "review_text": my_review.review_text,
            "created_at": my_review.created_at,
            "username": my_review.user.name
        } if my_review else None
    }
