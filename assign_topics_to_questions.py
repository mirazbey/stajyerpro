"""
Soruları Konulara Akıllı Eşleştirme Script'i
Bu script:
1. Her sorunun içeriğini analiz eder
2. Aynı dersteki tüm konuları kontrol eder
3. En uygun konuya atar (keyword matching + fuzzy matching)
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
import re
import json

if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Türkçe karakterleri normalize et
def normalize_turkish(text):
    """Türkçe karakterleri normalize et"""
    replacements = {
        'ı': 'i', 'İ': 'i',
        'ğ': 'g', 'Ğ': 'g',
        'ü': 'u', 'Ü': 'u',
        'ş': 's', 'Ş': 's',
        'ö': 'o', 'Ö': 'o',
        'ç': 'c', 'Ç': 'c'
    }
    for tr, en in replacements.items():
        text = text.replace(tr, en)
    return text.lower()

def extract_keywords(text):
    """Metinden anlamlı anahtar kelimeleri çıkar"""
    # Normalize et
    text = normalize_turkish(text)
    
    # Sadece harfler ve boşluklar kalsın
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    
    # Kelimelere ayır
    words = text.split()
    
    # Stop words (Türkçe)
    stop_words = {
        'bir', 'bu', 'su', 've', 'ile', 'icin', 'de', 'da', 'den', 'dan',
        'ne', 'mi', 'mu', 'mi', 'ya', 'veya', 'hem', 'ise', 'ki', 'gibi',
        'kadar', 'gore', 'dair', 'sonra', 'once', 'ait', 'ilgili', 'olan',
        'olarak', 'olmak', 'etmek', 'yapmak', 'bulunmak', 'var', 'yok',
        'hangisi', 'asagidakilerden', 'yukaridaki', 'asagidaki', 'ifade',
        'ifadelerden', 'sorusunun', 'cevabi', 'dogru', 'yanlis', 'sekilde',
        'durumda', 'halde', 'zaman', 'sirasinda', 'halinde', 'takdirde'
    }
    
    # 3 harften uzun ve stop word olmayan kelimeler
    keywords = [w for w in words if len(w) > 3 and w not in stop_words]
    
    return set(keywords)

def calculate_match_score(question_text, topic_name, topic_keywords):
    """Soru ve topic arasındaki eşleşme skorunu hesapla"""
    
    question_keywords = extract_keywords(question_text)
    topic_name_normalized = normalize_turkish(topic_name)
    topic_name_words = set(topic_name_normalized.split())
    
    score = 0
    matched_words = []
    
    # 1. Topic adı tam olarak geçiyor mu? (+20 puan)
    if topic_name_normalized in normalize_turkish(question_text):
        score += 20
        matched_words.append(f"[TAM]{topic_name}")
    
    # 2. Topic adındaki kelimeler geçiyor mu? (+5 puan her kelime için)
    for word in topic_name_words:
        if len(word) > 3 and word in normalize_turkish(question_text):
            score += 5
            matched_words.append(word)
    
    # 3. Özel terimler eşleşmesi (+3 puan)
    # Topic'e özgü terimler varsa kontrol et
    if topic_keywords:
        for kw in topic_keywords:
            if kw in question_keywords:
                score += 3
                matched_words.append(kw)
    
    return score, matched_words

# Konulara özgü anahtar kelimeler (manuel tanımlı)
TOPIC_SPECIFIC_KEYWORDS = {
    # İcra İflas
    'haciz': ['haciz', 'hacze', 'haczedilen', 'haczedilemez', 'menkul', 'gayrimenkul'],
    'iflas': ['iflas', 'muflislik', 'iflas masasi', 'tasfiye', 'konkordato'],
    'konkordato': ['konkordato', 'iflasın ertelenmesi', 'iyilestirme'],
    'icra': ['icra', 'takip', 'odeme emri', 'itiraz', 'icra dairesi'],
    'paraya cevirme': ['satis', 'ihale', 'acik artirma', 'pey', 'teminat'],
    'rehin': ['rehin', 'ipotek', 'teminat', 'rehinli'],
    'ilamli': ['ilam', 'ilamli', 'mahkeme karari', 'kesinlesmis'],
    'ilamsiz': ['ilamsiz', 'adi', 'kambiyo', 'odeme emri'],
    
    # Borçlar
    'sozlesme': ['sozlesme', 'akid', 'mukavele', 'taraflar', 'icap', 'kabul'],
    'tazminat': ['tazminat', 'zarar', 'giderim', 'karsilik'],
    'haksiz fiil': ['haksiz fiil', 'kusur', 'sorumluluk', 'zarar'],
    'kira': ['kira', 'kiraci', 'kiralayan', 'tahliye', 'kira bedeli'],
    'satis': ['satis', 'alim', 'satim', 'mal', 'ayip'],
    'vekalet': ['vekalet', 'vekil', 'temsil', 'yetki'],
    'borcun ifasi': ['ifa', 'odeme', 'edim', 'borc', 'alacak'],
    
    # Ceza
    'suc': ['suc', 'fail', 'magdur', 'kasit', 'taksir'],
    'ceza': ['ceza', 'hapis', 'adli para', 'muebbet', 'sureli'],
    'tesebbus': ['tesebbus', 'icra', 'elverisli', 'tamamlanmis'],
    'istirak': ['istirak', 'azmettirme', 'yardim', 'birlikte'],
    'meskun': ['meskun', 'konut', 'isyeri', 'gece'],
    
    # Medeni
    'evlilik': ['evlilik', 'evlenme', 'bosanma', 'nikah', 'nafaka'],
    'miras': ['miras', 'murisi', 'tereke', 'vasiyetname', 'mirascı'],
    'vesayet': ['vesayet', 'vasi', 'kisitli', 'kayyim'],
    'mulkiyet': ['mulkiyet', 'malik', 'tasarruf', 'zilyetlik'],
    'tapu': ['tapu', 'sicil', 'tescil', 'serh', 'beyan'],
    
    # Anayasa
    'temel haklar': ['temel hak', 'insan haklari', 'ozgurluk', 'sinirlandirma'],
    'yasama': ['tbmm', 'meclis', 'kanun', 'milletvekili'],
    'yurutme': ['cumhurbaskani', 'bakanlar', 'kararname', 'yurutme'],
    'yargi': ['mahkeme', 'yargi', 'anayasa mahkemesi', 'yargitay'],
    
    # İdare
    'idari islem': ['idari islem', 'iptal', 'idari karar', 'idari eylem'],
    'kamulaştırma': ['kamulastirma', 'istimlak', 'bedel'],
    'kamu gorevlisi': ['memur', 'devlet memuru', 'kamu gorevlisi', 'disiplin'],
    
    # Vergi
    'vergi': ['vergi', 'mukellefiyet', 'matrah', 'tarh', 'tahakkuk'],
    'vergi cezasi': ['vergi cezasi', 'kacakcilik', 'usulsuzluk'],
}

def get_topic_keywords(topic_name):
    """Topic adına göre özel anahtar kelimeler getir"""
    topic_lower = normalize_turkish(topic_name)
    keywords = set()
    
    for key, kw_list in TOPIC_SPECIFIC_KEYWORDS.items():
        if key in topic_lower:
            keywords.update(kw_list)
    
    return keywords

def assign_questions_to_topics(dry_run=True):
    """Soruları konulara ata"""
    
    print("=" * 80)
    print("SORU-KONU EŞLEŞTİRME İŞLEMİ")
    print("=" * 80)
    print(f"Mod: {'DRY RUN (değişiklik yapılmayacak)' if dry_run else 'GERÇEK (Firebase güncellenecek)'}")
    print()
    
    # Veri çek
    print("Veriler çekiliyor...")
    
    # Topics by subject
    topics_by_subject = defaultdict(list)
    all_topics = {}
    for doc in db.collection('topics').stream():
        data = doc.to_dict()
        data['id'] = doc.id
        all_topics[doc.id] = data
        subj_id = data.get('subjectId', 'unknown')
        topics_by_subject[subj_id].append(data)
    
    # Questions
    questions = []
    for doc in db.collection('questions').stream():
        data = doc.to_dict()
        data['id'] = doc.id
        questions.append(data)
    
    print(f"Toplam {len(questions)} soru ve {len(all_topics)} konu bulundu.")
    print()
    
    # İstatistikler
    stats = {
        'total_questions': len(questions),
        'updated': 0,
        'already_matched': 0,
        'no_match_found': 0,
        'errors': 0
    }
    
    assignments = []  # Yapılacak atamalar
    
    # Her soru için en uygun topic'i bul
    for i, question in enumerate(questions):
        q_id = question['id']
        subj_id = question.get('subjectId', '')
        current_topics = question.get('topicIds', [])
        
        # Soru metni
        stem = question.get('stem', '')
        explanation = question.get('explanation', '')
        law_article = question.get('lawArticle', '')
        full_text = f"{stem} {explanation} {law_article}"
        
        if not full_text.strip():
            stats['errors'] += 1
            continue
        
        # Bu subject'in topic'lerini al
        subject_topics = topics_by_subject.get(subj_id, [])
        
        if not subject_topics:
            stats['no_match_found'] += 1
            continue
        
        # Her topic için skor hesapla
        scored_topics = []
        for topic in subject_topics:
            topic_keywords = get_topic_keywords(topic.get('name', ''))
            score, matched = calculate_match_score(
                full_text, 
                topic.get('name', ''),
                topic_keywords
            )
            if score > 0:
                scored_topics.append({
                    'topic_id': topic['id'],
                    'topic_name': topic.get('name', ''),
                    'score': score,
                    'matched_words': matched
                })
        
        # Skora göre sırala
        scored_topics.sort(key=lambda x: x['score'], reverse=True)
        
        # En iyi eşleşmeyi al (en az 5 puan olmalı)
        if scored_topics and scored_topics[0]['score'] >= 5:
            best_match = scored_topics[0]
            new_topic_id = best_match['topic_id']
            
            # Zaten bu topic'e atanmış mı?
            if new_topic_id in current_topics:
                stats['already_matched'] += 1
            else:
                # Yeni atama
                new_topic_ids = list(set(current_topics + [new_topic_id]))
                
                assignments.append({
                    'question_id': q_id,
                    'stem_preview': stem[:80] + '...' if len(stem) > 80 else stem,
                    'subject_id': subj_id,
                    'old_topics': current_topics,
                    'new_topics': new_topic_ids,
                    'matched_topic': best_match['topic_name'],
                    'score': best_match['score'],
                    'matched_words': best_match['matched_words']
                })
                stats['updated'] += 1
        else:
            stats['no_match_found'] += 1
        
        # Progress
        if (i + 1) % 100 == 0:
            print(f"İşlenen: {i + 1}/{len(questions)}")
    
    print()
    print("=" * 80)
    print("SONUÇLAR")
    print("=" * 80)
    print(f"Toplam Soru: {stats['total_questions']}")
    print(f"Güncellenecek: {stats['updated']}")
    print(f"Zaten Eşleşmiş: {stats['already_matched']}")
    print(f"Eşleşme Bulunamadı: {stats['no_match_found']}")
    print(f"Hata: {stats['errors']}")
    
    # Atamaları subject bazında grupla ve göster
    assignments_by_subject = defaultdict(list)
    for a in assignments:
        assignments_by_subject[a['subject_id']].append(a)
    
    print()
    print("ATAMA ÖNİZLEME (Ders Bazında):")
    print("-" * 60)
    
    for subj_id, subj_assignments in sorted(assignments_by_subject.items()):
        print(f"\n📚 {subj_id}: {len(subj_assignments)} soru güncellenecek")
        
        # Topic bazında grupla
        by_topic = defaultdict(list)
        for a in subj_assignments:
            by_topic[a['matched_topic']].append(a)
        
        for topic, topic_assignments in sorted(by_topic.items(), key=lambda x: -len(x[1])):
            print(f"   └─ {topic}: {len(topic_assignments)} soru")
    
    # Sonuçları kaydet
    with open('topic_assignments.json', 'w', encoding='utf-8') as f:
        json.dump({
            'stats': stats,
            'assignments': assignments
        }, f, ensure_ascii=False, indent=2)
    
    print()
    print(f"Detaylı atamalar 'topic_assignments.json' dosyasına kaydedildi.")
    
    # Gerçek güncelleme
    if not dry_run and assignments:
        print()
        print("Firebase güncelleniyor...")
        
        batch = db.batch()
        batch_count = 0
        
        for i, assignment in enumerate(assignments):
            q_ref = db.collection('questions').document(assignment['question_id'])
            batch.update(q_ref, {'topicIds': assignment['new_topics']})
            batch_count += 1
            
            # Firestore batch limiti: 500
            if batch_count >= 450:
                batch.commit()
                print(f"  Batch commit: {i + 1}/{len(assignments)}")
                batch = db.batch()
                batch_count = 0
        
        if batch_count > 0:
            batch.commit()
        
        print(f"✅ {len(assignments)} soru güncellendi!")
    
    return stats, assignments

if __name__ == '__main__':
    import sys
    
    dry_run = '--apply' not in sys.argv
    
    if dry_run:
        print("DRY RUN modu - değişiklik yapılmayacak")
        print("Gerçek güncelleme için: python assign_topics_to_questions.py --apply")
        print()
    
    stats, assignments = assign_questions_to_topics(dry_run=dry_run)
