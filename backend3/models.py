from sqlalchemy import (
    Column, Integer, String, Text,
    ForeignKey, BigInteger, DateTime
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
from datetime import datetime



# =========================
# User
# =========================
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    google_id = Column(String, unique=True, nullable=True)  # ✅ new column

    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")
    lists = relationship("UserList", back_populates="user", cascade="all, delete-orphan")
    watchlist = relationship("Watchlist", back_populates="user", cascade="all, delete-orphan")
    events = relationship("Event", back_populates="user", cascade="all, delete-orphan")


# =========================
# Movie
# =========================
class Movie(Base):
    __tablename__ = "movies"

    tmdb_id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    poster_path = Column(String)
    tmdb_popularity = Column(Integer)

    genres = relationship("MovieGenre", back_populates="movie", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="movie")
    watchlists = relationship("Watchlist", back_populates="movie")


# =========================
# Review  ✅ FIXED
# =========================
class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    movie_id = Column(Integer, ForeignKey("movies.tmdb_id"), nullable=False)

    rating = Column(Integer, nullable=False)
    review_text = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="reviews")
    movie = relationship("Movie", back_populates="reviews")



# =========================
# MovieGenre
# =========================
class MovieGenre(Base):
    __tablename__ = "movie_genres"

    id = Column(Integer, primary_key=True)
    tmdb_id = Column(BigInteger, ForeignKey("movies.tmdb_id"), nullable=False)
    genre = Column(String, nullable=False)

    movie = relationship("Movie", back_populates="genres")


# =========================
# Event
# =========================
class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    tmdb_id = Column(Integer, nullable=False)
    event_type = Column(String, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="events")


# =========================
# UserList
# =========================
class UserList(Base):
    __tablename__ = "user_lists"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(Text)

    user = relationship("User", back_populates="lists")
    movies = relationship(
        "ListMovie",
        back_populates="list",
        cascade="all, delete-orphan"
    )


# =========================
# ListMovie
# =========================
class ListMovie(Base):
    __tablename__ = "list_movies"

    id = Column(Integer, primary_key=True, index=True)
    list_id = Column(Integer, ForeignKey("user_lists.id"), nullable=False)
    movie_tmdb_id = Column(BigInteger, ForeignKey("movies.tmdb_id"), nullable=False)

    list = relationship("UserList", back_populates="movies")
    movie = relationship("Movie")


# =========================
# Watchlist
# =========================
class Watchlist(Base):
    __tablename__ = "watchlist"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    movie_id = Column(Integer, ForeignKey("movies.tmdb_id"), nullable=False)

    user = relationship("User", back_populates="watchlist")
    movie = relationship("Movie", back_populates="watchlists")

