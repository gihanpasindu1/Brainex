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
