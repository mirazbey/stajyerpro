"""
Gelişmiş HMGS Soru Üretim Sistemi
- Konu bazlı multi-PDF işleme
- Tekrar tespit (deduplication)
- Progress tracking & resume
- Akıllı chunking
"""

import os
import json
import yaml
import hashlib
import argparse
from pathlib import Path
from typing import List, Dict
from datetime import datetime
import google.generativeai as genai
from PyPDF2 import PdfReader
import firebase_admin
from firebase_admin import credentials, firestore
from difflib import SequenceMatcher

# Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("⚠️ GEMINI_API_KEY environment variable bulunamadı!")
    exit(1)

genai.configure(api_key=GEMINI_API_KEY)

class QuestionGenerator:
    def __init__(self, config_file: str):
        """Konfigürasyon dosyasını yükle"""
        with open(config_file, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)
        
        self.docs_dir = Path(self.config['settings']['docs_directory'])
        self.output_dir = Path(self.config['settings']['output_directory'])
        self.output_dir.mkdir(exist_ok=True)
        
        self.progress_file = self.output_dir / "progress.json"
        self.progress = self.load_progress()
        
        # Firestore bağlantısı (deduplication için)
        self.db = None
        if self.config['settings']['enable_deduplication']:
            self.init_firebase()
    
    def init_firebase(self):
        """Firebase'i başlat (deduplication için)"""
        try:
            cred_path = "serviceAccountKey.json"
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                print("✅ Firebase bağlantısı kuruldu (deduplication aktif)")
        except:
            print("⚠️ Firebase bağlanamadı, deduplication devre dışı")
            self.db = None
    
    def load_progress(self) -> Dict:
        """İlerleme dosyasını yükle"""
        if self.progress_file.exists():
            with open(self.progress_file, 'r') as f:
                return json.load(f)
        return {}
    
    def save_progress(self):
        """İlerlemeyi kaydet"""
        with open(self.progress_file, 'w') as f:
            json.dump(self.progress, f, indent=2)
    
    def extract_text_from_multiple_pdfs(self, pdf_files: List[str], max_pages: int) -> str:
        """Birden fazla PDF'i birleştirip metin çıkar"""
        combined_text = ""
        
        for pdf_file in pdf_files:
            pdf_path = self.docs_dir / pdf_file
            
            if not pdf_path.exists():
                print(f"⚠️ PDF bulunamadı: {pdf_file}")
                continue
            
            print(f"  📄 Okunuyor: {pdf_file}")
            
            try:
                reader = PdfReader(str(pdf_path))
                total_pages = len(reader.pages)
                pages_to_read = min(total_pages, max_pages)
                
                for i in range(pages_to_read):
                    page = reader.pages[i]
                    combined_text += page.extract_text() + "\n\n"
                
                print(f"     ✅ {pages_to_read}/{total_pages} sayfa okundu")
            
            except Exception as e:
                print(f"     ❌ Hata: {e}")
        
        return combined_text
    
    def chunk_text(self, text: str, chunk_size: int) -> List[str]:
        """Metni akıllıca parçalara böl (paragraf sınırlarını koruyarak)"""
        paragraphs = text.split('\n\n')
        chunks = []
        current_chunk = []
        current_length = 0
        
        for para in paragraphs:
            para_length = len(para)
            
            if current_length + para_length > chunk_size and current_chunk:
                # Chunk doldu, kaydet
                chunks.append('\n\n'.join(current_chunk))
                current_chunk = [para]
                current_length = para_length
            else:
                current_chunk.append(para)
                current_length += para_length
        
        if current_chunk:
            chunks.append('\n\n'.join(current_chunk))
        
        return chunks
    
    def generate_question_hash(self, question_stem: str) -> str:
        """Soru için benzersiz hash oluştur (deduplication için)"""
        # Soruyu normalize et (küçük harf, boşluk temizle)
        normalized = question_stem.lower().strip()
        normalized = ' '.join(normalized.split())  # Çoklu boşlukları tek boşluk yap
        return hashlib.md5(normalized.encode()).hexdigest()
    
    def is_duplicate_question(self, question_stem: str, subject_id: str) -> bool:
        """Firestore'da benzer soru var mı kontrol et"""
        if not self.db:
            return False
        
        try:
            # Önce hash ile exact match kontrol
            question_hash = self.generate_question_hash(question_stem)
            
            # Firestore'dan bu konuyla ilgili tüm soruları çek
            questions_ref = self.db.collection('questions').where('subjectId', '==', subject_id).limit(500)
            existing_questions = questions_ref.stream()
            
            threshold = self.config['settings']['similarity_threshold']
            
            for doc in existing_questions:
                existing_stem = doc.to_dict().get('stem', '')
                
                # Similarity check
                similarity = SequenceMatcher(None, question_stem.lower(), existing_stem.lower()).ratio()
                
                if similarity > threshold:
                    print(f"     🔁 Benzer soru bulundu (benzerlik: {similarity:.2%})")
                    return True
            
            return False
        
        except Exception as e:
            print(f"     ⚠️ Deduplication hatası: {e}")
            return False
    
    def generate_questions_with_gemini(self, text: str, subject_info: Dict, num_questions: int) -> List[Dict]:
        """Gemini ile soru üret"""
        
        prompt = f"""
Sen bir HMGS (Hukuk Mesleklerine Giriş Sınavı) soru yazarısın.

KONU: {subject_info['name']}
SUBJECT ID: {subject_info['subjectId']}

Aşağıdaki {subject_info['name']} metninden **{num_questions} adet** HMGS tarzı soru üret:

---
{text[:10000]}  # İlk 10000 karakter (Gemini input limit)
---

KURALLAR:
1. Sorular **{subject_info['name']}** konusuyla ilgili olmalı
2. Her soru 5 şıklı (A-E)
3. Çeldirici şıklar gerçekçi olmalı
4. Kanun maddesi referansı ekle (varsa)
5. Detaylı açıklama + yanlış şık sebepleri

JSON FORMAT:
```json
[
  {{
    "stem": "Soru metni...",
    "options": ["A", "B", "C", "D", "E"],
    "correctIndex": 0,
    "difficulty": "medium",
    "lawArticle": "TMK m. 186",
    "detailedExplanation": "...",
    "wrongReasons": {{"1": "B yanlış çünkü...", "2": "C yanlış çünkü..."}},
    "subjectId": "{subject_info['subjectId']}",
    "topicIds": []
  }}
]
```

SADECE JSON VER.
"""
        
        try:
            model = genai.GenerativeModel('gemini-2.0-flash-exp')
            response = model.generate_content(prompt)
            
            # JSON parse
            response_text = response.text.strip()
            
            # Markdown temizle
            if response_text.startswith("```json"):
                response_text = response_text[7:]
            if response_text.startswith("```"):
                response_text = response_text[3:]
            if response_text.endswith("```"):
                response_text = response_text[:-3]
            
            questions = json.loads(response_text.strip())
            
            # Deduplication kontrolü
            unique_questions = []
            for q in questions:
                if not self.is_duplicate_question(q['stem'], subject_info['subjectId']):
                    unique_questions.append(q)
                else:
                    print(f"     ⏭️  Tekrar soru atlandı")
            
            return unique_questions
        
        except Exception as e:
            print(f"     ❌ Gemini hatası: {e}")
            return []
    
    def process_subject(self, subject_key: str):
        """Bir dersi işle (tüm PDF'leri birleştirerek)"""
        subject_info = self.config['subjects'][subject_key]
        
        print(f"\n{'='*70}")
        print(f"📚 {subject_info['name']} İşleniyor")
        print(f"{'='*70}")
        
        # Progress kontrolü
        if subject_key in self.progress and self.progress[subject_key].get('completed', False):
            print(f"✅ Bu ders zaten işlenmiş, atlanıyor.")
            response = input("Yine de işlemek ister misin? (y/n): ")
            if response.lower() != 'y':
                return
        
        # PDF'leri birleştir
        print(f"\n📖 {len(subject_info['pdfs'])} PDF birleştiriliyor...")
        combined_text = self.extract_text_from_multiple_pdfs(
            subject_info['pdfs'],
            self.config['settings']['max_pages_per_pdf']
        )
        
        if not combined_text:
            print("❌ Hiç metin çıkarılamadı!")
            return
        
        print(f"✅ Toplam {len(combined_text):,} karakter metin")
        
        # Chunk'lara böl
        chunks = self.chunk_text(combined_text, self.config['settings']['chunk_size'])
        print(f"📦 {len(chunks)} parçaya bölündü")
        
        # Her chunk için soru üret
        all_questions = []
        target_questions = subject_info['target_questions']
        questions_per_chunk = self.config['settings']['questions_per_chunk']
        
        for i, chunk in enumerate(chunks):
            if len(all_questions) >= target_questions:
                print(f"\n🎯 Hedef soru sayısına ulaşıldı ({target_questions}), durduruluyor.")
                break
            
            print(f"\n--- Chunk {i+1}/{len(chunks)} ---")
            questions = self.generate_questions_with_gemini(chunk, subject_info, questions_per_chunk)
            all_questions.extend(questions)
            print(f"✅ Şu ana kadar: {len(all_questions)} soru")
        
        # JSON olarak kaydet
        output_file = self.output_dir / f"{subject_key}_questions.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(all_questions, f, ensure_ascii=False, indent=2)
        
        # Progress güncelle
        self.progress[subject_key] = {
            'completed': True,
            'questions_generated': len(all_questions),
            'timestamp': datetime.now().isoformat()
        }
        self.save_progress()
        
        print(f"\n✅ {subject_info['name']}: {len(all_questions)} soru üretildi")
        print(f"💾 Kaydedildi: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='Gelişmiş Soru Üretim Sistemi')
    parser.add_argument('--config', type=str, default='scripts/subject_config.yaml', help='Konfigürasyon dosyası')
    parser.add_argument('--subject', type=str, help='Tek ders işle (örn: medeni_hukuk)')
    parser.add_argument('--all', action='store_true', help='Tüm dersleri işle')
    
    args = parser.parse_args()
    
    generator = QuestionGenerator(args.config)
    
    if args.all:
        # Tüm dersleri işle
        for subject_key in generator.config['subjects'].keys():
            generator.process_subject(subject_key)
    elif args.subject:
        # Tek ders işle
        if args.subject in generator.config['subjects']:
            generator.process_subject(args.subject)
        else:
            print(f"❌ '{args.subject}' dersi bulunamadı!")
            print(f"Mevcut dersler: {', '.join(generator.config['subjects'].keys())}")
    else:
        print("⚠️ --subject veya --all parametresi gerekli!")
        print("Örnek: python advanced_question_generator.py --subject medeni_hukuk")

if __name__ == "__main__":
    main()
