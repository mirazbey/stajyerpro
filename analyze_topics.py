import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()
questions = list(db.collection('questions').stream())

# subjectId ve topicIds analizi
subject_topics = {}
stem_duplicates = {}

for q in questions:
    data = q.to_dict()
    subject_id = data.get('subjectId', 'unknown')
    topic_ids = data.get('topicIds', [])
    stem = data.get('stem', '')
    
    if subject_id not in subject_topics:
        subject_topics[subject_id] = {'topics': set(), 'count': 0}
    
    subject_topics[subject_id]['count'] += 1
    for t in (topic_ids if isinstance(topic_ids, list) else [topic_ids]):
        subject_topics[subject_id]['topics'].add(t)
    
    # Duplicate check
    stem_key = stem[:60] if stem else ''
    if stem_key:
        if stem_key not in stem_duplicates:
            stem_duplicates[stem_key] = []
        stem_duplicates[stem_key].append({'id': q.id, 'subject': subject_id})

print('=== DERS BAZINDA SORU VE KONU SAYILARI ===')
for sid, info in sorted(subject_topics.items(), key=lambda x: -x[1]['count']):
    count = info['count']
    topic_count = len(info['topics'])
    print(f'{sid}: {count} soru, {topic_count} konu')
    if info['topics']:
        topics_list = sorted(list(info['topics']))[:5]
        for t in topics_list:
            print(f'    - {t}')
        if len(info['topics']) > 5:
            remaining = len(info['topics']) - 5
            print(f'    ... +{remaining} konu daha')

# Tekrar eden sorular
duplicates = [(k, v) for k, v in stem_duplicates.items() if len(v) > 1]
print(f'\n=== TEKRAR EDEN SORULAR: {len(duplicates)} adet ===')
for stem, entries in duplicates[:10]:
    print(f'Soru: {stem}...')
    for e in entries:
        print(f'  -> {e["subject"]} ({e["id"]})')
    print()
