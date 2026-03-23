from fastapi import APIRouter
from app.db.mongo import users_col, past_papers_col, short_notes_col, global_challenges_col, friend_challenges_col

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/stats")
async def get_admin_stats():
    try:
        users_count = await users_col.count_documents({})
    except:
        users_count = 0
        
    try:
        papers_count = await past_papers_col.count_documents({})
    except:
        papers_count = 0
        
    try:
        notes_count = await short_notes_col.count_documents({})
    except:
        notes_count = 0
        
    try:
        global_ch_count = await global_challenges_col.count_documents({})
    except:
        global_ch_count = 0
        
    try:
        friend_ch_count = await friend_challenges_col.count_documents({})
    except:
        friend_ch_count = 0
        
    return {
        "users": users_count,
        "papers": papers_count,
        "notes": notes_count,
        "challenges": global_ch_count + friend_ch_count
    }

@router.get("/short_notes")
async def get_all_short_notes():
    try:
        from fastapi import HTTPException
        cursor1 = short_notes_col.find({})
        notes1 = await cursor1.to_list(length=1000)
        
        from app.db.mongo import predefined_notes_col
        cursor2 = predefined_notes_col.find({})
        notes2 = await cursor2.to_list(length=1000)
        
        notes = notes1 + notes2
        # Sort notes loosely by date strings if possible or just return them
        for note in notes:
            if "_id" in note:
                note["_id"] = str(note["_id"])
        return notes
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/users")
async def get_all_users():
    try:
        from fastapi import HTTPException
        cursor = users_col.find({}).sort("created_at", -1)
        users = await cursor.to_list(length=1000)
        result = []
        for u in users:
            result.append({
                "user_id": u.get("user_id"),
                "email": u.get("email", "Unknown"),
                "total_xp": u.get("total_xp", 0),
                "is_blocked": u.get("is_blocked", False),
                "created_at": u.get("created_at")
            })
        return result
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=str(e))

from pydantic import BaseModel
class UserStatusUpdate(BaseModel):
    is_blocked: bool

@router.put("/users/{user_id}/status")
async def update_user_status(user_id: str, status: UserStatusUpdate):
    try:
        from fastapi import HTTPException
        result = await users_col.update_one(
            {"user_id": user_id},
            {"$set": {"is_blocked": status.is_blocked}}
        )
        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="User not found")
        return {"success": True, "is_blocked": status.is_blocked}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=str(e))
