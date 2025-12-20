import os, sys, time, json, re
from pathlib import Path
from datetime import datetime
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore

BASE_DIR = Path.cwd()
OUTPUT_DIR = BASE_DIR / "generated_lessons"
OUTPUT_DIR.mkdir(exist_ok=True)

if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

API_KEY = "AIzaSyApIRbm-RF9dHQ_99duUH4QUz6_NNJz65E"
genai.configure(api_key=API_KEY)

print("Setup complete. Starting generation...")
print(f"Output: {OUTPUT_DIR}")

subjects = {s.id: s.to_dict().get("name") for s in db.collection("subjects").stream()}
all_topics = list(db.collection("topics").stream())
empty = [(t.id, t.to_dict()) for t in all_topics if len(t.to_dict().get("description", "").strip()) < 10]

print(f"Empty topics: {len(empty)}")

if input("Continue? (y/n): ").lower() != "y":
    sys.exit(0)

for idx, (tid, tdata) in enumerate(empty[:5], 1):
    print(f"\n[{idx}/5] {tdata.get('name')}")
    time.sleep(2)
    print("  OK (test mode)")

print("\nTest completed!")
