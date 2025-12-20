"""
Sorusuz Konuları Tespit Et ve Soru Üretimi için Liste Oluştur
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

def find_topics_without_questions():
    """Sorusu olmayan topic'leri bul"""
    
    # Topics
    all_topics = {}
    for doc in db.collection('topics').stream():
        data = doc.to_dict()
        data['id'] = doc.id
        all_topics[doc.id] = data
    
    # Questions - hangi topicIds kullanılıyor
    used_topic_ids = set()
    for doc in db.collection('questions').stream():
        data = doc.to_dict()
        for tid in data.get('topicIds', []):
            used_topic_ids.add(tid)
    
    # Subjects
    subjects = {}
    for doc in db.collection('subjects').stream():
        subjects[doc.id] = doc.to_dict().get('name', doc.id)
    
    # Sorusuz konular
    topics_without_questions = []
    for tid, topic in all_topics.items():
        if tid not in used_topic_ids:
            topics_without_questions.append({
                'id': tid,
                'name': topic.get('name', 'NO NAME'),
                'subjectId': topic.get('subjectId', 'unknown'),
                'subjectName': subjects.get(topic.get('subjectId', ''), topic.get('subjectId', ''))
            })
    
    # Derse göre grupla
    by_subject = defaultdict(list)
    for t in topics_without_questions:
        by_subject[t['subjectName']].append(t)
    
    print("=" * 80)
    print("SORUSU OLMAYAN KONULAR")
    print("=" * 80)
    print(f"Toplam: {len(topics_without_questions)} konu sorusuz")
    print()
    
    for subj_name, topics in sorted(by_subject.items()):
        print(f"📚 {subj_name}: {len(topics)} sorusuz konu")
        for t in topics:
            print(f"   - {t['name']} ({t['id']})")
        print()
    
    # JSON olarak kaydet
    with open('topics_needing_questions.json', 'w', encoding='utf-8') as f:
        json.dump({
            'total': len(topics_without_questions),
            'by_subject': {k: v for k, v in by_subject.items()},
            'all_topics': topics_without_questions
        }, f, ensure_ascii=False, indent=2)
    
    print(f"Sonuçlar 'topics_needing_questions.json' dosyasına kaydedildi.")
    
    return topics_without_questions, by_subject

if __name__ == '__main__':
    find_topics_without_questions()
