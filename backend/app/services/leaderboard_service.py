from app.db.mongo import users_col


async def get_global_leaderboard(limit: int = 50) -> list[dict]:
    """
    Returns all users sorted by total_xp descending, with rank injected.
    Limit is applied after sorting so ranks are stable.
    """
    cursor = users_col.find(
        {},
        {"user_id": 1, "name": 1, "total_xp": 1, "profile_picture_base64": 1, "_id": 0},
    ).sort("total_xp", -1).limit(limit)

    results = []
    rank = 1
    async for doc in cursor:
        results.append(
            {
                "rank": rank,
                "user_id": doc.get("user_id", ""),
                "name": doc.get("name") or "Unnamed",
                "total_xp": doc.get("total_xp", 0),
                "profile_picture_base64": doc.get("profile_picture_base64"),
            }
        )
        rank += 1

    return results


async def get_my_rank(user_id: str) -> dict:
    """
    Returns the rank and XP of a specific user.
    Rank = number of users with strictly higher total_xp + 1.
    """
    user = await users_col.find_one({"user_id": user_id}, {"total_xp": 1, "_id": 0})
    if not user:
        return {"my_rank": None, "my_xp": 0}

    my_xp = user.get("total_xp", 0)
    higher_count = await users_col.count_documents({"total_xp": {"$gt": my_xp}})
    return {"my_rank": higher_count + 1, "my_xp": my_xp}
