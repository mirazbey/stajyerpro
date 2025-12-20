"""
Eksik ve Az Sorulu Konular için Çeşitli Soru Üretim Scripti
- Sorusuz konulara her zorluktan soru üretir
- Az sorulu konuları tamamlar
- Her soruya aiTip ekler

Kullanım:
    python generate_diverse_questions.py --list           # Eksik konuları listele
    python generate_diverse_questions.py --analyze        # Detaylı analiz
    python generate_diverse_questions.py --generate       # Üret (dry run)
    python generate_diverse_questions.py --generate --apply  # Firestore'a kaydet
    python generate_diverse_questions.py --subject ceza_muhakemesi --apply
"""

import os
import json
import argparse
import time
from datetime import datetime
from pathlib import Path
from collections import defaultdict

try:
    import google.generativeai as genai
except ImportError:
    print("❌ google-generativeai paketi yüklü değil!")
    exit(1)

import firebase_admin
from firebase_admin import credentials, firestore

# Firebase init
if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ============================================
# KONFIGÜRASYON
# ============================================

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyApIRbm-RF9dHQ_99duUH4QUz6_NNJz65E")
MODEL_NAME = "gemini-2.5-flash"

BASE_DIR = Path(__file__).parent
DOCS_DIR = BASE_DIR / "docs"

genai.configure(api_key=GEMINI_API_KEY)

# Rate limiting
RATE_LIMIT_DELAY = 8
RETRY_DELAY = 45
MAX_RETRIES = 5

# Minimum soru sayısı hedefi
MIN_QUESTIONS_PER_TOPIC = 10
MIN_EASY = 3
MIN_MEDIUM = 4
MIN_HARD = 3

# ============================================
# PDF YÖNETİMİ
# ============================================

SUBJECT_PDF_MAP = {
    'icra_iflas': [
        'icra ve iflas hukuku ders notları.pdf',
        'icra ve iflas kanunu.pdf',
        '9.yargı paketi.pdf'
    ],
    'anayasa_hukuku': [
        'Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf',
        'TC Anayasası.pdf',
        'genel kamu hukuku ders notları.pdf'
    ],
    'medeni_hukuk': [
        'medeni hukuk ders notları.pdf',
        'türk medeni kanunu.pdf',
        'hukuk muhakemeleri kanunu.pdf'
    ],
    'borclar_hukuku': [
        'borçlar hukuku ders notları.pdf',
        'türk borçlar kanunu.pdf'
    ],
    'ticaret_hukuku': [
        'ticaret hukuku ders notları.pdf',
        'türk ticaret kanunu.pdf'
    ],
    'ceza_hukuku': [
        'ceza hukuku genel hükümler ders notları.pdf',
        'ceza hukuku özel hükümler ders notları.pdf',
        'türk ceza kanunu.pdf',
        '9.yargı paketi.pdf',
        'CEZA MUHAKEMESİ KANUNU VE BAZI KANUNLARDA (7188).pdf',
        'CEZA MUHAKEMESİ KANUNU İLE BAZI KANUNLARDA DEĞİŞİKLİK.pdf'
    ],
    'ceza_muhakemesi': [
        'ceza muhakemesi kanunu.pdf',
        '9.yargı paketi.pdf',
        'CEZA MUHAKEMESİ KANUNU VE BAZI KANUNLARDA (7188).pdf',
        'CEZA MUHAKEMESİ KANUNU İLE BAZI KANUNLARDA DEĞİŞİKLİK.pdf'
    ],
    'idare_hukuku': [
        'genel kamu hukuku ders notları.pdf',
        'idari yargı ve anayasa yargısı.pdf'
    ],
    'idari_yargilama': [
        'idari yargılama usülü kanunu.pdf',
        'idari yargı ve anayasa yargısı.pdf',
        '9.yargı paketi.pdf'
    ],
    'is_hukuku': [
        'iş kanunu.pdf',
        'iş mahkemeleri kanunu.pdf',
        'sosyal sigortalar ve genel sağlık sigortası kanunu.pdf',
        '9.yargı paketi.pdf'
    ],
    'vergi_hukuku': [
        'vergi usul kanunu.pdf',
        'Turk Vergi Sistemi (2019 Guncel).pdf'
    ],
    'avukatlik_hukuku': [
        'avukatlık kanunu.pdf',
        'avukatlık hukuku.pdf',
        '2025-hukuk-mesleklerine-giris-sinavi-ozel-hukuk-soru-bankasi-2-cilt ÖRNEK.pdf'
    ],
    'hukuk_felsefesi': [
        'hukuk felsefesi ders notları.pdf'
    ],
    'milletlerarasi_hukuk': [
        'Milletlerarası Hukuk ders notları.pdf'
    ],
    'mohuk': [
        'MİLLETLERARASI ÖZEL HUKUK VE USUL HUKUKU.pdf'
    ]
}

