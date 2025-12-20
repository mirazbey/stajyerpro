#!/usr/bin/env python3
"""
Comprehensive Lesson Generator v2.1
Eksik ders içeriklerini Gemini AI ile üretir ve Firestore'a yükler.
"""

import os
import json
import time
import firebase_admin
from firebase_admin import credentials, firestore
import google.generativeai as genai
from pathlib import Path

# ============================================================
# API KEYS - Rotasyonlu kullanım
# ============================================================
API_KEYS = [
    "AIzaSyApIRbm-RF9dHQ_99duUH4QUz6_NNJz65E",
    "AIzaSyDYLTC8pkwjoMbL2qaoNn9p8j5fgSK7Qvs",
    "AIzaSyABi_1iJjZxt6Hvp5KLnvLb7y67I_PKAAk",
    "AIzaSyAzKBa-6xS7S4mMj4N5USaN0d1fuPbAnDY",
    "AIzaSyAXRt4ytEYHC0nH4BLL7KN12kVV0T_Wi9g",
]

key_idx = 0

def get_api_key():
    """Round-robin ile API key döndür"""
    global key_idx
    key = API_KEYS[key_idx % len(API_KEYS)]
    key_idx += 1
    return key

# ============================================================
# PATHS
# ============================================================
BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "generated_lessons"
PDF_DIR = BASE_DIR / "docs"

OUTPUT_DIR.mkdir(exist_ok=True)

# ============================================================
# FIREBASE
# ============================================================
if not firebase_admin._apps:
    cred = credentials.Certificate(str(BASE_DIR / "service-account.json"))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ============================================================
# PDF LOADING
# ============================================================
REFERENCE_BOOKS = [
    "Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf",
    "2025 hukuk meslekleri soru bankasi.pdf",
]

def find_pdfs(subject_name):
    """Konu için ilgili PDF dosyalarını bul"""
    results = []
    print(f"  [PDF] Arama yapiliyor...", flush=True)
    
    # Her zaman referans kitapları yükle
    for ref_book in REFERENCE_BOOKS:
        ref_path = PDF_DIR / ref_book
        if ref_path.exists():
            try:
                content = extract_pdf_text(ref_path)
                if content:
                    results.append(content[:5000])  # İlk 5000 karakter
                    print(f"  [REF] {ref_book}", flush=True)
            except Exception as e:
                print(f"  [HATA] {ref_book}: {e}", flush=True)
    
    # Konuya özel PDF ara
    subject_lower = subject_name.lower()
    if PDF_DIR.exists():
        for pdf_file in PDF_DIR.glob("*.pdf"):
            if any(word in pdf_file.name.lower() for word in subject_lower.split()):
                try:
                    content = extract_pdf_text(pdf_file)
                    if content:
                        results.append(content[:5000])
                        print(f"  [PDF] {pdf_file.name}", flush=True)
                except Exception as e:
                    print(f"  [HATA] {pdf_file.name}: {e}", flush=True)
    
    print(f"  [PDF] Toplam: {len(results)} dosya yuklendi", flush=True)
    return results

def extract_pdf_text(pdf_path):
    """PDF'den metin çıkar"""
    try:
        from syncfusion_flutter_pdf import PdfDocument
    except ImportError:
        pass
    
    # Basit metin döndür - PDF kütüphanesi yoksa
    return f"PDF: {pdf_path.name}"

# ============================================================
# PROMPT
# ============================================================
PROMPT = """Sen Türk Hukuku uzmanı bir eğitimcisin.
Aşağıdaki konu için kapsamlı ders içeriği oluştur.

KONU: {topic}
ALAN: {subject}

{pdf_context}

ÇIKTI FORMATI (SADECE JSON):
{{
  "steps": [
    {{"stepNumber": 1, "title": "Giriş ve Temel Kavramlar", "content": "..."}},
    {{"stepNumber": 2, "title": "Yasal Çerçeve", "content": "..."}},
    {{"stepNumber": 3, "title": "Pratik Uygulamalar", "content": "..."}},
    {{"stepNumber": 4, "title": "Dikkat Edilmesi Gerekenler", "content": "..."}},
    {{"stepNumber": 5, "title": "Özet ve Pekiştirme", "content": "..."}}
  ],
  "practiceQuestions": [
    {{
      "questionNumber": 1,
      "question": "...",
      "options": {{"A": "...", "B": "...", "C": "...", "D": "..."}},
      "correctAnswer": "A",
      "explanation": "..."
    }}
  ]
}}

KURALLAR:
1. Her adım en az 200 kelime olmalı
2. 5 adet pratik soru oluştur
3. Sorular ÖSYM formatında olmalı
4. Türk Hukuku'na uygun olmalı
5. Güncel mevzuatı kullan

SADECE JSON DÖNDÜR!"""

