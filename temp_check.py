import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()
topics = list(db.collection('topics').stream())
empty = [t for t in topics if len(t.to_dict().get('description', '').strip()) < 10]

print(f'Toplam topic: {len(topics)}')
print(f'Bos/Kisa (<10 kar): {len(empty)}')
print(f'Dolu (10+ kar): {len(topics)-len(empty)}')
print('\nBos olanlardan 10 ornek:')
for t in empty[:10]:
    d = t.to_dict()
    print(f'  - {d.get(\"name\")} ({d.get(\"subjectId\")}): {len(d.get(\"description\",\"\").strip())} kar')
