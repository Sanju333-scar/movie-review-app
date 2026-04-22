#Rule-Based Hybrid (Activity + Genres)

def calculate_score(user_actions, movie_genres, user_top_genres, popularity):
    score = 0

    # 1. User activity weights
    if user_actions.get("liked"):
        score += 20
    if user_actions.get("watchlisted"):
        score += 10
    if user_actions.get("rated"):
        score += user_actions["rated"] * 4

    # 2. Genre match scoring
    for g in movie_genres:
        if g in user_top_genres:
            score += 15

    # 3. Popularity weight
    score += (popularity or 0) * 0.3

    return score