def get_pdfs_for_subject(subject_id: str) -> tuple[list[Path], list[str]]:
    """Ders için PDF listesini bul ve eksikleri bildir"""

    desired_pdfs = SUBJECT_PDF_MAP.get(subject_id, [])
    existing_paths: list[Path] = []
    missing_names: list[str] = []

    if DOCS_DIR.exists():
        for pdf_name in desired_pdfs:
            pdf_path = DOCS_DIR / pdf_name
            if pdf_path.exists():
                existing_paths.append(pdf_path)
            else:
                missing_names.append(pdf_name)

        # Genel soru bankasını ek kaynak olarak ekle
        general_bank = DOCS_DIR / "2025-hukuk-mesleklerine-giris-sinavi-ozel-hukuk-soru-bankasi-2-cilt ÖRNEK.pdf"
        if general_bank.exists() and general_bank not in existing_paths:
            existing_paths.append(general_bank)

    return existing_paths, missing_names

def upload_pdf_to_gemini(pdf_path: Path):
    """PDF'i Gemini'ye yükle"""
    try:
        uploaded = genai.upload_file(path=str(pdf_path), display_name=pdf_path.name)
        while uploaded.state.name == "PROCESSING":
            time.sleep(2)
            uploaded = genai.get_file(uploaded.name)
        return uploaded if uploaded.state.name == "ACTIVE" else None
    except Exception as e:
        print(f"   ⚠️ PDF yükleme hatası: {e}")
        return None

# ============================================
# VERİ ANALİZİ
# ============================================

def analyze_topics():
    """Tüm konuların soru durumunu analiz et"""
    
    print("🔍 Veriler analiz ediliyor...")
    
    # Subjects
    subjects = {}
    for doc in db.collection('subjects').stream():
        subjects[doc.id] = doc.to_dict().get('name', doc.id)
    
    # Topics
    topics = {}
    for doc in db.collection('topics').stream():
        data = doc.to_dict()
        topics[doc.id] = {
            'id': doc.id,
            'name': data.get('name'),
            'subjectId': data.get('subjectId'),
            'subjectName': subjects.get(data.get('subjectId'), data.get('subjectId'))
        }
    
    # Questions per topic
    questions_by_topic = defaultdict(lambda: {'easy': 0, 'medium': 0, 'hard': 0, 'total': 0})
    
    for doc in db.collection('questions').stream():
        data = doc.to_dict()
        difficulty = data.get('difficulty', 'medium')
        for tid in data.get('topicIds', []):
            questions_by_topic[tid][difficulty] += 1
            questions_by_topic[tid]['total'] += 1
    
    # Eksik konuları bul
    topics_needing_questions = []
    
    for tid, topic in topics.items():
        q = questions_by_topic.get(tid, {'easy': 0, 'medium': 0, 'hard': 0, 'total': 0})
        
        # Eksik soru sayısını hesapla
        need_easy = max(0, MIN_EASY - q['easy'])
        need_medium = max(0, MIN_MEDIUM - q['medium'])
        need_hard = max(0, MIN_HARD - q['hard'])
        need_total = need_easy + need_medium + need_hard
        
        if need_total > 0:
            topics_needing_questions.append({
                **topic,
                'current_easy': q['easy'],
                'current_medium': q['medium'],
                'current_hard': q['hard'],
                'current_total': q['total'],
                'need_easy': need_easy,
                'need_medium': need_medium,
                'need_hard': need_hard,
                'need_total': need_total,
                'priority': 0 if q['total'] == 0 else 1  # Sorusuz konular önce
            })
    
    # Önceliğe göre sırala
    topics_needing_questions.sort(key=lambda x: (x['priority'], -x['need_total']))
    
    return topics_needing_questions, subjects

