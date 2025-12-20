"""
Soru Dağılımı Analizi
Hangi konularda soru eksik, zorluk dağılımı nasıl?
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Tüm topics
topics = {}
for doc in db.collection('topics').stream():
    data = doc.to_dict()
    topics[doc.id] = {'name': data.get('name'), 'subjectId': data.get('subjectId')}

# Tüm subjects
subjects = {}
for doc in db.collection('subjects').stream():
    subjects[doc.id] = doc.to_dict().get('name', doc.id)

# Tüm sorular - topic ve difficulty dağılımı
questions_by_topic = defaultdict(lambda: {'easy': 0, 'medium': 0, 'hard': 0, 'total': 0})
total_questions = 0

for doc in db.collection('questions').stream():
    data = doc.to_dict()
    total_questions += 1
    difficulty = data.get('difficulty', 'medium')
    for tid in data.get('topicIds', []):
        questions_by_topic[tid][difficulty] += 1
        questions_by_topic[tid]['total'] += 1

print(f'📊 TOPLAM: {total_questions} soru, {len(topics)} konu')
print()

# Derse göre grupla
by_subject = defaultdict(list)
for tid, info in topics.items():
    q_info = questions_by_topic.get(tid, {'easy': 0, 'medium': 0, 'hard': 0, 'total': 0})
    by_subject[info['subjectId']].append({
        'id': tid,
        'name': info['name'],
        **q_info
    })

# Özet
print('=' * 70)
print('DERS BAZINDA SORU DAĞILIMI')
print('=' * 70)

zero_all = []
low_all = []

for subj_id, topic_list in sorted(by_subject.items()):
    subj_name = subjects.get(subj_id, subj_id)
    total = sum(t['total'] for t in topic_list)
    zero_topics = [t for t in topic_list if t['total'] == 0]
    low_topics = [t for t in topic_list if 0 < t['total'] < 5]
    
    zero_all.extend([(subj_name, t) for t in zero_topics])
    low_all.extend([(subj_name, t) for t in low_topics])
    
    print(f'\n📚 {subj_name}')
    print(f'   Toplam: {total} soru, {len(topic_list)} konu')
    print(f'   Sorusuz: {len(zero_topics)}, Az sorulu (<5): {len(low_topics)}')
    
    if zero_topics:
        print(f'   ⚠️ Sorusuz konular:')
        for t in zero_topics[:5]:
            print(f'      - {t["name"]}')
        if len(zero_topics) > 5:
            print(f'      ... ve {len(zero_topics)-5} konu daha')

print()
print('=' * 70)
print('ZORLUK DAĞILIMI (TÜM SORULAR)')
print('=' * 70)
easy = sum(q['easy'] for q in questions_by_topic.values())
medium = sum(q['medium'] for q in questions_by_topic.values())
hard = sum(q['hard'] for q in questions_by_topic.values())
print(f'Easy: {easy} ({easy*100//max(1,total_questions)}%)')
print(f'Medium: {medium} ({medium*100//max(1,total_questions)}%)')
print(f'Hard: {hard} ({hard*100//max(1,total_questions)}%)')

print()
print('=' * 70)
print(f'ÖZET: {len(zero_all)} sorusuz konu, {len(low_all)} az sorulu konu')
print('=' * 70)
