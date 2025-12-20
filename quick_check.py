import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()
topics = list(db.collection("topics").stream())
empty = []
filled = []

for t in topics:
    d = t.to_dict()
    desc_len = len(d.get("description", "").strip())
    if desc_len < 10:
        empty.append((d.get("name"), d.get("subjectId"), desc_len))
    else:
        filled.append((d.get("name"), d.get("subjectId"), desc_len))

print(f"Toplam topic: {len(topics)}")
print(f"Bos/Kisa: {len(empty)}")
print(f"Dolu: {len(filled)}")

if empty:
    print("\nBos olanlardan 15 ornek:")
    for name, subj, length in empty[:15]:
        print(f"  - {name} ({subj}): {length} kar")
        
if filled:
    print("\nDolu olanlardan 5 ornek:")
    for name, subj, length in filled[:5]:
        print(f"  - {name} ({subj}): {length} kar")