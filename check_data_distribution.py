import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from pathlib import Path
from collections import Counter

# Configuration
BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

def check_distribution():
    print("Checking Question Distribution...")
    
    questions = db.collection('questions').stream()
    subject_counts = Counter()
    total_questions = 0
    
    for q in questions:
        data = q.to_dict()
        subject_id = data.get('subjectId', 'UNKNOWN')
        subject_counts[subject_id] += 1
        total_questions += 1
        
    print(f"Total Questions: {total_questions}")
    print("\nQuestions per Subject:")
    for subject_id, count in subject_counts.most_common():
        # Get subject name
        subject_doc = db.collection('subjects').document(subject_id).get()
        subject_name = subject_doc.to_dict().get('name', subject_id) if subject_doc.exists else subject_id
        print(f"{subject_name} ({subject_id}): {count}")

if __name__ == '__main__':
    check_distribution()
