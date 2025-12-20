import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

print("=== SORULARIN topicIds YAPISINI KONTROL ===")
questions = list(db.collection("questions").limit(10).stream())
for q in questions:
    data = q.to_dict()
    print(f"Q: {q.id}")
    print(f"  subjectId: {data.get('subjectId')}")
    print(f"  topicIds: {data.get('topicIds')}")
    print(f"  topicId (singular): {data.get('topicId')}")
    print()

# topicIds alanı olan soruları say
print("\n=== topicIds ALANI ANALIZI ===")
all_questions = list(db.collection("questions").stream())
with_topicIds = 0
without_topicIds = 0
topicIds_values = set()

for q in all_questions:
    data = q.to_dict()
    topic_ids = data.get('topicIds')
    if topic_ids and len(topic_ids) > 0:
        with_topicIds += 1
        for tid in topic_ids:
            topicIds_values.add(tid)
    else:
        without_topicIds += 1

print(f"topicIds OLAN sorular: {with_topicIds}")
print(f"topicIds OLMAYAN sorular: {without_topicIds}")
print(f"Toplam: {len(all_questions)}")

print(f"\nOrnek topicIds degerleri (ilk 10):")
for i, tid in enumerate(list(topicIds_values)[:10]):
    print(f"  {tid}")

# Bu topicIds'lerin gercekten topics koleksiyonunda var olup olmadigini kontrol et
print("\n=== topicIds GECERLILIGI ===")
sample_topic_ids = list(topicIds_values)[:5]
for tid in sample_topic_ids:
    topic_doc = db.collection("topics").document(tid).get()
    if topic_doc.exists:
        print(f"  {tid} -> EXISTS: {topic_doc.to_dict().get('name')}")
    else:
        print(f"  {tid} -> NOT FOUND!")
