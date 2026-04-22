import pandas as pd
from mlxtend.frequent_patterns import apriori, association_rules
from sqlalchemy.orm import Session
import models
from sqlalchemy.sql import func
import random

# --------------------------------------------------------
# Convert ALL user lists into transactions (Training Data)
# --------------------------------------------------------
def get_transactions(db: Session):

    data = db.query(
        models.UserList.user_id,
        models.ListMovie.movie_tmdb_id
    ).join(
        models.ListMovie,
        models.UserList.id == models.ListMovie.list_id
    ).all()

    transactions_dict = {}

    for user_id, movie_id in data:
        if user_id not in transactions_dict:
            transactions_dict[user_id] = []

        transactions_dict[user_id].append(movie_id)

    return list(transactions_dict.values())


# --------------------------------------------------------
# Get movies from user's "Recommendation Seed" list
# --------------------------------------------------------
def get_user_seed_movies(db: Session, user_id: int):

    seed_list = db.query(models.UserList).filter(
        models.UserList.user_id == user_id,
        models.UserList.name == "Recommendation Seed"
    ).first()

    if not seed_list:
        return []

    movies = db.query(models.ListMovie.movie_tmdb_id).filter(
        models.ListMovie.list_id == seed_list.id
    ).all()

    return [m[0] for m in movies]


# --------------------------------------------------------
# MAIN RECOMMENDATION FUNCTION
# --------------------------------------------------------
def generate_recommendations(db: Session, user_id: int):

    user_movies = get_user_seed_movies(db, user_id)

    # 🔥 Popular fallback
    popular_movies = db.query(models.Movie)\
        .order_by(models.Movie.tmdb_popularity.desc())\
        .limit(20)\
        .all()

    # Cold start
    if not user_movies:
        return popular_movies[:10]

    transactions = get_transactions(db)

    if not transactions:
        return popular_movies[:10]

    df = pd.DataFrame(transactions)

    if df.empty:
        return popular_movies[:10]

    # One-hot encode
    df = pd.get_dummies(df.stack()).groupby(level=0).sum()
    df = df > 0

    frequent_itemsets = apriori(
        df,
        min_support=0.05,
        use_colnames=True
    )

    if frequent_itemsets.empty:
        return popular_movies[:10]

    rules = association_rules(
        frequent_itemsets,
        metric="confidence",
        min_threshold=0.1
    )

    recommendations = set()

    for _, row in rules.iterrows():
        if set(row["antecedents"]) & set(user_movies):
            recommendations.update(row["consequents"])

    recommendations = recommendations.difference(user_movies)

    recommended_movies = []

    if recommendations:
        recommended_movies = db.query(models.Movie).filter(
            models.Movie.tmdb_id.in_(recommendations)
        ).all()

    # Convert to dictionary (avoid duplicates)
    final_movies = {m.tmdb_id: m for m in recommended_movies}

    # 🔥 RANDOM fallback instead of popularity
    if len(final_movies) < 10:
        additional_movies = db.query(models.Movie)\
            .filter(~models.Movie.tmdb_id.in_(user_movies))\
            .filter(~models.Movie.tmdb_id.in_(final_movies.keys()))\
            .order_by(func.random())\
            .limit(20)\
            .all()

        for movie in additional_movies:
            final_movies[movie.tmdb_id] = movie
            if len(final_movies) >= 10:
                break

    final_list = list(final_movies.values())
    random.shuffle(final_list)

    return final_list[:10]