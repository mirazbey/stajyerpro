import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict

if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

print("=== TOPIC IDS DETAYLI ANALIZ ===")

# Once tum gercek topic ID'lerini al
all_topics = list(db.collection("topics").stream())
valid_topic_ids = set(t.id for t in all_topics)
print(f"Gecerli topic sayisi: {len(valid_topic_ids)}")

# Simdi sorulari kontrol et
all_questions = list(db.collection("questions").stream())
print(f"Toplam soru sayisi: {len(all_questions)}")

valid_topicid_questions = 0
invalid_topicid_questions = 0
invalid_topicids = defaultdict(int)

for q in all_questions:
    data = q.to_dict()
    topic_ids = data.get('topicIds', [])
    
    if not topic_ids:
        invalid_topicid_questions += 1
        continue
    
    # Ilk topicId'yi kontrol et (genellikle tek eleman var)
    first_topic_id = topic_ids[0] if topic_ids else None
    
    if first_topic_id and first_topic_id in valid_topic_ids:
        valid_topicid_questions += 1
    else:
        invalid_topicid_questions += 1
        if first_topic_id:
            invalid_topicids[first_topic_id] += 1

print(f"\n=== SONUCLAR ===")
print(f"Gecerli topicIds olan sorular: {valid_topicid_questions}")
print(f"Gecersiz/yanlis topicIds olan sorular: {invalid_topicid_questions}")

print(f"\n=== GECERSIZ topicIds ORNEKLERI (En sik 20) ===")
sorted_invalid = sorted(invalid_topicids.items(), key=lambda x: -x[1])
for tid, count in sorted_invalid[:20]:
    print(f"  {tid}: {count} soru")

# Bir ornek topic ID'nin neye benzedigini goster
print(f"\n=== ORNEK GECERLI TOPIC ID ===")
sample_topic = list(all_topics)[:3]
for t in sample_topic:
    print(f"  ID: {t.id}")
    print(f"  Name: {t.to_dict().get('name')}")
    print()
