import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv
import certifi

# Load environment variables
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("DB_NAME", "brainex")

async def setup_indexes():
    print(f"Connecting to MongoDB at {MONGO_URI}...")
    client = AsyncIOMotorClient(MONGO_URI, tlsCAFile=certifi.where())
    db = client[DB_NAME]
    users_col = db["users"]

    print("Creating unique index on 'email' field...")
    try:
        # Create a unique index on the email field
        # sparse=True allows multiple documents to have no email field, 
        # but if they have one, it must be unique.
        result = await users_col.create_index("email", unique=True, sparse=True)
        print(f"Index created: {result}")
    except Exception as e:
        print(f"Error creating index: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    asyncio.run(setup_indexes())
