from sqlalchemy.orm import Session
from datetime import datetime
from passlib.context import CryptContext
from models import User
import models, schemas
from models import Event, Review, Movie
from services.recommendation_engine import calculate_score

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

#create user
def create_user(db: Session, name: str, email: str, password: str):
    existing_user = db.query(User).filter(User.email == email).first()
    if existing_user:
        raise Exception("Email already registered")

    hashed_password = pwd_context.hash(password)

    new_user = User(
        name=name,
        email=email,
        password_hash=hashed_password
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user
# ----------------------------------------------------
# ✅ Authenticate user (USES password_hash ONLY)
# ----------------------------------------------------
def authenticate_user(db: Session, email: str, password: str):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        return None

    if not pwd_context.verify(password, user.password_hash):
        return None

    return user


# ----------------------------------------------------
# ✅ Get or create movie (by tmdb_id)
# ----------------------------------------------------
def get_or_create_movie(db: Session, movie_data: dict):
    movie = db.query(Movie).filter(Movie.tmdb_id == movie_data["tmdb_id"]).first()
    if not movie:
        movie = Movie(**movie_data)
        db.add(movie)
        db.commit()
        db.refresh(movie)
    return movie


# ----------------------------------------------------
# ✅ Log user event
# ----------------------------------------------------
def log_event(db: Session, event: schemas.EventCreate):
    db_event = Event(
        user_id=event.user_id,
        tmdb_id=event.tmdb_id,
        event_type=event.event_type,
    )
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return {"message": "Event logged", "event_id": db_event.id}


# ----------------------------------------------------
# ✅ Create or update review (FIXED)
# ----------------------------------------------------
def create_review(db: Session, review: schemas.ReviewCreate):
    movie = db.query(Movie).filter(Movie.tmdb_id == review.movie_id).first()
    if not movie:
        raise ValueError("Movie not found")

    existing = db.query(Review).filter(
        Review.user_id == review.user_id,
        Review.movie_id == review.movie_id,
    ).first()

    if existing:
        existing.rating = review.rating
        existing.review_text = review.review_text
        existing.created_at = datetime.utcnow()
        db.commit()
        return existing

    new_review = Review(
        user_id=review.user_id,
        movie_id=review.movie_id,  # ✅ FIXED
        rating=review.rating,
        review_text=review.review_text,
    )

    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    return new_review

# ----------------------------------------------------
# ✅ Recommendations (FULLY FIXED)
# ----------------------------------------------------
def get_recommendations_for_user(db: Session, user_id: int):
    events = db.query(Event).filter(Event.user_id == user_id).all()
    user_actions = {}

    for e in events:
        user_actions.setdefault(e.tmdb_id, {})

        if e.event_type == "like":
            user_actions[e.tmdb_id]["liked"] = True

        elif e.event_type == "watchlist":
            user_actions[e.tmdb_id]["watchlisted"] = True

        elif e.event_type == "rate":
            rev = db.query(Review).filter(
                Review.user_id == user_id,
                Review.movie_id == e.tmdb_id
            ).first()

            if rev:
                user_actions[e.tmdb_id]["rated"] = rev.rating

    genre_count = {}

    for tmdb_id in user_actions:
        movie = db.query(Movie).filter(Movie.tmdb_id == tmdb_id).first()
        if not movie or not movie.genres:
            continue

        for g in movie.genres:
            genre_count[g.genre] = genre_count.get(g.genre, 0) + 1

    top_genres = sorted(genre_count, key=genre_count.get, reverse=True)[:4]

    results = []

    for movie in db.query(Movie).all():
        movie_genres = [g.genre for g in movie.genres] if movie.genres else []

        score = calculate_score(
            user_actions.get(movie.tmdb_id, {}),
            movie_genres,
            top_genres,
            movie.tmdb_popularity or 0
        )

        results.append({
            "movie_id": movie.tmdb_id,
            "title": movie.title,
            "poster_path": movie.poster_path,
            "score": score,
        })

    return sorted(results, key=lambda x: x["score"], reverse=True)

# ----------------------------------------------------
# ✅ Lists
# ----------------------------------------------------
def create_list(db: Session, user_id: int, name: str, description: str | None):
    new_list = models.UserList(
        user_id=user_id,
        name=name,
        description=description
    )
    db.add(new_list)
    db.commit()
    db.refresh(new_list)
    return new_list


def add_movie_to_list(db: Session, list_id: int, movie_tmdb_id: int):
    entry = models.ListMovie(
        list_id=list_id,
        movie_tmdb_id=movie_tmdb_id
    )
    db.add(entry)
    db.commit()
    return entry


# ----------------------------------------------------
# ✅ Watchlist (CORRECT — uses movie.id)
# ----------------------------------------------------
def add_to_watchlist(db: Session, user_id: int, movie_id: int):
    exists = db.query(models.Watchlist).filter_by(
        user_id=user_id,
        movie_id=movie_id
    ).first()

    if exists:
        return exists

    item = models.Watchlist(
        user_id=user_id,
        movie_id=movie_id
    )
    db.add(item)
    db.commit()
    return item
