"""Check isActive status"""
import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate(r'c:\Users\HP\Desktop\StajyerPro\service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Anayasa topics isActive durumu
print('=== ANAYASA TOPICS isActive ===')
topics = list(db.collection('topics').where('subjectId', '==', 'anayasa_hukuku').stream())
active_count = sum(1 for t in topics if t.to_dict().get('isActive') == True)
inactive_count = sum(1 for t in topics if t.to_dict().get('isActive') == False)
none_count = sum(1 for t in topics if t.to_dict().get('isActive') is None)

print(f'Toplam: {len(topics)}')
print(f'isActive=True: {active_count}')
print(f'isActive=False: {inactive_count}')
print(f'isActive=None: {none_count}')

print()
for t in topics[:5]:
    d = t.to_dict()
    print(f"  {d.get('name')}: isActive={d.get('isActive')}")
