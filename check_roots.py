"""Anayasa root topics kontrol"""
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate(r'c:\Users\HP\Desktop\StajyerPro\service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Anayasa root topics
print('=== ANAYASA ROOT TOPICS ===')
topics = db.collection('topics').where('subjectId', '==', 'anayasa_hukuku').stream()
roots = []
children = []
for t in topics:
    d = t.to_dict()
    if d.get('parentId') is None:
        roots.append(d)
    else:
        children.append(d)

print(f'ROOT: {len(roots)}')
for r in roots:
    print(f'  - {r.get("name")}')

print(f'\nCHILD: {len(children)}')
for c in children[:5]:
    print(f'  - {c.get("name")}')

print('\n=== ALL ROOT TOPICS ===')
all_topics = list(db.collection('topics').stream())
all_roots = [t.to_dict() for t in all_topics if t.to_dict().get('parentId') is None]
print(f'Toplam ROOT topic: {len(all_roots)}')

# Subject bazında grupla
from collections import Counter
subject_counts = Counter(r.get('subjectId') for r in all_roots)
for subj, count in subject_counts.most_common(10):
    print(f'  {subj}: {count} root')
