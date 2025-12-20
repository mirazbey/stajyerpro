"""Firestore durumunu kontrol et"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

print('=== SUBJECTS ===')
subjects = list(db.collection('subjects').stream())
for s in subjects[:5]:
    data = s.to_dict()
    print(f"  {s.id}: {data.get('name')} (isActive={data.get('isActive')})")
print(f'\nToplam subject: {len(subjects)}')

print('\n=== TOPICS ===')
topics = list(db.collection('topics').stream())
for t in topics[:10]:
    data = t.to_dict()
    parent = 'ROOT' if data.get('parentId') is None else data.get('parentId')[:8]
    name = data.get('name', 'N/A')[:30]
    print(f"  {t.id[:8]}: {name:30} | parent={parent} | active={data.get('isActive')}")
print(f'\nToplam topic: {len(topics)}')

# Anayasa Hukuku konuları
print('\n=== ANAYASA HUKUKU KONULARI ===')
anayasa = None
for s in subjects:
    if s.to_dict().get('name') == 'Anayasa Hukuku':
        anayasa = s.id
        break

if anayasa:
    print(f'Anayasa Hukuku ID: {anayasa}')
    anayasa_topics = [t for t in topics if t.to_dict().get('subjectId') == anayasa]
    print(f'Bu derse ait {len(anayasa_topics)} konu var')
    for t in anayasa_topics[:5]:
        data = t.to_dict()
        parent = 'ROOT' if data.get('parentId') is None else 'CHILD'
        print(f"  - {data.get('name')} ({parent})")
