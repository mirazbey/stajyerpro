"""
Sorusuz Konular için Gemini 2.5 Flash ile Soru Üretim Scripti
Firestore'daki topics koleksiyonundan sorusu olmayan konuları bulur ve 
her konu için 10 soru üretir.

Kullanım:
    python generate_missing_questions.py --list              # Sorusuz konuları listele
    python generate_missing_questions.py --subject icra_iflas --count 10  # Belirli ders
    python generate_missing_questions.py --all --count 10    # Tüm dersler
    python generate_missing_questions.py --apply             # Firebase'e kaydet
    python generate_missing_questions.py --skip "topic_name" # Belirli topic'i atla
    python generate_missing_questions.py --start-from "topic_name"  # Bu topic'ten başla
"""

import os
import json
import argparse
import time
from datetime import datetime
from pathlib import Path
from collections import defaultdict

# Rate limiting için global değişkenler
RATE_LIMIT_DELAY = 5  # Her topic arasında 5 saniye bekle
RETRY_DELAY = 30  # Hata sonrası 30 saniye bekle
MAX_RETRIES = 3  # Maksimum retry sayısı

try:
    import google.generativeai as genai
except ImportError:
    print("❌ google-generativeai paketi yüklü değil!")
    print("   Yüklemek için: pip install google-generativeai")
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
SORULAR_DIR = BASE_DIR / "sorular"

# Debug: klasör yollarını kontrol et
print(f"📂 BASE_DIR: {BASE_DIR}")
print(f"📂 DOCS_DIR: {DOCS_DIR} (exists: {DOCS_DIR.exists()})")

# Genai config
genai.configure(api_key=GEMINI_API_KEY)

# Cache dosyası
TOPICS_CACHE_FILE = BASE_DIR / "topics_needing_questions.json"

# ============================================
# FIRESTORE VERİ ÇEKME
# ============================================

