import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 1. icra_iflas soruların topicIds'lerini analiz et
print('=== İCRA İFLAS SORULARI ANALİZİ ===')
questions = db.collection('questions').where('subjectId', '==', 'icra_iflas').stream()
icra_questions = list(questions)
print(f'Toplam icra_iflas sorusu: {len(icra_questions)}')

topic_ids_in_questions = set()
for q in icra_questions:
    data = q.to_dict()
    tids = data.get('topicIds', [])
    for tid in tids:
        topic_ids_in_questions.add(tid)
print(f'Sorulardaki benzersiz topicIds: {len(topic_ids_in_questions)}')
print(f'TopicIds örnekleri: {list(topic_ids_in_questions)[:10]}')

# 2. topics koleksiyonundaki icra_iflas konuları
print()
print('=== TOPICS KOLEKSİYONUNDAKİ İCRA_İFLAS KONULARI ===')
topics = db.collection('topics').where('subjectId', '==', 'icra_iflas').stream()
topic_docs = {t.id: t.to_dict().get('name', 'NO NAME') for t in topics}
print(f'Toplam icra_iflas konusu: {len(topic_docs)}')
print('Topic ID -> Name örnekleri:')
for tid, name in list(topic_docs.items())[:10]:
    print(f'  {tid}: {name}')

# 3. XcO4vpvKHsasMFNldRlO topic'ini bul
print()
print('=== SEÇİLEN TOPIC DETAYI ===')
target_topic = db.collection('topics').document('XcO4vpvKHsasMFNldRlO').get()
if target_topic.exists:
    data = target_topic.to_dict()
    print(f'Topic ID: XcO4vpvKHsasMFNldRlO')
    print(f'Name: {data.get("name")}')
    print(f'SubjectId: {data.get("subjectId")}')
else:
    print('Topic bulunamadı!')

# 4. Eşleşme kontrolü
print()
print('=== EŞLEŞMELERİ KONTROL ET ===')
matches = topic_ids_in_questions.intersection(set(topic_docs.keys()))
print(f'Eşleşen topic sayısı: {len(matches)}')
if not matches:
    print('HİÇBİR SORU TOPIC ID İLE EŞLEŞMİYOR!')
else:
    print(f'Eşleşen topics: {matches}')

# 5. Genel özet - tüm dersler
print()
print('=== TÜM DERSLER İÇİN ÖZET ===')
subjects = db.collection('subjects').stream()
for subj in subjects:
    subj_id = subj.id
    subj_name = subj.to_dict().get('name', subj_id)
    
    # Bu dersteki sorular
    qs = list(db.collection('questions').where('subjectId', '==', subj_id).stream())
    question_topic_ids = set()
    for q in qs:
        for tid in q.to_dict().get('topicIds', []):
            question_topic_ids.add(tid)
    
    # Bu dersteki topics
    ts = list(db.collection('topics').where('subjectId', '==', subj_id).stream())
    topic_ids = {t.id for t in ts}
    
    # Eşleşme
    match_count = len(question_topic_ids.intersection(topic_ids))
    
    print(f'{subj_name}: {len(qs)} soru, {len(ts)} konu, {match_count} eşleşme')