# ============================================
# SORU ÜRETİMİ
# ============================================

def create_diverse_prompt(topic: dict) -> str:
    """Çeşitli zorluk ve türlerde soru üretim promptu"""
    
    questions_needed = []
    if topic['need_easy'] > 0:
        questions_needed.append(f"{topic['need_easy']} EASY (temel kavram, tanım)")
    if topic['need_medium'] > 0:
        questions_needed.append(f"{topic['need_medium']} MEDIUM (uygulama, örnek olay)")
    if topic['need_hard'] > 0:
        questions_needed.append(f"{topic['need_hard']} HARD (karmaşık senaryo, karşılaştırma)")
    
    questions_desc = ", ".join(questions_needed)
    
    prompt = f"""
# GÖREV
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için profesyonel soru yazarısın.
"{topic['subjectName']}" dersi, "{topic['name']}" konusu için toplam {topic['need_total']} soru üret:
{questions_desc}

# ZORUNLU JSON FORMATI
Her soru için TAM OLARAK bu formatı kullan:

```json
{{
  "stem": "Soru metni - en az 50 karakter, açık ve net",
  "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
  "correctIndex": 0,
  "explanation": "Detaylı açıklama - neden doğru, diğerleri neden yanlış",
  "lawArticle": "İlgili kanun maddesi veya null",
  "difficulty": "easy|medium|hard",
  "aiTip": "Kısa ipucu (max 2 cümle) - cevabı söylemeden düşünmeye yardımcı"
}}
```

# ZORLUK SEVİYELERİ
- EASY: Temel tanım, kavram soruları. "Hangisi doğrudur?", "Aşağıdakilerden hangisi X'tir?"
- MEDIUM: Uygulama soruları, örnek olay. "A kişisi ... durumunda ne yapmalıdır?"
- HARD: Karmaşık senaryolar, karşılaştırma, istisna durumlar. Detaylı analiz gerektiren.

# KURALLAR
1. correctIndex: 0=A, 1=B, 2=C, 3=D, 4=E
2. TAM 5 şık olmalı
3. Her zorluk seviyesinden belirtilen sayıda soru üret
4. aiTip: Doğru cevabı söyleme, sadece düşünmeye yönelik ipucu ver
5. Her soru "{topic['name']}" konusuyla doğrudan ilgili olmalı

# ÇIKTI
SADECE JSON array döndür, başka açıklama yok:
[soru1, soru2, ...]
"""
    return prompt


def generate_questions_for_topic(topic: dict, uploaded_files: list = None, retry_count: int = 0):
    """Bir konu için soru üret"""
    
    model = genai.GenerativeModel(
        model_name=MODEL_NAME,
        generation_config={
            "temperature": 0.8,
            "top_p": 0.95,
            "max_output_tokens": 16384,
        }
    )
    
    prompt = create_diverse_prompt(topic)
    content_parts = (uploaded_files or []) + [prompt]
    
    try:
        response = model.generate_content(content_parts)
        
        if not response.candidates or not response.candidates[0].content.parts:
            if retry_count < MAX_RETRIES:
                time.sleep(10)
                return generate_questions_for_topic(topic, uploaded_files, retry_count + 1)
            return []
        
        response_text = response.text
        
        # JSON çıkar
        if "```json" in response_text:
            json_start = response_text.find("```json") + 7
            json_end = response_text.find("```", json_start)
            response_text = response_text[json_start:json_end].strip()
        elif "```" in response_text:
            json_start = response_text.find("```") + 3
            json_end = response_text.find("```", json_start)
            response_text = response_text[json_start:json_end].strip()
        
        questions = json.loads(response_text)
        return questions
        
    except json.JSONDecodeError as e:
        print(f"   ❌ JSON hatası: {e}")
        if retry_count < MAX_RETRIES:
            time.sleep(5)
            return generate_questions_for_topic(topic, uploaded_files, retry_count + 1)
        return []
    except Exception as e:
        error_msg = str(e).lower()
        if 'rate' in error_msg or 'quota' in error_msg or 'resource' in error_msg:
            if retry_count < MAX_RETRIES:
                print(f"   ⏳ Rate limit, {RETRY_DELAY}s bekleniyor...")
                time.sleep(RETRY_DELAY)
                return generate_questions_for_topic(topic, uploaded_files, retry_count + 1)
        print(f"   ❌ API hatası: {e}")
        return []


