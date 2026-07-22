from pymongo import MongoClient
import sys

client = MongoClient("mongodb://localhost:27017")
db = client.r26_se_031

students = list(db.students.find().limit(5))
print(f"Found {len(students)} students")
for s in students:
    print(f"Student: {s.get('username')}, parent_id: {s.get('parent_id')}, parent_id type: {type(s.get('parent_id'))}")
    print(f"ID: {s.get('_id')}")

