import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os

# Initialize Firebase Admin
cred = credentials.Certificate('service-account.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

def inspect_topics():
    # 1. List all subjects to find the correct one
    subjects_ref = db.collection('subjects')
    results = subjects_ref.stream()
    
    subject_id = None
    print("--- ALL SUBJECTS ---")
    for doc in results:
        name = doc.to_dict().get('name', 'Unknown')
        print(f"Subject: {name} (ID: {doc.id})")
        if 'avukat' in name.lower():
            subject_id = doc.id
            print(f"*** MATCH FOUND: {name} ***")
            
    if not subject_id:
        print("Subject matching 'avukat' not found.")
        return

    # 2. List Topics
    topics_ref = db.collection('topics')
    query = topics_ref.where('subjectId', '==', subject_id)
    results = query.stream()
    
    print("\n--- ACTIVE TOPICS ---")
    count = 0
    for doc in results:
        data = doc.to_dict()
        if data.get('isActive') == True:
            print(f"ID: {doc.id}")
            print(f"Name: {data.get('name')}")
            print(f"Active: {data.get('isActive')}")
            print(f"QuestionCount: {data.get('questionCount')}")
            print("-" * 20)
            count += 1
        
    print(f"Total Active Topics: {count}")

if __name__ == '__main__':
    inspect_topics()