def validate_and_prepare_question(q: dict, topic: dict) -> dict:
    """Soruyu doğrula ve hazırla"""
    
    # Zorunlu alanlar
    if not q.get('stem') or len(q.get('stem', '')) < 30:
        return None
    if not q.get('options') or len(q.get('options', [])) != 5:
        return None
    if q.get('correctIndex') not in [0, 1, 2, 3, 4]:
        return None
    
    # Varsayılan değerler
    q['subjectId'] = topic['subjectId']
    q['topicIds'] = [topic['id']]
    
    if q.get('difficulty') not in ['easy', 'medium', 'hard']:
        q['difficulty'] = 'medium'
    
    if not q.get('explanation'):
        q['explanation'] = ''
    
    if not q.get('lawArticle'):
        q['lawArticle'] = None
    
    if not q.get('aiTip'):
        q['aiTip'] = None
    
    q['createdAt'] = firestore.SERVER_TIMESTAMP
    q['updatedAt'] = firestore.SERVER_TIMESTAMP
    q['source'] = 'AI Generated (Diverse)'
    
    return q


def save_questions_to_firestore(questions: list, dry_run: bool = True):
    """Soruları Firestore'a kaydet"""
    
    if not questions:
        return 0
    
    if dry_run:
        print(f"   📝 DRY RUN: {len(questions)} soru kaydedilecek")
        return len(questions)
    
    saved = 0
    for q in questions:
        try:
            db.collection('questions').add(q)
            saved += 1
        except Exception as e:
            print(f"   ⚠️ Kayıt hatası: {e}")
    
    return saved

# ============================================
# MAIN
# ============================================

