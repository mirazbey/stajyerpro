"""Check topic descriptions and create topic_lessons from them"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Eser Sözleşmesi'nin full description'ını görelim
topics = list(db.collection('topics').where('subjectId', '==', 'borclar_hukuku').stream())

for t in topics:
    data = t.to_dict()
    if 'Eser' in data.get('name', ''):
        print(f"=== {data.get('name')} ===")
        print(f"Topic ID: {t.id}")
        print(f"Description length: {len(data.get('description', ''))}")
        print(f"\nFull Description:")
        print(data.get('description', 'YOK'))
        print('\n' + '='*80)
        break
