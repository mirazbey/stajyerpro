"""
StajyerPro - Dersler, Konular, Sorular Hiyerarşi Analizi
Bu script uygulamadaki yapı ile Firestore'daki yapıyı karşılaştırır
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
import json

# Firebase başlat
if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def analyze_hierarchy():
    print("=" * 80)
    print("📊 StajyerPro - Hiyerarşi Analizi")
    print("=" * 80)
    
    # 1. SUBJECTS (Dersler) ANALİZİ
    print("\n" + "=" * 60)
    print("1️⃣  SUBJECTS (DERSLER) KOLEKSİYONU")
    print("=" * 60)
    
    subjects = {}
    subjects_docs = db.collection('subjects').get()
    
    for doc in subjects_docs:
        data = doc.to_dict()
        subjects[doc.id] = {
            'name': data.get('name', 'N/A'),
            'isActive': data.get('isActive', False),
            'order': data.get('order', 0),
            'topicCount': data.get('topicCount', 0),
        }
    
    print(f"\nToplam Ders: {len(subjects)}")
    print("\n📚 Aktif Dersler:")
    active_subjects = {k: v for k, v in subjects.items() if v['isActive']}
    for sid, info in sorted(active_subjects.items(), key=lambda x: x[1]['order']):
        print(f"  [{info['order']:2}] {sid}: {info['name']}")
    
    inactive_subjects = {k: v for k, v in subjects.items() if not v['isActive']}
    if inactive_subjects:
        print(f"\n⚠️  Pasif Dersler ({len(inactive_subjects)}):")
        for sid, info in inactive_subjects.items():
            print(f"      {sid}: {info['name']}")
    
    # 2. TOPICS (Konular) ANALİZİ
    print("\n" + "=" * 60)
    print("2️⃣  TOPICS (KONULAR) KOLEKSİYONU")
    print("=" * 60)
    
    topics = {}
    topics_by_subject = defaultdict(list)
    root_topics = []
    sub_topics = []
    orphan_topics = []
    
    topics_docs = db.collection('topics').get()
    
    for doc in topics_docs:
        data = doc.to_dict()
        subject_id = data.get('subjectId', '')
        parent_id = data.get('parentId')
        
        topics[doc.id] = {
            'name': data.get('name', 'N/A'),
            'subjectId': subject_id,
            'parentId': parent_id,
            'isActive': data.get('isActive', False),
            'order': data.get('order', 0),
        }
        
        if subject_id:
            topics_by_subject[subject_id].append(doc.id)
        
        if parent_id:
            sub_topics.append(doc.id)
        else:
            root_topics.append(doc.id)
        
        # Orphan kontrol (subject_id var ama subjects'ta yok)
        if subject_id and subject_id not in subjects:
            orphan_topics.append({
                'topicId': doc.id,
                'topicName': data.get('name'),
                'subjectId': subject_id
            })
    
    print(f"\nToplam Konu: {len(topics)}")
    print(f"  - Ana Konular (parentId yok): {len(root_topics)}")
    print(f"  - Alt Konular (parentId var): {len(sub_topics)}")
    
    if orphan_topics:
        print(f"\n⚠️  Yetim Konular (subject_id geçersiz): {len(orphan_topics)}")
        for ot in orphan_topics[:5]:
            print(f"      {ot['topicId']}: {ot['topicName']} -> subjectId: {ot['subjectId']}")
    
    # Ders başına konu sayısı
    print("\n📊 Ders Başına Konu Dağılımı:")
    for sid in sorted(active_subjects.keys()):
        topic_count = len(topics_by_subject.get(sid, []))
        print(f"  {sid}: {topic_count} konu")
    
    # 3. QUESTIONS (Sorular) ANALİZİ
    print("\n" + "=" * 60)
    print("3️⃣  QUESTIONS (SORULAR) KOLEKSİYONU")
    print("=" * 60)
    
    questions_by_subject = defaultdict(int)
    questions_by_topic = defaultdict(int)
    invalid_subject_questions = []
    invalid_topic_questions = []
    
    questions_docs = db.collection('questions').get()
    
    for doc in questions_docs:
        data = doc.to_dict()
        subject_id = data.get('subjectId', '')
        topic_ids = data.get('topicIds', [])
        
        questions_by_subject[subject_id] += 1
        
        for tid in topic_ids:
            questions_by_topic[tid] += 1
        
        # Invalid subject kontrolü
        if subject_id and subject_id not in subjects:
            invalid_subject_questions.append({
                'questionId': doc.id,
                'subjectId': subject_id,
                'stem': data.get('stem', '')[:50]
            })
        
        # Invalid topic kontrolü
        for tid in topic_ids:
            if tid not in topics:
                invalid_topic_questions.append({
                    'questionId': doc.id,
                    'topicId': tid,
                    'stem': data.get('stem', '')[:50]
                })
    
    print(f"\nToplam Soru: {len(questions_docs)}")
    
    print("\n📊 Subject (Ders) Başına Soru Dağılımı:")
    for sid, count in sorted(questions_by_subject.items(), key=lambda x: -x[1]):
        status = "✓" if sid in subjects else "⚠️ "
        print(f"  {status} {sid}: {count} soru")
    
    if invalid_subject_questions:
        print(f"\n⚠️  Geçersiz subjectId'li Sorular: {len(invalid_subject_questions)}")
        for q in invalid_subject_questions[:5]:
            print(f"      {q['questionId']}: subjectId='{q['subjectId']}'")
    
    if invalid_topic_questions:
        print(f"\n⚠️  Geçersiz topicId'li Sorular: {len(invalid_topic_questions)}")
        unique_invalid_topics = set(q['topicId'] for q in invalid_topic_questions)
        print(f"      Geçersiz topic sayısı: {len(unique_invalid_topics)}")
        for tid in list(unique_invalid_topics)[:10]:
            count = sum(1 for q in invalid_topic_questions if q['topicId'] == tid)
            print(f"        '{tid}': {count} soru")
    
    # 4. UYUM PROBLEMLERİ
    print("\n" + "=" * 60)
    print("4️⃣  UYUM PROBLEMLERİ")
    print("=" * 60)
    
    problems = []
    
    # 4.1 Script vs Firestore subject ID'leri
    # 4.1 Script vs Firestore subject ID'leri (import_questions_to_firestore.py ile eşleşmeli)
    script_subjects = {
        "ANAYASA": "anayasa_hukuku",
        "MEDENI": "medeni_hukuk",     # Düzeltildi: medeni_hukuku -> medeni_hukuk
        "BORCLAR": "borclar_hukuku",
        "TICARET": "ticaret_hukuku",
        "CEZA": "ceza_hukuku",
        "CMK": "ceza_muhakemesi",
        "IDARE": "idare_hukuku",
        "IYUK": "idari_yargilama",
        "VERGI": "vergi_hukuku",
        "ICRA": "icra_iflas",
        "IS": "is_hukuku",
        "AVUKATLIK": "avukatlik_hukuku",
        "FELSEFE": "hukuk_felsefesi",
        "MILLETLERARASI": "milletlerarasi_hukuk",
        "MOHUK": "mohuk",
    }
    
    # Script'teki subject'ların Firestore'da var mı kontrolü
    print("\n📋 Script vs Firestore Subject Eşleştirmesi:")
    for script_code, expected_id in script_subjects.items():
        in_firestore = expected_id in subjects
        in_questions = expected_id in questions_by_subject
        q_count = questions_by_subject.get(expected_id, 0)
        
        status = "✅" if (in_firestore and in_questions) else "⚠️ "
        fs_status = "FS:✓" if in_firestore else "FS:✗"
        q_status = f"Q:{q_count}"
        
        print(f"  {status} {script_code} -> {expected_id}: {fs_status}, {q_status}")
        
        if not in_firestore:
            problems.append(f"Subject '{expected_id}' Firestore'da yok")
    
    # 4.2 Exam distribution vs actual subjects (exam_repository.dart ile eşleşmeli)
    # NOT: exam_repository.dart'taki distribution güncellendi - doğru ID'ler kullanılıyor
    exam_distribution = {
        'medeni_hukuk': 15,      # Medeni Hukuk
        'borclar_hukuku': 12,    # Borçlar Hukuku  
        'ticaret_hukuku': 12,    # Ticaret Hukuku
        'ceza_hukuku': 12,       # Ceza Hukuku (genel + özel birleşti)
        'ceza_muhakemesi': 9,    # CMK
        'anayasa_hukuku': 9,     # Anayasa Hukuku
        'idare_hukuku': 9,       # İdare Hukuku
        'idari_yargilama': 8,    # İdari Yargılama
        'vergi_hukuku': 8,       # Vergi Hukuku
        'icra_iflas': 8,         # İcra ve İflas
        'is_hukuku': 6,          # İş Hukuku
        'avukatlik_hukuku': 6,   # Avukatlık Hukuku
        'hukuk_felsefesi': 3,    # Hukuk Felsefesi
        'milletlerarasi_hukuk': 2,  # Milletlerarası Hukuk
        'mohuk': 1,              # MÖHUK
    }
    
    print("\n📋 Exam Repository Distribution vs Firestore:")
    for exam_subject, required in exam_distribution.items():
        actual = questions_by_subject.get(exam_subject, 0)
        status = "✅" if actual >= required else "⚠️ "
        print(f"  {status} {exam_subject}: gerekli={required}, mevcut={actual}")
        
        if actual < required:
            problems.append(f"'{exam_subject}' için yetersiz soru: {actual}/{required}")
    
    # 4.3 topicIds string vs array kontrolü
    print("\n📋 TopicIds Format Kontrolü:")
    string_topicids = 0
    array_topicids = 0
    empty_topicids = 0
    
    for doc in questions_docs:
        data = doc.to_dict()
        topic_ids = data.get('topicIds')
        if topic_ids is None:
            empty_topicids += 1
        elif isinstance(topic_ids, str):
            string_topicids += 1
        elif isinstance(topic_ids, list):
            array_topicids += 1
    
    print(f"  - Array format: {array_topicids}")
    print(f"  - String format: {string_topicids}")
    print(f"  - Boş/null: {empty_topicids}")
    
    if string_topicids > 0:
        problems.append(f"{string_topicids} soruda topicIds string formatında (array olmalı)")
    
    # ÖZET
    print("\n" + "=" * 60)
    print("📊 ÖZET")
    print("=" * 60)
    
    print(f"""
Mevcut Yapı:
  - Subjects: {len(subjects)} ({len(active_subjects)} aktif)
  - Topics: {len(topics)} ({len(root_topics)} ana, {len(sub_topics)} alt)
  - Questions: {len(questions_docs)}

Hiyerarşi:
  subjects (dersler)
      └─ topics (konular) -> subjectId ile bağlı
          └─ topics (alt konular) -> parentId ile bağlı
              └─ questions (sorular) -> subjectId + topicIds ile bağlı

Sorunlar: {len(problems)} adet
""")
    
    if problems:
        print("⚠️  Tespit Edilen Sorunlar:")
        for i, p in enumerate(problems, 1):
            print(f"  {i}. {p}")
    
    return {
        'subjects': len(subjects),
        'topics': len(topics),
        'questions': len(questions_docs),
        'problems': problems
    }


if __name__ == "__main__":
    analyze_hierarchy()