def main():
    parser = argparse.ArgumentParser(description='Eksik konular için çeşitli soru üret')
    parser.add_argument('--list', action='store_true', help='Eksik konuları listele')
    parser.add_argument('--analyze', action='store_true', help='Detaylı analiz')
    parser.add_argument('--generate', action='store_true', help='Soru üret')
    parser.add_argument('--subject', type=str, help='Belirli ders (örn: ceza_muhakemesi)')
    parser.add_argument('--limit', type=int, default=10, help='Max konu sayısı')
    parser.add_argument('--apply', action='store_true', help='Firestore\'a kaydet')
    
    args = parser.parse_args()
    
    # Analiz
    topics_needing, subjects = analyze_topics()
    
    if args.subject:
        topics_needing = [t for t in topics_needing if t['subjectId'] == args.subject]
    
    print(f"\n📊 {len(topics_needing)} konu eksik sorulara sahip")
    
    if args.list or args.analyze:
        # Derse göre grupla
        by_subject = defaultdict(list)
        for t in topics_needing:
            by_subject[t['subjectId']].append(t)
        
        print("\n" + "=" * 70)
        print("EKSİK SORULU KONULAR")
        print("=" * 70)
        
        for subj_id, topic_list in sorted(by_subject.items()):
            subj_name = subjects.get(subj_id, subj_id)
            total_need = sum(t['need_total'] for t in topic_list)
            zero_count = len([t for t in topic_list if t['current_total'] == 0])
            
            print(f"\n📚 {subj_name} ({subj_id})")
            print(f"   Eksik konu: {len(topic_list)}, Sorusuz: {zero_count}, Gereken soru: {total_need}")
            
            if args.analyze:
                for t in topic_list[:10]:
                    status = "⚠️ SORUSUZ" if t['current_total'] == 0 else f"({t['current_total']} soru)"
                    print(f"   - {t['name']} {status}")
                    print(f"     Mevcut: E:{t['current_easy']} M:{t['current_medium']} H:{t['current_hard']}")
                    print(f"     Gereken: E:{t['need_easy']} M:{t['need_medium']} H:{t['need_hard']}")
                if len(topic_list) > 10:
                    print(f"   ... ve {len(topic_list) - 10} konu daha")
        
        return
    
    if args.generate:
        # Soru üret
        topics_to_process = topics_needing[:args.limit]
        
        print(f"\n🚀 {len(topics_to_process)} konu için soru üretilecek")
        print(f"   Kayıt modu: {'GERÇEK' if args.apply else 'DRY RUN'}")
        
        total_generated = 0
        total_saved = 0
        
        for i, topic in enumerate(topics_to_process):
            print(f"\n📦 [{i+1}/{len(topics_to_process)}] {topic['subjectName']} > {topic['name']}")
            print(f"   Gereken: E:{topic['need_easy']} M:{topic['need_medium']} H:{topic['need_hard']}")
            
            # PDF yükle (zorunlu)
            uploaded_files = []
            pdf_paths, missing_pdfs = get_pdfs_for_subject(topic['subjectId'])
            required_pdf_count = max(1, min(3, len(SUBJECT_PDF_MAP.get(topic['subjectId'], []))))

            if missing_pdfs:
                print(f"   ⚠️ Eksik PDF: {', '.join(missing_pdfs)}")

            if len(pdf_paths) < required_pdf_count:
                print(f"   ❌ PDF sayısı yetersiz ({len(pdf_paths)}/{required_pdf_count}), konu atlanıyor")
                continue

            upload_limit = min(4, len(pdf_paths))
            print(f"   📂 PDF yükleme: {upload_limit} dosya seçildi")

            for pdf_path in pdf_paths[:upload_limit]:
                uploaded = upload_pdf_to_gemini(pdf_path)
                if uploaded:
                    uploaded_files.append(uploaded)

            if len(uploaded_files) < required_pdf_count:
                print(f"   ❌ Yüklenen PDF sayısı yetersiz ({len(uploaded_files)}/{required_pdf_count}), konu atlanıyor")
                for f in uploaded_files:
                    try:
                        genai.delete_file(f.name)
                    except:
                        pass
                continue
            
            # Soru üret
            questions = generate_questions_for_topic(topic, uploaded_files)
            
            if questions:
                # Doğrula
                valid_questions = []
                for q in questions:
                    validated = validate_and_prepare_question(q, topic)
                    if validated:
                        valid_questions.append(validated)
                
                print(f"   ✓ {len(valid_questions)} geçerli soru üretildi")
                total_generated += len(valid_questions)
                
                # Kaydet
                saved = save_questions_to_firestore(valid_questions, dry_run=not args.apply)
                if args.apply:
                    print(f"   💾 {saved} soru kaydedildi")
                total_saved += saved
            else:
                print(f"   ⚠️ Soru üretilemedi")
            
            # Yüklenen dosyaları temizle
            for f in uploaded_files:
                try:
                    genai.delete_file(f.name)
                except:
                    pass
            
            # Rate limit
            if i < len(topics_to_process) - 1:
                time.sleep(RATE_LIMIT_DELAY)
        
        print(f"\n{'=' * 70}")
        print(f"📈 ÖZET")
        print(f"{'=' * 70}")
        print(f"   İşlenen konu: {len(topics_to_process)}")
        print(f"   Üretilen soru: {total_generated}")
        print(f"   Kaydedilen: {total_saved}")
        
        if not args.apply:
            print("\n💡 Gerçek kayıt için: --apply parametresi ekleyin")
    
    else:
        print("\n💡 Kullanım:")
        print("   --list: Eksik konuları listele")
        print("   --analyze: Detaylı analiz")
        print("   --generate: Soru üret (dry run)")
        print("   --generate --apply: Soru üret ve kaydet")


if __name__ == '__main__':
    main()
