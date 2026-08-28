import os
from motor.motor_asyncio import AsyncIOMotorClient

import certifi

# MongoDB connection settings
MONGO_URL = os.environ.get("MONGODB_URL")
DB_NAME = os.environ.get("MONGODB_DB_NAME", "r26_se_031")

client = None
db = None
knowledge_states_collection = None
adaptive_decisions_collection = None

async def connect_to_mongo():
    global client, db, knowledge_states_collection, adaptive_decisions_collection
    if not MONGO_URL:
        raise ValueError("MONGODB_URL environment variable is not set!")
    client = AsyncIOMotorClient(MONGO_URL, tlsCAFile=certifi.where())
    db = client[DB_NAME]
    knowledge_states_collection = db["knowledge_states"]
    adaptive_decisions_collection = db["adaptive_decisions"]
    print("Connected to MongoDB Cloud (adaptive-tutoring-v1)")

async def close_mongo_connection():
    global client
    if client:
        client.close()
        print("Closed MongoDB connection (adaptive-tutoring-v1)")
