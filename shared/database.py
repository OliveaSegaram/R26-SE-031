import os
from motor.motor_asyncio import AsyncIOMotorClient

class Database:
    client: AsyncIOMotorClient = None

db_instance = Database()

async def connect_to_mongo():
    mongo_url = os.getenv("MONGODB_URL", "mongodb://127.0.0.1:27017")
    db_instance.client = AsyncIOMotorClient(mongo_url)
    print(f"Connected to MongoDB at {mongo_url}")

async def close_mongo_connection():
    if db_instance.client:
        db_instance.client.close()
        print("MongoDB connection closed.")

def get_db():
    db_name = os.getenv("MONGODB_DB_NAME", "r26_se_031")
    return db_instance.client[db_name]
