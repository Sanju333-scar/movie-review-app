from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Movie, MovieGenre
from schemas import MovieCreate   # <-- use main schema

router = APIRouter(tags=["Movies"])


@router.post("/")
def create_movie(movie: MovieCreate, db: Session = Depends(get_db)):

    existing = db.query(Movie).filter(Movie.tmdb_id == movie.tmdb_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Movie already exists")

    db_movie = Movie(
        tmdb_id=movie.tmdb_id,
        title=movie.title,
        poster_path=movie.poster_path,
        tmdb_popularity=movie.tmdb_popularity,
    )
    db.add(db_movie)
    db.commit()
    db.refresh(db_movie)

    # save genres
    for g in movie.genres:
        db.add(MovieGenre(tmdb_id=db_movie.tmdb_id, genre=g.genre))

    db.commit()

    return {"message": "Movie + genres saved"}
