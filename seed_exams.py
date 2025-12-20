import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from pathlib import Path
import datetime

# Configuration
BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

def seed_exams():
    print("Seeding Exams...")
    
    exams_ref = db.collection('exams')
    
    # Check if any exam exists
    docs = list(exams_ref.limit(1).stream())
    if docs:
        print("Exams already exist. Skipping.")
        return

    # Create a default HMGS Exam
    exam_data = {
        'name': 'HMGS Genel Deneme 1',
        'description': 'Gerçek sınav formatında, 120 soruluk tam kapsamlı deneme sınavı.',
        'durationMinutes': 130,
        'totalQuestions': 120,
        'isActive': True,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP
    }
    
    exams_ref.add(exam_data)
    print("Created 'HMGS Genel Deneme 1'")

if __name__ == '__main__':
    seed_exams()
