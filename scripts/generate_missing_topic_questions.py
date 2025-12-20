"""
Sorusuz Konular için Soru Üretim Scripti
Bu script topics_needing_questions.json dosyasını okur ve her konu için
Gemini 2.5 Flash kullanarak soru üretir.

Kullanım:
    python generate_missing_topic_questions.py --dry-run    # Önizleme
    python generate_missing_topic_questions.py --apply       # Firestore'a yaz
    python generate_missing_topic_questions.py --subject icra_iflas --apply  # Tek ders
"""

import os
import sys
import json
import argparse
import time
from datetime import datetime
from pathlib import Path

# Proje kök dizinini ekle
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    import google.generativeai as genai
except ImportError:
    print("❌ google-generativeai paketi yüklü değil!")
    print("   Yüklemek için: pip install google-generativeai")
    exit(1)

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ firebase-admin paketi yüklü değil!")
    exit(1)

# ============================================
# KONFIGÜRASYON
# ============================================

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyApIRbm-RF9dHQ_99duUH4QUz6_NNJz65E")
MODEL_NAME = "gemini-2.5-flash-preview-05-20"

BASE_DIR = Path(__file__).parent.parent if Path(__file__).parent.name == "scripts" else Path(__file__).parent
DOCS_DIR = BASE_DIR / "docs"
SERVICE_ACCOUNT = BASE_DIR / "service-account.json"

# Firebase başlat
if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Gemini API
genai.configure(api_key=GEMINI_API_KEY)

# ============================================
# DERS KODLARI EŞLEŞMESİ
# ============================================

SUBJECT_ID_MAP = {
    "Anayasa Hukuku": "anayasa_hukuku",
    "Avukatlık Hukuku": "avukatlik_hukuku",
    "Borçlar Hukuku": "borclar_hukuku",
    "Ceza Hukuku": "ceza_hukuku",
    "Ceza Muhakemesi Hukuku": "ceza_muhakemesi",
    "Hukuk Felsefesi ve Sosyolojisi": "hukuk_felsefesi",
    "İcra ve İflas Hukuku": "icra_iflas",
    "İdare Hukuku": "idare_hukuku",
    "İdari Yargılama Usulü (İYUK)": "idari_yargilama",
    "İş Hukuku ve Sosyal Güvenlik": "is_hukuku",
    "Medeni Hukuk": "medeni_hukuku",
    "Milletlerarası Hukuk": "milletlerarasi_hukuk",
    "Milletlerarası Özel Hukuk (MÖHUK)": "mohuk",
    "Ticaret Hukuku": "ticaret_hukuku",
    "Vergi Hukuku": "vergi_hukuku"
}

# ============================================
# PDF YÖNETİMİ
# ============================================

def get_pdfs_for_subject(subject_id: str) -> list:
    """Derse göre ilgili PDF'leri bul"""
    
    if not DOCS_DIR.exists():
        print(f"⚠️ docs/ klasörü bulunamadı: {DOCS_DIR}")
        return []
    
    all_pdfs = list(DOCS_DIR.glob("*.pdf"))
    
    # Anahtar kelime eşleştirme
    keyword_map = {
        "anayasa_hukuku": ["anayasa"],
        "avukatlik_hukuku": ["avukatlık", "baro", "hmgs"],
        "borclar_hukuku": ["borçlar", "tbk"],
        "ceza_hukuku": ["ceza kanunu", "tck", "ceza hukuku"],
        "ceza_muhakemesi": ["muhakemesi", "cmk"],
        "hukuk_felsefesi": ["felsefe", "sosyoloji"],
        "icra_iflas": ["icra", "iflas", "iik"],
        "idare_hukuku": ["idare"],
        "idari_yargilama": ["yargılama", "iyuk"],
        "is_hukuku": ["iş kanunu", "iş hukuku", "sosyal"],
        "medeni_hukuk": ["medeni", "tmk"],
        "milletlerarasi_hukuk": ["milletlerarası hukuk"],
        "mohuk": ["milletlerarası özel", "möhuk"],
        "ticaret_hukuku": ["ticaret", "ttk"],
        "vergi_hukuku": ["vergi"]
    }
    
    keywords = keyword_map.get(subject_id, [])
    matched = []
    
    for pdf in all_pdfs:
        pdf_lower = pdf.name.lower()
        for kw in keywords:
            if kw.lower() in pdf_lower:
                matched.append(pdf)
                break
    
    # Soru bankası ve yargı paketi - herkese ekle
    for pdf in all_pdfs:
        pdf_lower = pdf.name.lower()
        if "soru-bankasi" in pdf_lower or "yargı paketi" in pdf_lower or "yargi paketi" in pdf_lower:
            if pdf not in matched:
                matched.append(pdf)
    
    return matched