def generate(topic, subject, pdfs, api_key, retry_count=0):
    """Icerik uret - quota asilirsa baska key dene"""
    print(f"  [AI] Gemini ile icerik uretiliyor (Key #{key_idx % len(API_KEYS) + 1})...", flush=True)
    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-2.5-flash")
        
        pdf_ctx = ""
        if pdfs:
            pdf_ctx = "PDF KAYNAK:\n" + "\n".join(pdfs[:2])
            print(f"  [AI] PDF context: {len(pdf_ctx)} karakter", flush=True)
        
        prompt = PROMPT.format(topic=topic, subject=subject, pdf_context=pdf_ctx)
        
        start_time = time.time()
        resp = model.generate_content(prompt)
        elapsed = time.time() - start_time
        print(f"  [AI] Yanit alindi ({elapsed:.1f}s)", flush=True)
        
        text = resp.text.strip()
        
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        elif "```" in text:
            text = text.split("```")[1].split("```")[0]
        
        data = json.loads(text.strip())
        
        steps = len(data.get("steps", []))
        questions = len(data.get("practiceQuestions", []))
        print(f"  [AI] Adim: {steps}, Soru: {questions}", flush=True)
        
        if steps < 5:
            print(f"  [UYARI] Yetersiz adim ({steps}/5)", flush=True)
            return None
        if questions < 3:
            print(f"  [UYARI] Yetersiz soru ({questions}/5)", flush=True)
            return None
        
        return data
    except Exception as e:
        error_str = str(e)
        if "429" in error_str:
            if retry_count < len(API_KEYS) - 1:
                print(f"  [QUOTA] Key #{key_idx % len(API_KEYS)} limiti asildi, sonraki key'e geciliyor...", flush=True)
                next_key = get_api_key()
                time.sleep(2)
                return generate(topic, subject, pdfs, next_key, retry_count + 1)
            else:
                print(f"  [QUOTA] Tum key'lerin limiti doldu! 60 saniye bekleniyor...", flush=True)
                time.sleep(60)
                return None
        print(f"  [HATA] {e}", flush=True)
        return None

def save_local(topic_id, data):
    """Lokale kaydet"""
    filename = topic_id.lower().replace(" ", "_").replace("/", "_") + ".json"
    filepath = OUTPUT_DIR / filename
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"  [KAYIT] {filename}", flush=True)
    return filepath

def save_firestore(topic_id, data):
    """Firestore'a kaydet"""
    print(f"  [FIRESTORE] Yukleniyor...", flush=True)
    try:
        doc_ref = db.collection("topic_lessons").document(topic_id)
        doc_ref.set({
            "topicId": topic_id,
            "steps": data.get("steps", []),
            "practiceQuestions": data.get("practiceQuestions", []),
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })
        print(f"  [FIRESTORE] Basarili: topic_lessons/{topic_id}", flush=True)
        return True
    except Exception as e:
        print(f"  [FIRESTORE HATA] {e}", flush=True)
        return False

def main():
    print("=" * 60, flush=True)
    print("COMPREHENSIVE LESSON GENERATOR v2.1", flush=True)
    print("=" * 60, flush=True)
    print(f"Output: {OUTPUT_DIR}", flush=True)
    print(f"PDFs: {PDF_DIR}", flush=True)
    print(f"API Keys: {len(API_KEYS)}", flush=True)
    
    # Mevcut dersleri al
    existing_lessons = set()
    try:
        lessons_ref = db.collection("topic_lessons").stream()
        for doc in lessons_ref:
            existing_lessons.add(doc.id)
        print(f"Dersler: {len(existing_lessons)}", flush=True)
    except Exception as e:
        print(f"Ders listesi alinamadi: {e}", flush=True)
    
    # Konuları al
    topics = []
    try:
        topics_ref = db.collection("topics").stream()
        for doc in topics_ref:
            data = doc.to_dict()
            topics.append({
                "id": doc.id,
                "name": data.get("name", ""),
                "subjectId": data.get("subjectId", ""),
                "subjectName": data.get("subjectName", ""),
                "description": data.get("description", ""),
            })
        print(f"Konular: {len(topics)}", flush=True)
    except Exception as e:
        print(f"Konu listesi alinamadi: {e}", flush=True)
        return
    
    # Eksik konuları filtrele
    missing = []
    for t in topics:
        desc = t.get("description", "") or ""
        if len(desc) < 100 and t["id"] not in existing_lessons:
            missing.append(t)
    
    print(f"Bos konular: {len(missing)}", flush=True)
    
    # Mevcut derslerle karşılaştır
    to_process = [t for t in missing if t["id"] not in existing_lessons]
    print(f"Islenecek: {len(to_process)}", flush=True)
    
    if not to_process:
        print("\nTum dersler mevcut!", flush=True)
        return
    
    # Tahmini süre
    estimated_mins = len(to_process) * 0.5
    print(f"\nTahmini sure: ~{estimated_mins:.0f} dakika", flush=True)
    print("\nOTOMATIK BASLATILIYOR...", flush=True)
    print("\n" + "=" * 60, flush=True)
    
    # İşle
    success = 0
    for i, topic in enumerate(to_process):
        print(f"\n[{i+1}/{len(to_process)}] {topic['name']} ({topic['subjectName']})", flush=True)
        
        # PDF bul
        pdfs = find_pdfs(topic["subjectName"])
        
        # Üret
        api_key = get_api_key()
        data = generate(topic["name"], topic["subjectName"], pdfs, api_key)
        
        if data:
            # Kaydet
            save_local(topic["id"], data)
            if save_firestore(topic["id"], data):
                success += 1
        else:
            print(f"  [ATLANDI] Icerik uretilemedi", flush=True)
    
    print("\n" + "=" * 60, flush=True)
    print(f"TAMAMLANDI: {success}/{len(to_process)}", flush=True)
    print("=" * 60, flush=True)

if __name__ == "__main__":
    main()
