from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

import models, schemas
from database import get_db
from auth import verify_token
from services.tmdb_service import fetch_movie_from_tmdb

router = APIRouter()

# -------------------------
# Create List
# -------------------------
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_list(
    data: schemas.UserListCreate,
    user_id: str = Depends(verify_token),
    db: Session = Depends(get_db),
):
    new_list = models.UserList(
        user_id=int(user_id),
        name=data.name,
        description=data.description,
    )
    db.add(new_list)
    db.commit()
    db.refresh(new_list)

    return {"list_id": new_list.id}


# -------------------------
# Get User Lists WITH Movies
# -------------------------
@router.get("/", status_code=200)
def get_user_lists(
    user_id: str = Depends(verify_token),
    db: Session = Depends(get_db),
):
    lists = (
        db.query(models.UserList)
        .filter(models.UserList.user_id == int(user_id))
        .all()
    )

    result = []

    for user_list in lists:
        movies = (
            db.query(models.Movie)
            .join(models.ListMovie,
                  models.Movie.tmdb_id == models.ListMovie.movie_tmdb_id)
            .filter(models.ListMovie.list_id == user_list.id)
            .all()
        )

        result.append({
            "id": user_list.id,
            "name": user_list.name,
            "description": user_list.description,
            "movies": [
                {
                    "tmdb_id": m.tmdb_id,
                    "title": m.title,
                    "poster_path": m.poster_path,
                }
                for m in movies
            ]
        })

    return result


# -------------------------
# Add Movie to List (🔥 FIXED)
# -------------------------
@router.post("/{list_id}/movies/{tmdb_id}", status_code=201)
def add_movie_to_list(
    list_id: int,
    tmdb_id: int,
    user_id: str = Depends(verify_token),
    db: Session = Depends(get_db),
):
    user_list = db.query(models.UserList).filter(
        models.UserList.id == list_id,
        models.UserList.user_id == int(user_id),
    ).first()

    if not user_list:
        raise HTTPException(status_code=404, detail="List not found")

    # 1️⃣ Check if movie exists locally
    movie = db.query(models.Movie).filter(
        models.Movie.tmdb_id == tmdb_id
    ).first()

    # 2️⃣ If not → try TMDB (OPTIONAL)
    if not movie:
        tmdb_data = fetch_movie_from_tmdb(tmdb_id)

        if tmdb_data:
            movie = models.Movie(**tmdb_data)
        else:
            # ✅ ALLOW ANY MOVIE (NO FAILURE)
            movie = models.Movie(
                tmdb_id=tmdb_id,
                title="Unknown title",
                poster_path=None,
                tmdb_popularity=0,
            )

        db.add(movie)
        db.commit()
        db.refresh(movie)

    # 3️⃣ Prevent duplicate entry
    exists = db.query(models.ListMovie).filter(
        models.ListMovie.list_id == list_id,
        models.ListMovie.movie_tmdb_id == tmdb_id,
    ).first()

    if exists:
        return {"message": "Movie already in list"}

    # 4️⃣ Add to list
    db.add(models.ListMovie(
        list_id=list_id,
        movie_tmdb_id=tmdb_id,
    ))
    db.commit()

    return {"message": "Movie added to list"}


# -------------------------
# Get Single List with Movies
# -------------------------
@router.get("/{list_id}", status_code=200)
def get_list(
    list_id: int,
    user_id: str = Depends(verify_token),
    db: Session = Depends(get_db),
):
    user_list = db.query(models.UserList).filter(
        models.UserList.id == list_id,
        models.UserList.user_id == int(user_id),
    ).first()

    if not user_list:
        raise HTTPException(status_code=404, detail="List not found")

    movies = (
        db.query(models.Movie)
        .join(models.ListMovie,
              models.Movie.tmdb_id == models.ListMovie.movie_tmdb_id)
        .filter(models.ListMovie.list_id == list_id)
        .all()
    )

    return {
        "id": user_list.id,
        "name": user_list.name,
        "description": user_list.description,
        "movies": [
            {
                "tmdb_id": m.tmdb_id,
                "title": m.title,
                "poster_path": m.poster_path,
            }
            for m in movies
        ],
    }