def upload_pdf_to_gemini(pdf_path: Path):
    """PDF'i Gemini'ye yükle"""
    try:
        print(f"   📤 Yükleniyor: {pdf_path.name}")
        uploaded = genai.upload_file(str(pdf_path), mime_type="application/pdf")
        
        # İşlenmesini bekle
        while uploaded.state.name == "PROCESSING":
            time.sleep(2)
            uploaded = genai.get_file(uploaded.name)
        
        if uploaded.state.name == "FAILED":
            print(f"   ❌ Yükleme başarısız: {pdf_path.name}")
            return None
        
        return uploaded
    except Exception as e:
        print(f"   ❌ Hata: {e}")
        return None


# ============================================
# SORU ÜRETİMİ
# ============================================

def create_topic_prompt(topic_name: str, topic_id: str, subject_name: str, subject_id: str, count: int = 3) -> str:
    """Konu için soru üretim promptu"""
    
    timestamp = datetime.now().isoformat() + "Z"
    
    prompt = f"""
# GÖREV
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için profesyonel soru yazarısın.
"{subject_name}" dersi altındaki "{topic_name}" konusu için {count} adet ÖZGÜN çoktan seçmeli soru üret.

# KAYNAK PDF'LER
Yukarıda yüklenen PDF dosyalarını analiz et ve "{topic_name}" konusuyla ilgili:
- Kanun maddelerini doğru şekilde kullan
- Tanımları ve kavramları referans al
- Güncel değişiklikleri (9. Yargı Paketi vb.) varsa dikkate al

# ZORUNLU JSON FORMATI
Her soru için TAM OLARAK bu formatı kullan:

```json
{{
  "stem": "Soru metni - en az 30 karakter, açık ve net olmalı, '{topic_name}' konusuyla ilgili olmalı",
  "options": ["A şıkkı metni", "B şıkkı metni", "C şıkkı metni", "D şıkkı metni", "E şıkkı metni"],
  "correctIndex": 0,
  "explanation": "Detaylı açıklama - neden doğru cevabın doğru olduğunu açıkla, diğer şıkların neden yanlış olduğunu belirt",
  "lawArticle": "İlgili kanun maddesi (örn: İİK m.35) veya null",
  "difficulty": "medium",
  "source": "AI Generated - Gemini",
  "subjectId": "{subject_id}",
  "topicIds": ["{topic_id}"]
}}
```

# ZORUNLU KURALLAR

1. **Konu Odaklı**: Sorular MUTLAKA "{topic_name}" konusuyla DOĞRUDAN ilgili olmalı
2. **stem**: En az 30 karakter, soru işareti ile bitmeli
3. **options**: TAM 5 şık (A-E), mantıklı çeldiriciler, her biri farklı olmalı
4. **correctIndex**: 0-4 arası (0=A, 1=B, 2=C, 3=D, 4=E)
5. **explanation**: Öğretici olmalı, en az 50 karakter
6. **difficulty**: "easy", "medium" veya "hard"
7. **lawArticle**: Varsa ilgili kanun maddesi, yoksa null

# SORU TÜRLERİ
Çeşitlilik için farklı soru türleri kullan:
- Tanım soruları ("'{topic_name}' kapsamında X kavramı nedir?")
- Uygulama ("'{topic_name}'e göre bu durumda hangi hüküm uygulanır?")
- Karşılaştırma ("'{topic_name}' açısından aşağıdakilerden hangisi farklıdır?")
- Negatif ("'{topic_name}'de aşağıdakilerden hangisi söylenemez?")

# ÇIKTI
SADECE JSON array döndür, başka açıklama ekleme:
[soru1, soru2, soru3]
"""
    return prompt


def generate_questions_for_topic(topic: dict, pdf_files: list, count: int = 3) -> list:
    """Tek bir konu için soru üret"""
    
    topic_id = topic['id']
    topic_name = topic['name']
    subject_id = topic['subjectId']
    subject_name = topic.get('subjectName', subject_id)
    
    print(f"\n   🔄 '{topic_name}' için {count} soru üretiliyor...")
    
    # PDF'leri yükle
    uploaded_files = []
    for pdf_path in pdf_files[:3]:  # Max 3 PDF
        uploaded = upload_pdf_to_gemini(pdf_path)
        if uploaded:
            uploaded_files.append(uploaded)
    
    if not uploaded_files:
        print(f"   ⚠️ PDF yüklenemedi, PDF'siz üretim deneniyor...")
    
    # Model oluştur
    model = genai.GenerativeModel(
        model_name=MODEL_NAME,
        generation_config={
            "temperature": 0.9,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 8192,
        }
    )
    
    # Prompt oluştur
    prompt = create_topic_prompt(topic_name, topic_id, subject_name, subject_id, count)
    
    # İçerik hazırla
    content_parts = uploaded_files + [prompt] if uploaded_files else [prompt]
    
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
        
        # Validate ve düzelt
        valid_questions = []
        for q in questions:
            # Gerekli alanları kontrol et
            if not q.get('stem') or len(q.get('options', [])) != 5:
                continue
            
            # Varsayılan değerler ekle
            q['subjectId'] = subject_id
            q['topicIds'] = [topic_id]
            q['source'] = q.get('source', 'AI Generated - Gemini')
            q['difficulty'] = q.get('difficulty', 'medium')
            q['createdAt'] = firestore.SERVER_TIMESTAMP
            q['updatedAt'] = firestore.SERVER_TIMESTAMP
            
            valid_questions.append(q)
        
        print(f"   ✅ {len(valid_questions)} geçerli soru üretildi")
        
        # Temizlik
        for f in uploaded_files:
            try:
                genai.delete_file(f.name)
            except:
                pass
        
        return valid_questions
        
    except json.JSONDecodeError as e:
        print(f"   ❌ JSON parse hatası: {e}")
        return []
    except Exception as e:
        print(f"   ❌ API hatası: {e}")
        return []


