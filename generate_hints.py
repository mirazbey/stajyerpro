"""
Mevcut Sorular için AI İpucu (aiTip) Üretim Scripti
Firestore'daki aiTip alanı boş olan sorular için toplu ipucu üretir.

Kullanım:
    python generate_hints.py --list              # aiTip'siz soruları listele
    python generate_hints.py --count 100         # 100 soru için ipucu üret
    python generate_hints.py --all               # Tüm sorular için üret
    python generate_hints.py --apply             # Firebase'e kaydet
    python generate_hints.py --subject icra_iflas --apply  # Belirli ders
"""

import os
import json
import argparse
import time
from datetime import datetime
from collections import defaultdict

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

# Rate limiting
BATCH_SIZE = 5  # Daha küçük batch (API yükünü azalt)
RATE_LIMIT_DELAY = 8  # Her batch arasında saniye
RETRY_DELAY = 60  # Hata sonrası bekleme
MAX_RETRIES = 5  # Retry sayısı

# Genai config
genai.configure(api_key=GEMINI_API_KEY)

# ============================================
# FIRESTORE İŞLEMLERİ
# ============================================

def get_questions_without_hints(subject_filter=None, limit=None):
    """aiTip alanı boş olan soruları getir"""
    
    print("🔍 aiTip'siz sorular aranıyor...")
    
    query = db.collection('questions')
    
    if subject_filter:
        query = query.where('subjectId', '==', subject_filter)
    
    questions = []
    for doc in query.stream():
        data = doc.to_dict()
        data['id'] = doc.id
        
        # aiTip boş veya yok mu?
        if not data.get('aiTip'):
            questions.append(data)
            
            if limit and len(questions) >= limit:
                break
    
    return questions


def get_subjects():
    """Tüm dersleri getir"""
    subjects = {}
    for doc in db.collection('subjects').stream():
        subjects[doc.id] = doc.to_dict()
    return subjects


# ============================================
# İPUCU ÜRETİMİ
# ============================================

def create_batch_hint_prompt(questions: list) -> str:
    """Birden fazla soru için toplu ipucu promptu"""
    
    questions_text = ""
    option_labels = ['A', 'B', 'C', 'D', 'E']
    
    for i, q in enumerate(questions):
        options_str = "\n".join([
            f"{option_labels[j]}) {opt}" 
            for j, opt in enumerate(q.get('options', []))
        ])
        
        questions_text += f"""
---
SORU {i+1} (ID: {q['id']}):
{q.get('stem', '')}

ŞIKLAR:
{options_str}

DOĞRU CEVAP: {option_labels[q.get('correctIndex', 0)]}
---
"""
    
    prompt = f"""
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için uzman bir koçsun.
Aşağıdaki sorular için KISA, PRATİK ve AKILDA KALICI ipuçları üret.

{questions_text}

# KURALLAR
1. Her ipucu MAX 2 cümle (50 kelime altında)
2. Doğru cevabı SÖYLEME, sadece düşünmeye yardımcı ipucu ver
3. Anahtar kelime, kavram farkı veya dikkat edilecek nokta belirt
4. Ezber tekniği veya kısa formül varsa kullan
5. Her sorunun ID'sini AYNEN kullan

# ÇIKTI FORMATI
Sadece JSON döndür:
{{
  "hints": {{
    "SORU_ID_1": "İpucu metni 1",
    "SORU_ID_2": "İpucu metni 2",
    ...
  }}
}}

Örnek ipuçları:
- "Zamanaşımı sorularında 'süre başlangıcı' ifadesine dikkat!"
- "Bu kavram karşılaştırmasında 'tarafların durumu' düşün."
- "Kanun maddesi sayısı: TMK 186, 187, 188 sırasını hatırla."
"""
    return prompt


def generate_hints_for_batch(questions: list, retry_count: int = 0) -> dict:
    """Bir batch soru için ipuçları üret"""
    
    model = genai.GenerativeModel(
        model_name=MODEL_NAME,
        generation_config={
            "temperature": 0.7,
            "top_p": 0.9,
            "max_output_tokens": 4096,
        }
    )
    
    prompt = create_batch_hint_prompt(questions)
    
    try:
        response = model.generate_content([prompt])
        
        # Response kontrolü
        if not response.candidates or not response.candidates[0].content.parts:
            print(f"   ⚠️ Boş yanıt, tekrar deneniyor...")
            if retry_count < MAX_RETRIES:
                time.sleep(10)
                return generate_hints_for_batch(questions, retry_count + 1)
            return {}
        
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
        
        result = json.loads(response_text)
        return result.get('hints', {})
    
    except ValueError as e:
        # response.text erişim hatası
        print(f"   ⚠️ Geçersiz yanıt: {str(e)[:100]}")
        if retry_count < MAX_RETRIES:
            time.sleep(10)
            return generate_hints_for_batch(questions, retry_count + 1)
        return {}
    except json.JSONDecodeError as e:
        print(f"   ❌ JSON parse hatası: {e}")
        print(f"   Ham yanıt:\n{response_text[:300]}...")
        return {}
    except Exception as e:
        error_msg = str(e)
        print(f"   ⚠️ Hata: {error_msg[:150]}")
        if 'quota' in error_msg.lower() or 'rate' in error_msg.lower() or 'resource' in error_msg.lower():
            if retry_count < MAX_RETRIES:
                print(f"   ⏳ Rate limit, {RETRY_DELAY}s bekleniyor... (deneme {retry_count+1}/{MAX_RETRIES})")
                time.sleep(RETRY_DELAY)
                return generate_hints_for_batch(questions, retry_count + 1)
        return {}


