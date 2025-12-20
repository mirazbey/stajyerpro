"""
Detaylı Topic-Question Analizi
Bu script:
1. Tüm topics'leri ve sorularını analiz eder
2. Her topic için potansiyel soru eşleşmelerini bulur
3. Eşleşme stratejisi önerir
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
from collections import defaultdict

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

def get_all_data():
    """Tüm subjects, topics ve questions verilerini çek"""
    
    # Subjects
    subjects = {}
    for doc in db.collection('subjects').stream():
        subjects[doc.id] = doc.to_dict()
    
    # Topics
    topics = {}
    for doc in db.collection('topics').stream():
        data = doc.to_dict()
        data['id'] = doc.id
        topics[doc.id] = data
    
    # Questions
    questions = []
    for doc in db.collection('questions').stream():
        data = doc.to_dict()
        data['id'] = doc.id
        questions.append(data)
    
    return subjects, topics, questions

def analyze_topic_question_matching():
    """Her topic için kaç soru var analiz et"""
    
    subjects, topics, questions = get_all_data()
    
    print("=" * 80)
    print("DETAYLI TOPIC-QUESTION ANALİZİ")
    print("=" * 80)
    
    # Subject bazlı grupla
    topics_by_subject = defaultdict(list)
    for tid, topic in topics.items():
        subj_id = topic.get('subjectId', 'unknown')
        topics_by_subject[subj_id].append(topic)
    
    # Questions by subject
    questions_by_subject = defaultdict(list)
    for q in questions:
        subj_id = q.get('subjectId', 'unknown')
        questions_by_subject[subj_id].append(q)
    
    # Topic'e göre question sayısı
    questions_by_topic = defaultdict(list)
    for q in questions:
        for tid in q.get('topicIds', []):
            questions_by_topic[tid].append(q)
    
    total_unmatched_topics = 0
    total_topics = len(topics)
    
    results = []
    
    for subj_id, subj_topics in sorted(topics_by_subject.items()):
        subj_name = subjects.get(subj_id, {}).get('name', subj_id)
        subj_questions = questions_by_subject.get(subj_id, [])
        
        print(f"\n{'='*60}")
        print(f"📚 {subj_name} ({subj_id})")
        print(f"   Toplam Soru: {len(subj_questions)}, Toplam Konu: {len(subj_topics)}")
        print(f"{'='*60}")
        
        matched_topics = []
        unmatched_topics = []
        
        for topic in sorted(subj_topics, key=lambda x: x.get('name', '')):
            topic_id = topic['id']
            topic_name = topic.get('name', 'NO NAME')
            topic_questions = questions_by_topic.get(topic_id, [])
            
            if len(topic_questions) > 0:
                matched_topics.append({
                    'id': topic_id,
                    'name': topic_name,
                    'question_count': len(topic_questions)
                })
            else:
                unmatched_topics.append({
                    'id': topic_id,
                    'name': topic_name,
                    'subjectId': subj_id
                })
                total_unmatched_topics += 1
        
        if matched_topics:
            print(f"\n✅ Sorulu Konular ({len(matched_topics)}):")
            for t in matched_topics:
                print(f"   - {t['name']}: {t['question_count']} soru")
        
        if unmatched_topics:
            print(f"\n❌ Sorusuz Konular ({len(unmatched_topics)}):")
            for t in unmatched_topics:
                print(f"   - {t['name']} ({t['id']})")
        
        results.append({
            'subjectId': subj_id,
            'subjectName': subj_name,
            'totalQuestions': len(subj_questions),
            'totalTopics': len(subj_topics),
            'matchedTopics': matched_topics,
            'unmatchedTopics': unmatched_topics
        })
    
    print("\n" + "=" * 80)
    print("ÖZET")
    print("=" * 80)
    print(f"Toplam Topic: {total_topics}")
    print(f"Sorusu Olan Topic: {total_topics - total_unmatched_topics}")
    print(f"Sorusuz Topic: {total_unmatched_topics}")
    print(f"Toplam Soru: {len(questions)}")
    
    # JSON olarak kaydet
    with open('topic_analysis_result.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"\nDetaylı sonuçlar 'topic_analysis_result.json' dosyasına kaydedildi.")
    
    return results

def find_potential_matches():
    """Soruların içeriğine bakarak potansiyel topic eşleşmeleri bul"""
    
    subjects, topics, questions = get_all_data()
    
    # Topics'leri subject'e göre grupla ve isimlerini küçük harfe çevir
    topics_by_subject = defaultdict(list)
    for tid, topic in topics.items():
        subj_id = topic.get('subjectId', 'unknown')
        topics_by_subject[subj_id].append({
            'id': tid,
            'name': topic.get('name', ''),
            'name_lower': topic.get('name', '').lower(),
            'keywords': set(topic.get('name', '').lower().split())
        })
    
    # Her soru için potansiyel topic eşleşmesi bul
    potential_matches = []
    
    for q in questions:
        subj_id = q.get('subjectId', 'unknown')
        current_topic_ids = q.get('topicIds', [])
        stem = q.get('stem', '').lower()
        explanation = q.get('explanation', '').lower()
        law_article = q.get('lawArticle', '').lower()
        
        # Birleşik metin
        full_text = f"{stem} {explanation} {law_article}"
        
        # Bu subject'in topic'leri
        subj_topics = topics_by_subject.get(subj_id, [])
        
        # Skor hesapla
        matches = []
        for topic in subj_topics:
            score = 0
            matched_keywords = []
            
            # Topic adı tam olarak geçiyor mu?
            if topic['name_lower'] in full_text:
                score += 10
                matched_keywords.append(f"TAM: {topic['name']}")
            
            # Anahtar kelimeler geçiyor mu?
            for kw in topic['keywords']:
                if len(kw) > 3 and kw in full_text:  # 3 harften uzun kelimeler
                    score += 2
                    matched_keywords.append(kw)
            
            if score > 0:
                matches.append({
                    'topic_id': topic['id'],
                    'topic_name': topic['name'],
                    'score': score,
                    'keywords': matched_keywords
                })
        
        # En yüksek skorlu eşleşmeleri al
        matches.sort(key=lambda x: x['score'], reverse=True)
        best_matches = matches[:3] if matches else []
        
        if best_matches:
            potential_matches.append({
                'question_id': q['id'],
                'stem_preview': q.get('stem', '')[:100],
                'current_topics': current_topic_ids,
                'subject_id': subj_id,
                'potential_matches': best_matches
            })
    
    # Sonuçları kaydet
    with open('potential_topic_matches.json', 'w', encoding='utf-8') as f:
        json.dump(potential_matches, f, ensure_ascii=False, indent=2)
    
    print(f"\n{len(potential_matches)} soru için potansiyel eşleşme bulundu.")
    print("Sonuçlar 'potential_topic_matches.json' dosyasına kaydedildi.")
    
    return potential_matches

if __name__ == '__main__':
    analyze_topic_question_matching()
    print("\n" + "=" * 80)
    print("POTANSİYEL EŞLEŞMELERİ ARANIYOR...")
    print("=" * 80)
    find_potential_matches()