def save_questions_to_firestore(questions: list) -> int:
    """Soruları Firestore'a kaydet"""
    
    saved = 0
    batch = db.batch()
    
    for q in questions:
        doc_ref = db.collection('questions').document()
        batch.set(doc_ref, q)
        saved += 1
        
        # Batch limiti
        if saved % 400 == 0:
            batch.commit()
            batch = db.batch()
    
    if saved % 400 != 0:
        batch.commit()
    
    return saved


# ============================================
# ANA FONKSİYON
# ============================================

def main():
    parser = argparse.ArgumentParser(description='Sorusuz konular için soru üret')
    parser.add_argument('--dry-run', action='store_true', help='Önizleme - Firestore\'a yazmaz')
    parser.add_argument('--apply', action='store_true', help='Firestore\'a yaz')
    parser.add_argument('--subject', type=str, help='Sadece belirli ders (örn: icra_iflas)')
    parser.add_argument('--count', type=int, default=3, help='Konu başına soru sayısı')
    parser.add_argument('--limit', type=int, help='Maksimum konu sayısı')
    args = parser.parse_args()
    
    if not args.apply and not args.dry_run:
        args.dry_run = True
    
    print("=" * 70)
    print("SORUSUZ KONULAR İÇİN SORU ÜRETİMİ")
    print("=" * 70)
    print(f"Mod: {'DRY RUN' if args.dry_run else 'APPLY (Firestore yazılacak)'}")
    print(f"Konu başına soru: {args.count}")
    if args.subject:
        print(f"Filtre: {args.subject}")
    print()
    
    # Sorusuz konuları yükle
    topics_file = BASE_DIR / "topics_needing_questions.json"
    if not topics_file.exists():
        print("❌ topics_needing_questions.json bulunamadı!")
        print("   Önce çalıştırın: python find_topics_without_questions.py")
        return
    
    with open(topics_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    all_topics = data.get('all_topics', [])
    print(f"📊 Toplam sorusuz konu: {len(all_topics)}")
    
    # Filtrele
    if args.subject:
        all_topics = [t for t in all_topics if t['subjectId'] == args.subject]
        print(f"   Filtrelenmiş: {len(all_topics)} konu ({args.subject})")
    
    if args.limit:
        all_topics = all_topics[:args.limit]
        print(f"   Limit: {len(all_topics)} konu")
    
    if not all_topics:
        print("⚠️ İşlenecek konu yok!")
        return
    
    # Subject bazında grupla
    topics_by_subject = {}
    for t in all_topics:
        subj = t['subjectId']
        if subj not in topics_by_subject:
            topics_by_subject[subj] = []
        topics_by_subject[subj].append(t)
    
    total_generated = 0
    total_saved = 0
    
    for subject_id, topics in topics_by_subject.items():
        print(f"\n{'='*60}")
        print(f"📚 {subject_id}: {len(topics)} konu")
        print("=" * 60)
        
        # PDF'leri bul
        pdfs = get_pdfs_for_subject(subject_id)
        print(f"   📄 {len(pdfs)} PDF bulundu")
        
        for topic in topics:
            questions = generate_questions_for_topic(topic, pdfs, args.count)
            total_generated += len(questions)
            
            if questions and args.apply:
                saved = save_questions_to_firestore(questions)
                total_saved += saved
                print(f"   💾 {saved} soru Firestore'a kaydedildi")
            
            # Rate limiting
            time.sleep(2)
    
    print("\n" + "=" * 70)
    print("ÖZET")
    print("=" * 70)
    print(f"Üretilen toplam soru: {total_generated}")
    if args.apply:
        print(f"Firestore'a kaydedilen: {total_saved}")
    else:
        print("(DRY RUN - Firestore'a yazılmadı)")


if __name__ == '__main__':
    main()
