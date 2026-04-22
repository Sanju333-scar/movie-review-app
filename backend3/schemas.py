from pydantic import BaseModel
from typing import Optional, List
from datetime import date  # correct type for release_date

# ------------------------------
# USER AUTH SCHEMAS
# ------------------------------
class UserCreate(BaseModel):
    name: str
    email: str
    password: str


class UserLogin(BaseModel):
    email: str
    password: str


# ------------------------------
# REVIEW SCHEMA
# ------------------------------
class ReviewCreate(BaseModel):
    user_id: int
    movie_id: int
    rating: float
    review_text: Optional[str] = None



# ------------------------------
# EVENT LOG SCHEMA
# ------------------------------
class EventCreate(BaseModel):
    user_id: int
    tmdb_id: int
    event_type: str
    value: float | None = None





# ------------------------------
# MOVIE GENRE SCHEMA
# ------------------------------
class GenreCreate(BaseModel):
    genre: str


# ------------------------------
# MOVIE CREATE SCHEMA
# ------------------------------
class MovieCreate(BaseModel):
    tmdb_id: int
    title: str
    overview: str | None = None
    release_date: date | None = None
    poster_path: str | None = None          # REQUIRED
    tmdb_popularity: float | None = None
    genres: list[GenreCreate] = [] 


# ------------------------------
# MOVIE RESPONSE SCHEMA
# ------------------------------
class MovieResponse(BaseModel):
    tmdb_id: int
    title: str
    overview: Optional[str] = None
    poster_path: Optional[str] = None
    release_date: Optional[date] = None

    model_config = {"from_attributes": True}

class UserListCreate(BaseModel):
    name: str
    description: str | None = None

