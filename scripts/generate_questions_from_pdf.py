"""
HMGS Soru Üretimi - PDF'den AI ile Soru Oluşturma
Bu script, docs/ klasöründeki PDF'leri okur ve Gemini API ile HMGS tarzı sorular üretir.
"""

import os
import json
import argparse
from pathlib import Path
import google.generativeai as genai
from PyPDF2 import PdfReader
from datetime import datetime

# Gemini API Key (environment variable'dan al)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("⚠️ GEMINI_API_KEY environment variable bulunamadı!")
    print("Kullanım: export GEMINI_API_KEY='your-api-key'")
    exit(1)

genai.configure(api_key=GEMINI_API_KEY)

# Prompt Template
QUESTION_GENERATION_PROMPT = """
Sen bir HMGS (Hukuk Mesleklerine Giriş Sınavı) soru yazarısın. 

Aşağıdaki hukuk metni veriyorum. Bu metinden **{num_questions} adet** HMGS tarzında çoktan seçmeli soru üret.

---
METİN:
{text_content}
---

KURALLAR:
1. Her soru 5 şıklı olmalı (A, B, C, D, E)
2. Sadece 1 doğru cevap olmalı
3. Çeldirici şıklar gerçekçi olmalı (öğrenci karıştırabilmeli)
4. Soru HMGS seviyesinde olmalı (çok kolay veya çok zor değil)
5. Kanun maddesi referansı ekle
6. Detaylı açıklama + yanlış şıkların neden yanlış olduğunu yaz

OUTPUT FORMAT (JSON):
```json
[
  {{
    "stem": "Soru metni...",
    "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
    "correctIndex": 0,
    "difficulty": "medium",
    "lawArticle": "TMK m. 186",
    "detailedExplanation": "Doğru cevabın açıklaması...",
    "wrongReasons": {{
      "1": "B şıkkının neden yanlış olduğu...",
      "2": "C şıkkının neden yanlış olduğu...",
      "3": "D şıkkının neden yanlış olduğu...",
      "4": "E şıkkının neden yanlış olduğu..."
    }},
    "subjectId": "medeni_hukuk",
    "topicIds": ["aile_hukuku"]
  }}
]
```

SADECE JSON OUTPUT VER, BAŞKA BİR ŞEY YAZMA.
"""

def extract_text_from_pdf(pdf_path: str, max_pages: int = 50) -> str:
    """PDF'ten metin çıkarır"""
    print(f"📄 PDF okunuyor: {pdf_path}")
    
    try:
        reader = PdfReader(pdf_path)
        text = ""
        
        # İlk N sayfayı al (tüm kitabı işleme, çok uzun olur)
        pages_to_read = min(len(reader.pages), max_pages)
        
        for i in range(pages_to_read):
            page = reader.pages[i]
            text += page.extract_text() + "\n\n"
        
        print(f"✅ {pages_to_read} sayfa okundu ({len(text)} karakter)")
        return text
    
    except Exception as e:
        print(f"❌ PDF okuma hatası: {e}")
        return ""

def chunk_text(text: str, chunk_size: int = 8000) -> list[str]:
    """Metni parçalara böler (Gemini token limiti için)"""
    chunks = []
    words = text.split()
    
    current_chunk = []
    current_length = 0
    
    for word in words:
        current_chunk.append(word)
        current_length += len(word) + 1
        
        if current_length >= chunk_size:
            chunks.append(" ".join(current_chunk))
            current_chunk = []
            current_length = 0
    
    if current_chunk:
        chunks.append(" ".join(current_chunk))
    
    return chunks

def generate_questions_with_gemini(text: str, num_questions: int = 10) -> list:
    """Gemini API ile soru üretir"""
    print(f"🤖 Gemini'ye {num_questions} soru üretimi için istek gönderiliyor...")
    
    model = genai.GenerativeModel('gemini-2.0-flash-exp')
    
    prompt = QUESTION_GENERATION_PROMPT.format(
        text_content=text,
        num_questions=num_questions
    )
    
    try:
        response = model.generate_content(prompt)
        
        # JSON çıktısını parse et
        response_text = response.text.strip()
        
        # Markdown code block'u temizle
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.startswith("```"):
            response_text = response_text[3:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
        
        response_text = response_text.strip()
        
        questions = json.loads(response_text)
        print(f"✅ {len(questions)} soru üretildi")
        
        return questions
    
    except Exception as e:
        print(f"❌ Gemini API hatası: {e}")
        return []

def process_pdf(pdf_path: str, output_dir: str, questions_per_chunk: int = 5):
    """Tek bir PDF'i işler"""
    pdf_name = Path(pdf_path).stem
    
    print(f"\n{'='*60}")
    print(f"📖 İşleniyor: {pdf_name}")
    print(f"{'='*60}\n")
    
    # PDF'ten metin çıkar
    text = extract_text_from_pdf(pdf_path, max_pages=50)
    
    if not text:
        print("⚠️ PDF'den metin çıkarılamadı, atlanıyor.")
        return
    
    # Metni parçalara böl
    chunks = chunk_text(text, chunk_size=6000)
    print(f"📦 Metin {len(chunks)} parçaya bölündü")
    
    all_questions = []
    
    # Her chunk için soru üret
    for i, chunk in enumerate(chunks[:3]):  # İlk 3 chunk (cost control)
        print(f"\n--- Chunk {i+1}/{len(chunks)} işleniyor ---")
        questions = generate_questions_with_gemini(chunk, questions_per_chunk)
        all_questions.extend(questions)
    
    # JSON olarak kaydet
    output_file = Path(output_dir) / f"{pdf_name}_questions.json"
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_questions, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Toplam {len(all_questions)} soru üretildi")
    print(f"💾 Kaydedildi: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='PDF\'lerden HMGS soruları üret')
    parser.add_argument('--pdf', type=str, help='İşlenecek PDF dosyası')
    parser.add_argument('--dir', type=str, default='docs/', help='PDF klasörü')
    parser.add_argument('--output', type=str, default='generated_questions/', help='Çıktı klasörü')
    parser.add_argument('--questions-per-chunk', type=int, default=5, help='Her chunk için soru sayısı')
    
    args = parser.parse_args()
    
    # Output klasörünü oluştur
    os.makedirs(args.output, exist_ok=True)
    
    if args.pdf:
        # Tek PDF işle
        process_pdf(args.pdf, args.output, args.questions_per_chunk)
    else:
        # Klasördeki tüm PDF'leri işle
        docs_dir = Path(args.dir)
        pdf_files = list(docs_dir.glob("*.pdf"))
        
        print(f"📚 {len(pdf_files)} PDF dosyası bulundu")
        
        for pdf_file in pdf_files:
            try:
                process_pdf(str(pdf_file), args.output, args.questions_per_chunk)
            except Exception as e:
                print(f"❌ {pdf_file.name} işlenirken hata: {e}")
                continue

if __name__ == "__main__":
    main()
