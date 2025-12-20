import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

print('=== 1. SUBJECTS (Dersler) KOLEKSIYONU ===')
subjects = list(db.collection('subjects').stream())
print(f'Toplam: {len(subjects)} ders\n')
for s in subjects[:5]:
    data = s.to_dict()
    print(f'  ID: {s.id}')
    print(f'  name: {data.get("name")}')
    print(f'  keys: {list(data.keys())}')
    print()

print('\n=== 2. TOPICS (Konular) KOLEKSIYONU ===')
topics = list(db.collection('topics').stream())
print(f'Toplam: {len(topics)} konu\n')

# parentId olan ve olmayan konuları ayır
root_topics = []
sub_topics = []
for t in topics:
    data = t.to_dict()
    if data.get('parentId'):
        sub_topics.append((t.id, data))
    else:
        root_topics.append((t.id, data))

print(f'Ana Konular (parentId yok): {len(root_topics)}')
print(f'Alt Konular (parentId var): {len(sub_topics)}')

print('\n--- Örnek Ana Konular ---')
for tid, data in root_topics[:5]:
    print(f'  {tid}: {data.get("name")} -> subjectId: {data.get("subjectId")}')

print('\n--- Örnek Alt Konular ---')
for tid, data in sub_topics[:5]:
    print(f'  {tid}: {data.get("name")} -> parentId: {data.get("parentId")}')

print('\n=== 3. QUESTIONS (Sorular) YAPISINI INCELE ===')
questions = list(db.collection('questions').limit(10).stream())
print(f'\nÖrnek Soru Yapıları:')
for q in questions[:3]:
    data = q.to_dict()
    print(f'\nSoru ID: {q.id}')
    print(f'  subjectId: {data.get("subjectId")}')
    print(f'  topicIds: {data.get("topicIds")}')
    print(f'  topic (eski?): {data.get("topic")}')
    print(f'  difficulty: {data.get("difficulty")}')
    print(f'  tags: {data.get("tags")}')
    print(f'  stem: {data.get("stem", "")[:60]}...')

print('\n=== 4. HIYERARSI ANALIZI ===')
# Bir dersin tüm konularını göster
sample_subject = 'anayasa_hukuku'
print(f'\n{sample_subject} dersinin konuları:')

subject_topics = [t for t in topics if t.to_dict().get('subjectId') == sample_subject]
print(f'Toplam {len(subject_topics)} konu')

for t in subject_topics:
    data = t.to_dict()
    parent = data.get('parentId', '')
    level = '  └─ ' if parent else '• '
    print(f'{level}{t.id}: {data.get("name")}')
