"""
Firestore Temizlik Script'i
- Konusu olmayan subject'leri isActive=false yap
"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

# Configuration
BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

def cleanup_empty_subjects():
    print('=== ANALIZ ===')

    # 1. Tüm subjects
    subjects = {s.id: s.to_dict() for s in db.collection('subjects').stream()}
    print(f'Toplam subject: {len(subjects)}')

    # 2. Topics'lerin hangi subject'e bağlı olduğunu bul
    topics = list(db.collection('topics').stream())
    topic_subjects = set(t.to_dict().get('subjectId') for t in topics)
    print(f'Topic içeren subject sayısı: {len(topic_subjects)}')

    # 3. Topic'i olmayan subjects
    empty_subjects = []
    for sid, data in subjects.items():
        if sid not in topic_subjects:
            empty_subjects.append((sid, data.get('name')))

    print(f'\n=== TOPIC İÇERMEYEN SUBJECTS ({len(empty_subjects)}) ===')
    for sid, name in empty_subjects:
        print(f'  {sid}: {name}')

    # 4. Topic içerenleri listele
    print(f'\n=== TOPIC İÇEREN SUBJECTS ({len(topic_subjects)}) ===')
    for sid in sorted(topic_subjects):
        name = subjects.get(sid, {}).get('name', '???')
        count = sum(1 for t in topics if t.to_dict().get('subjectId') == sid)
        print(f'  {sid}: {name} ({count} topic)')

    # 5. Temizlik yap
    print('\n=== TEMİZLİK ===')
    for sid, name in empty_subjects:
        print(f'  Deactivating: {name}')
        db.collection('subjects').document(sid).update({'isActive': False})

    print(f'\n✅ {len(empty_subjects)} subject deaktive edildi')
    print('Artık sadece topic içeren subject\'ler görünecek')

if __name__ == '__main__':
    cleanup_empty_subjects()