def get_topics_from_cache():
    """Cache dosyasından sorusuz konuları oku"""
    if not TOPICS_CACHE_FILE.exists():
        return None, None, None
    
    with open(TOPICS_CACHE_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Flat list oluştur
    topics_without_questions = []
    by_subject = defaultdict(list)
    
    for subj_name, topics in data.get('by_subject', {}).items():
        for t in topics:
            topics_without_questions.append(t)
            by_subject[t['subjectId']].append(t)
    
    # Subjects dict (basit versiyon)
    subjects = {}
    for t in topics_without_questions:
        if t['subjectId'] not in subjects:
            subjects[t['subjectId']] = {'name': t['subjectName']}
    
    return topics_without_questions, dict(by_subject), subjects


def get_topics_without_questions():
    """Firestore'dan sorusu olmayan konuları çek"""
    
    # Tüm topics
    all_topics = {}
    for doc in db.collection('topics').stream():
        data = doc.to_dict()
        data['id'] = doc.id
        all_topics[doc.id] = data
    
    # Tüm sorulardaki topicIds
    used_topic_ids = set()
    for doc in db.collection('questions').stream():
        data = doc.to_dict()
        for tid in data.get('topicIds', []):
            used_topic_ids.add(tid)
    
    # Subjects
    subjects = {}
    for doc in db.collection('subjects').stream():
        subjects[doc.id] = doc.to_dict()
    
    # Sorusuz konular
    topics_without_questions = []
    for tid, topic in all_topics.items():
        if tid not in used_topic_ids:
            subj_id = topic.get('subjectId', 'unknown')
            topics_without_questions.append({
                'id': tid,
                'name': topic.get('name', 'NO NAME'),
                'subjectId': subj_id,
                'subjectName': subjects.get(subj_id, {}).get('name', subj_id)
            })
    
    # Derse göre grupla
    by_subject = defaultdict(list)
    for t in topics_without_questions:
        by_subject[t['subjectId']].append(t)
    
    return topics_without_questions, by_subject, subjects


def get_existing_questions_for_subject(subject_id: str, retry_count: int = 0):
    """Bir dersteki mevcut soruları getir - retry logic ile"""
    questions = []
    stems = set()
    
    try:
        docs = db.collection('questions').where('subjectId', '==', subject_id).stream()
        for doc in docs:
            data = doc.to_dict()
            questions.append(data)
            stem = data.get('stem', '')[:50].lower().strip()
            if stem:
                stems.add(stem)
    except Exception as e:
        if 'Quota exceeded' in str(e) or 'RESOURCE_EXHAUSTED' in str(e):
            if retry_count < MAX_RETRIES:
                print(f"   ⚠️ Firestore quota aşıldı, {RETRY_DELAY}s bekleniyor...")
                time.sleep(RETRY_DELAY)
                return get_existing_questions_for_subject(subject_id, retry_count + 1)
            else:
                print(f"   ❌ Max retry aşıldı, boş liste dönüyor")
                return [], set()
        raise e
    
    return questions, stems


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

def get_pdfs_for_subject(subject_id: str) -> list:
    """Ders için ilgili PDF'leri bul"""
    pdfs = SUBJECT_PDF_MAP.get(subject_id, [])
    existing_pdfs = []
    
    print(f"   🔍 Aranan PDF'ler: {pdfs}")
    print(f"   📂 DOCS_DIR: {DOCS_DIR} (exists: {DOCS_DIR.exists()})")
    
    if DOCS_DIR.exists():
        for pdf_name in pdfs:
            pdf_path = DOCS_DIR / pdf_name
            if pdf_path.exists():
                existing_pdfs.append(pdf_path)
                print(f"   ✓ Bulundu: {pdf_name}")
            else:
                print(f"   ✗ Bulunamadı: {pdf_name}")
    
    # Genel soru bankası varsa ekle
    soru_bankasi = DOCS_DIR / "2025-hukuk-mesleklerine-giris-sinavi-ozel-hukuk-soru-bankasi-2-cilt ÖRNEK.pdf"
    if soru_bankasi.exists() and soru_bankasi not in existing_pdfs:
        existing_pdfs.append(soru_bankasi)
    
    return existing_pdfs


def upload_pdf_to_gemini(pdf_path: Path):
    """PDF'i Gemini'ye yükle"""
    try:
        print(f"   📤 Yükleniyor: {pdf_path.name}")
        uploaded = genai.upload_file(path=str(pdf_path), display_name=pdf_path.name)
        
        # Yükleme tamamlanana kadar bekle
        while uploaded.state.name == "PROCESSING":
            time.sleep(2)
            uploaded = genai.get_file(uploaded.name)
        
        if uploaded.state.name == "ACTIVE":
            return uploaded
        else:
            print(f"   ❌ Yükleme başarısız: {uploaded.state.name}")
            return None
    except Exception as e:
        print(f"   ❌ PDF yükleme hatası: {e}")
        return None


# ============================================
# SORU ÜRETİMİ
# ============================================

def create_prompt_for_topic(topic_name: str, subject_name: str, subject_id: str, 
                           topic_id: str, count: int, existing_stems: set) -> str:
    """Belirli bir konu için soru üretim promptu"""
    
    existing_warning = ""
    if existing_stems:
        sample = list(existing_stems)[:3]
        existing_warning = f"""
⚠️ Bu derste zaten {len(existing_stems)} soru var. Aşağıdaki gibi sorular ÜRETME:
{chr(10).join(f'- "{s}..."' for s in sample)}
"""

    prompt = f"""
# GÖREV
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için profesyonel soru yazarısın.
"{subject_name}" dersi, "{topic_name}" konusu için {count} adet ÖZGÜN çoktan seçmeli soru üret.

{existing_warning}

# KAYNAK
Yukarıda yüklenen PDF dosyalarını referans al. "{topic_name}" konusuyla ilgili:
- Kanun maddelerini doğru kullan
- Tanım ve kavramları referans al
- Pratik uygulama örnekleri ver

# ZORUNLU JSON FORMATI
Her soru için TAM OLARAK bu formatı kullan:

```json
{{
  "stem": "Soru metni - açık, net, en az 30 karakter",
  "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
  "correctIndex": 0,
  "explanation": "Detaylı açıklama - neden bu cevap doğru, diğerleri neden yanlış",
  "lawArticle": "İlgili kanun maddesi (örn: İİK m.35) veya null",
  "difficulty": "medium",
  "subjectId": "{subject_id}",
  "topicIds": ["{topic_id}"],
  "aiTip": "Kısa ipucu (max 2 cümle) - cevabı söylemeden düşünmeye yardımcı olacak pratik ipucu"
}}
```

# KURALLAR
1. correctIndex: 0=A, 1=B, 2=C, 3=D, 4=E (0-4 arası integer)
2. difficulty: "easy", "medium" veya "hard"
3. TAM 5 şık olmalı
4. stem en az 30 karakter olmalı
5. explanation öğretici olmalı
6. Tüm sorular "{topic_name}" konusuyla ilgili olmalı

# SORU ÇEŞİTLİLİĞİ
- 2 tanım/kavram sorusu
- 3 uygulama/örnek olay sorusu  
- 2 karşılaştırma sorusu
- 2 kanun maddesi sorusu
- 1 "hangisi yanlıştır" türü soru

# ÇIKTI
SADECE JSON array döndür:
[soru1, soru2, soru3, ...]
"""
    return prompt


def generate_questions_for_topic(topic: dict, subject_info: dict, count: int = 10, skip_existing_check: bool = False):
    """Belirli bir konu için soru üret"""
    
    topic_name = topic['name']
    topic_id = topic['id']
    subject_id = topic['subjectId']
    subject_name = topic['subjectName']
    
    print(f"\n{'='*60}")
    print(f"📚 {subject_name} > {topic_name}")
    print(f"   Topic ID: {topic_id}")
    print(f"{'='*60}")
    
    # Mevcut soruları al (opsiyonel - Firestore sorgusunu atla)
    existing_stems = set()
    if skip_existing_check:
        print(f"⏭️ Mevcut soru kontrolü atlandı (--skip-existing-check)")
    else:
        existing_questions, existing_stems = get_existing_questions_for_subject(subject_id)
        print(f"📊 Derste mevcut soru: {len(existing_questions)}")
    
    # PDF'leri bul ve yükle
    pdf_paths = get_pdfs_for_subject(subject_id)
    if not pdf_paths:
        print(f"⚠️ PDF bulunamadı, PDF'siz devam ediliyor...")
    else:
        print(f"📄 Bulunan PDF'ler: {[p.name for p in pdf_paths]}")
    
    uploaded_files = []
    for pdf_path in pdf_paths[:3]:  # Max 3 PDF
        uploaded = upload_pdf_to_gemini(pdf_path)
        if uploaded:
            uploaded_files.append(uploaded)
    
    # Model oluştur
    model = genai.GenerativeModel(
        model_name=MODEL_NAME,
        generation_config={
            "temperature": 0.8,
            "top_p": 0.95,
            "max_output_tokens": 16384,
        }
    )
    
    # Prompt oluştur
    prompt = create_prompt_for_topic(
        topic_name, subject_name, subject_id, topic_id, count, existing_stems
    )
    
    # İçerik hazırla
    content_parts = uploaded_files + [prompt]
    
    print(f"🔄 {count} soru üretiliyor...")
    
    try:
        response = model.generate_content(content_parts)
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
        print(f"✅ {len(questions)} soru üretildi!")
        
        # Yüklenen dosyaları temizle
        for f in uploaded_files:
            try:
                genai.delete_file(f.name)
            except:
                pass
        
        return questions
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON parse hatası: {e}")
        print(f"   Ham yanıt:\n{response_text[:500]}")
        return []
    except Exception as e:
        print(f"❌ API hatası: {e}")
        return []


def validate_questions(questions: list, topic: dict) -> list:
    """Soruları doğrula"""
    valid = []
    
    for i, q in enumerate(questions):
        # Zorunlu alanlar
        if not q.get('stem') or len(q.get('stem', '')) < 20:
            print(f"   ⚠️ Soru {i+1}: stem çok kısa, atlanıyor")
            continue
        
        if not q.get('options') or len(q.get('options', [])) != 5:
            print(f"   ⚠️ Soru {i+1}: 5 şık gerekli, atlanıyor")
            continue
        
        if q.get('correctIndex') is None or q['correctIndex'] not in [0, 1, 2, 3, 4]:
            print(f"   ⚠️ Soru {i+1}: correctIndex geçersiz, atlanıyor")
            continue
        
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
        
        # Timestamp ekle
        q['createdAt'] = firestore.SERVER_TIMESTAMP
        q['updatedAt'] = firestore.SERVER_TIMESTAMP
        q['source'] = 'AI Generated'
        
        valid.append(q)
    
    return valid


def save_to_firestore(questions: list, dry_run: bool = True, retry_count: int = 0):
    """Soruları Firestore'a kaydet - retry logic ile"""
    
    if dry_run:
        print(f"\n📝 DRY RUN - {len(questions)} soru kaydedilecek (simülasyon)")
        for i, q in enumerate(questions[:3]):
            print(f"   {i+1}. {q['stem'][:60]}...")
        return
    
    print(f"\n💾 Firestore'a {len(questions)} soru kaydediliyor...")
    
    try:
        batch = db.batch()
        count = 0
        
        for q in questions:
            doc_ref = db.collection('questions').document()
            batch.set(doc_ref, q)
            count += 1
            
            if count >= 450:
                batch.commit()
                print(f"   Batch commit: {count} soru")
                time.sleep(2)  # Batch arası bekleme
                batch = db.batch()
                count = 0
        
        if count > 0:
            batch.commit()
        
        print(f"✅ {len(questions)} soru kaydedildi!")
        
    except Exception as e:
        if 'Quota exceeded' in str(e) or 'RESOURCE_EXHAUSTED' in str(e):
            if retry_count < MAX_RETRIES:
                print(f"   ⚠️ Firestore quota aşıldı, {RETRY_DELAY}s bekleniyor...")
                time.sleep(RETRY_DELAY)
                return save_to_firestore(questions, dry_run, retry_count + 1)
            else:
                print(f"   ❌ Max retry aşıldı, sorular kaydedilemedi!")
        raise e


# ============================================
# MAIN
# ============================================

def main():
    parser = argparse.ArgumentParser(description='Sorusuz konular için soru üret')
    parser.add_argument('--list', action='store_true', help='Sorusuz konuları listele')
    parser.add_argument('--subject', type=str, help='Belirli ders için üret (örn: icra_iflas)')
    parser.add_argument('--count', type=int, default=10, help='Konu başına soru sayısı')
    parser.add_argument('--all', action='store_true', help='Tüm dersler için üret')
    parser.add_argument('--apply', action='store_true', help='Firebase\'e kaydet')
    parser.add_argument('--limit', type=int, default=5, help='Maksimum konu sayısı')
    parser.add_argument('--start-from', type=str, help='Bu topic adından başla')
    parser.add_argument('--skip', type=str, action='append', default=[], help='Bu topic adlarını atla')
    parser.add_argument('--use-cache', action='store_true', help='Cache dosyasından oku (Firestore sorgusunu atla)')
    parser.add_argument('--skip-existing-check', action='store_true', help='Mevcut soru kontrolünü atla (Firestore tasarrufu)')
    
    args = parser.parse_args()
    
    # Cache kullan mı?
    if args.use_cache:
        print("📋 Cache dosyasından sorusuz konular okunuyor...")
        topics_without_questions, by_subject, subjects = get_topics_from_cache()
        if topics_without_questions is None:
            print(f"❌ Cache dosyası bulunamadı: {TOPICS_CACHE_FILE}")
            return
        print(f"   ✓ Cache'den {len(topics_without_questions)} topic okundu")
    else:
        print("🔍 Firestore'dan sorusuz konular alınıyor...")
        
        # Retry logic ile topic'leri al
        for retry in range(MAX_RETRIES):
            try:
                topics_without_questions, by_subject, subjects = get_topics_without_questions()
                break
            except Exception as e:
                if 'Quota exceeded' in str(e) or 'RESOURCE_EXHAUSTED' in str(e):
                    if retry < MAX_RETRIES - 1:
                        print(f"⚠️ Firestore quota aşıldı, {RETRY_DELAY}s bekleniyor... (deneme {retry+1}/{MAX_RETRIES})")
                        time.sleep(RETRY_DELAY)
                    else:
                        print(f"❌ Firestore quota aşıldı ve max retry aşıldı. Lütfen birkaç dakika bekleyip tekrar deneyin.")
                        print(f"💡 Cache kullanmak için: --use-cache parametresi ekleyin")
                        return
                else:
                    raise e
    
    print(f"\n📊 Toplam {len(topics_without_questions)} sorusuz konu bulundu")
    
    if args.list:
        print("\n" + "="*60)
        print("SORUSUZ KONULAR")
        print("="*60)
        
        for subj_id, topics in sorted(by_subject.items()):
            subj_name = subjects.get(subj_id, {}).get('name', subj_id)
            print(f"\n📚 {subj_name} ({subj_id}): {len(topics)} konu")
            for t in topics[:10]:
                print(f"   - {t['name']}")
            if len(topics) > 10:
                print(f"   ... ve {len(topics) - 10} konu daha")
        return
    
    # Üretilecek konuları belirle
    topics_to_generate = []
    
    if args.subject:
        topics_to_generate = by_subject.get(args.subject, [])
        if not topics_to_generate:
            print(f"❌ '{args.subject}' için sorusuz konu bulunamadı")
            return
    elif args.all:
        topics_to_generate = topics_without_questions
    else:
        print("Kullanım: --list, --subject <ders_id>, veya --all")
        return
    
    # --start-from: Belirli bir topic'ten başla
    if args.start_from:
        start_idx = -1
        for i, t in enumerate(topics_to_generate):
            if args.start_from.lower() in t['name'].lower():
                start_idx = i
                print(f"📍 '{t['name']}' topic'inden başlanıyor (index: {i})")
                break
        if start_idx == -1:
            print(f"⚠️ '{args.start_from}' bulunamadı, baştan başlanıyor")
        else:
            topics_to_generate = topics_to_generate[start_idx:]
    
    # --skip: Belirli topic'leri atla
    if args.skip:
        skip_names = [s.lower() for s in args.skip]
        original_len = len(topics_to_generate)
        topics_to_generate = [t for t in topics_to_generate 
                             if not any(skip in t['name'].lower() for skip in skip_names)]
        skipped = original_len - len(topics_to_generate)
        if skipped > 0:
            print(f"⏭️ {skipped} topic atlandı")
    
    # Limit uygula
    topics_to_generate = topics_to_generate[:args.limit]
    
    print(f"\n🚀 {len(topics_to_generate)} konu için soru üretilecek")
    print(f"   Konu başına: {args.count} soru")
    print(f"   Mod: {'GERÇEK (Firebase)' if args.apply else 'DRY RUN'}")
    print(f"   Rate limit: {RATE_LIMIT_DELAY}s topic arası bekleme")
    if args.skip_existing_check:
        print(f"   ⏭️ Mevcut soru kontrolü: ATLANACAK")
    
    all_questions = []
    processed_count = 0
    failed_topics = []
    
    for i, topic in enumerate(topics_to_generate):
        print(f"\n[{i+1}/{len(topics_to_generate)}] İşleniyor: {topic['name']}")
        
        for retry in range(MAX_RETRIES):
            try:
                questions = generate_questions_for_topic(
                    topic, 
                    subjects.get(topic['subjectId'], {}), 
                    args.count,
                    skip_existing_check=args.skip_existing_check
                )
                
                if questions:
                    valid_questions = validate_questions(questions, topic)
                    all_questions.extend(valid_questions)
                    print(f"   ✓ {len(valid_questions)} geçerli soru")
                    
                    # Her topic'in sorularını hemen kaydet
                    if args.apply and valid_questions:
                        save_to_firestore(valid_questions, dry_run=False)
                
                processed_count += 1
                break  # Başarılı, retry loop'tan çık
                
            except Exception as e:
                error_str = str(e)
                if 'Quota exceeded' in error_str or 'RESOURCE_EXHAUSTED' in error_str or '429' in error_str:
                    if retry < MAX_RETRIES - 1:
                        print(f"   ⚠️ Quota aşıldı, {RETRY_DELAY}s bekleniyor... (deneme {retry+1}/{MAX_RETRIES})")
                        time.sleep(RETRY_DELAY)
                    else:
                        print(f"   ❌ '{topic['name']}' için max retry aşıldı, atlanıyor")
                        failed_topics.append(topic['name'])
                else:
                    print(f"   ❌ Hata: {e}")
                    failed_topics.append(topic['name'])
                    break
        
        # Rate limit - her topic arasında bekle
        if i < len(topics_to_generate) - 1:  # Son topic değilse
            print(f"   ⏳ Rate limit: {RATE_LIMIT_DELAY}s bekleniyor...")
            time.sleep(RATE_LIMIT_DELAY)
    
    print(f"\n{'='*60}")
    print(f"ÖZET")
    print(f"{'='*60}")
    print(f"İşlenen topic: {processed_count}/{len(topics_to_generate)}")
    print(f"Toplam üretilen: {len(all_questions)} soru")
    
    if failed_topics:
        print(f"\n⚠️ Başarısız topic'ler ({len(failed_topics)}):")
        for ft in failed_topics:
            print(f"   - {ft}")
        print(f"\nBunları tekrar denemek için:")
        print(f"   python generate_missing_questions.py --all --count {args.count} --start-from \"{failed_topics[0]}\" --apply")
    
    if all_questions and not args.apply:
        print(f"\n💡 Gerçek kayıt için --apply ekleyin")


if __name__ == '__main__':
    main()
