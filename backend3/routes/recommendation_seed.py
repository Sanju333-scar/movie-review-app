from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter(
    prefix="/seed",
    tags=["Recommendation Seed"]
)


# ✅ Request Body Model (BEST PRACTICE)
class SeedRequest(BaseModel):
    user_id: int
    tmdb_id: int


@router.post("/add")
def add_to_seed(data: SeedRequest, db: Session = Depends(get_db)):

    user_id = data.user_id
    tmdb_id = data.tmdb_id

    # 1️⃣ Check if seed list exists
    seed_list = db.query(models.UserList).filter(
        models.UserList.user_id == user_id,
        models.UserList.name == "Recommendation Seed"
    ).first()

    # 2️⃣ If not, create it
    if not seed_list:
        seed_list = models.UserList(
            user_id=user_id,
            name="Recommendation Seed",
            description="Auto-generated list for recommendations"
        )
        db.add(seed_list)
        db.commit()
        db.refresh(seed_list)

    # 3️⃣ Check if movie already exists
    existing = db.query(models.ListMovie).filter(
        models.ListMovie.list_id == seed_list.id,
        models.ListMovie.movie_tmdb_id == tmdb_id
    ).first()

    if existing:
        return {
            "status": False,
            "message": "Movie already in recommendation seed"
        }

    # 4️⃣ Add movie
    list_movie = models.ListMovie(
        list_id=seed_list.id,
        movie_tmdb_id=tmdb_id
    )

    db.add(list_movie)
    db.commit()

    return {
        "status": True,
        "message": "Movie added to recommendation seed"
    }