def save_hints_to_firestore(hints: dict, dry_run: bool = True):
    """İpuçlarını Firestore'a kaydet"""
    
    if not hints:
        return 0
    
    if dry_run:
        return len(hints)
    
    saved = 0
    failed = 0
    
    for qid, tip in hints.items():
        try:
            doc_ref = db.collection('questions').document(qid)
            doc_ref.update({
                'aiTip': tip,
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            saved += 1
        except Exception as e:
            failed += 1
            if 'NOT_FOUND' not in str(e).upper():
                print(f"   ⚠️ Kayıt hatası {qid}: {e}")
    
    if failed > 0:
        print(f"   ⚠️ {failed} soru kaydedilemedi (silinmiş olabilir)")
    
    return saved


# ============================================
# MAIN
# ============================================

def main():
    parser = argparse.ArgumentParser(description='Mevcut sorular için ipucu üret')
    parser.add_argument('--list', action='store_true', help='İpucusuz soruları listele')
    parser.add_argument('--subject', type=str, help='Belirli ders (örn: icra_iflas)')
    parser.add_argument('--count', type=int, default=50, help='Kaç soru işlenecek')
    parser.add_argument('--all', action='store_true', help='Tüm sorular için üret')
    parser.add_argument('--apply', action='store_true', help='Firebase\'e kaydet')
    parser.add_argument('--batch-size', type=int, default=BATCH_SIZE, help='Batch boyutu')
    
    args = parser.parse_args()
    
    # İpucusuz soruları getir
    limit = None if args.all else args.count
    questions = get_questions_without_hints(
        subject_filter=args.subject,
        limit=limit
    )
    
    print(f"\n📊 Toplam {len(questions)} ipucusuz soru bulundu")
    
    if args.list:
        subjects = get_subjects()
        by_subject = defaultdict(list)
        
        for q in questions:
            by_subject[q.get('subjectId', 'unknown')].append(q)
        
        print("\n" + "="*60)
        print("İPUCUSUZ SORULAR")
        print("="*60)
        
        for subj_id, qs in sorted(by_subject.items()):
            subj_name = subjects.get(subj_id, {}).get('name', subj_id)
            print(f"\n📚 {subj_name}: {len(qs)} soru")
            for q in qs[:3]:
                print(f"   - {q.get('stem', '')[:50]}...")
            if len(qs) > 3:
                print(f"   ... ve {len(qs) - 3} soru daha")
        return
    
    if not questions:
        print("✅ Tüm sorularda ipucu var!")
        return
    
    # Batch'ler halinde işle
    batch_size = args.batch_size
    total_batches = (len(questions) + batch_size - 1) // batch_size
    dry_run = not args.apply
    
    print(f"\n🚀 {len(questions)} soru {total_batches} batch'te işlenecek")
    print(f"   Batch boyutu: {batch_size}")
    print(f"   Kayıt modu: {'GERÇEK' if not dry_run else 'DRY RUN'}")
    print(f"   Tahmini süre: ~{total_batches * (RATE_LIMIT_DELAY + 3)} saniye")
    
    total_saved = 0
    total_failed = 0
    
    for i in range(0, len(questions), batch_size):
        batch_num = i // batch_size + 1
        batch_questions = questions[i:i + batch_size]
        
        print(f"\n📦 Batch {batch_num}/{total_batches} ({len(batch_questions)} soru)")
        
        hints = generate_hints_for_batch(batch_questions)
        
        if hints:
            print(f"   ✓ {len(hints)} ipucu üretildi")
            
            # Her batch'i hemen kaydet (checkpoint)
            if not dry_run:
                saved = save_hints_to_firestore(hints, dry_run=False)
                total_saved += saved
                print(f"   💾 {saved} ipucu kaydedildi (toplam: {total_saved})")
            else:
                total_saved += len(hints)
        else:
            total_failed += len(batch_questions)
            print(f"   ⚠️ Bu batch için ipucu üretilemedi")
        
        # Rate limiting
        if i + batch_size < len(questions):
            time.sleep(RATE_LIMIT_DELAY)
    
    print(f"\n{'='*60}")
    print(f"📈 ÖZET")
    print(f"{'='*60}")
    print(f"   İşlenen soru: {len(questions)}")
    print(f"   Başarılı ipucu: {total_saved}")
    print(f"   Başarısız: {total_failed}")
    print(f"   Başarı oranı: {total_saved/len(questions)*100:.1f}%")
    
    if dry_run:
        print("\n💡 Gerçek kayıt için: --apply parametresi ekleyin")


if __name__ == '__main__':
    main()
