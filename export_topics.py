"""
Firestore'dan tüm Subject/Topic/Subtopic listesini export eden script.
Çıktı: lesson_content/TOPIC_LIST.md ve JSON dosyaları için klasör yapısı
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

# Firebase başlat
if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def export_topics():
    """Tüm konuları export et ve klasör yapısı oluştur."""
    
    output_dir = "lesson_content"
    os.makedirs(output_dir, exist_ok=True)
    
    # PDF eşleştirmeleri
    pdf_mapping = {
        "Anayasa Hukuku": [
            "Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf",
            "TC Anayasası.pdf"
        ],
        "Borçlar Hukuku": [
            "borçlar hukuku ders notları.pdf",
            "türk borçlar kanunu.pdf"
        ],
        "Ceza Hukuku": [
            "ceza hukuku genel hükümler ders notları.pdf",
            "ceza hukuku özel hükümler ders notları.pdf",
            "türk ceza kanunu.pdf"
        ],
        "Ceza Muhakemesi Hukuku": [
            "ceza muhakemesi kanunu.pdf",
            "CEZA MUHAKEMESİ KANUNU VE BAZI KANUNLARDA (7188).pdf"
        ],
        "Medeni Hukuk": [
            "medeni hukuk ders notları.pdf",
            "türk medeni kanunu.pdf"
        ],
        "Ticaret Hukuku": [
            "ticaret hukuku ders notları.pdf",
            "türk ticaret kanunu.pdf"
        ],
        "İcra ve İflas Hukuku": [
            "icra ve iflas hukuku ders notları.pdf",
            "icra ve iflas kanunu.pdf"
        ],
        "Hukuk Muhakemeleri": [
            "hukuk muhakemeleri kanunu.pdf"
        ],
        "İdare Hukuku": [
            "idari yargı ve anayasa yargısı.pdf",
            "idari yargılama usülü kanunu.pdf"
        ],
        "İş Hukuku": [
            "iş kanunu.pdf",
            "iş mahkemeleri kanunu.pdf",
            "sosyal sigortalar ve genel sağlık sigortası kanunu.pdf"
        ],
        "Vergi Hukuku": [
            "Turk Vergi Sistemi (2019 Guncel).pdf",
            "vergi usul kanunu.pdf"
        ],
        "Avukatlık Hukuku": [
            "avukatlık hukuku.pdf",
            "avukatlık kanunu.pdf"
        ],
        "Milletlerarası Hukuk": [
            "Milletlerarası Hukuk ders notları.pdf",
            "MİLLETLERARASI ÖZEL HUKUK VE USUL HUKUKU.pdf"
        ],
        "Genel Kamu Hukuku": [
            "genel kamu hukuku ders notları.pdf"
        ],
        "Hukuk Felsefesi": [
            "hukuk felsefesi ders notları.pdf"
        ],
        "Türk Hukuk Tarihi": [
            "türk tarihi hukuku.pdf"
        ]
    }
    
    # Subjects'ları çek
    subjects_ref = db.collection('subjects').stream()
    
    all_data = []
    md_content = "# 📚 Ders İçeriği Üretim Rehberi\n\n"
    md_content += "Bu dosya, AI aracınıza verebileceğiniz konu listesini ve ilgili PDF'leri içerir.\n\n"
    md_content += "---\n\n"
    
    for subject_doc in subjects_ref:
        subject = subject_doc.to_dict()
        subject_id = subject_doc.id
        subject_name = subject.get('name', 'Bilinmeyen Ders')
        
        # Klasör oluştur
        subject_folder = os.path.join(output_dir, subject_name.replace('/', '-'))
        os.makedirs(subject_folder, exist_ok=True)
        
        md_content += f"## 📖 {subject_name}\n"
        md_content += f"**Subject ID:** `{subject_id}`\n\n"
        
        # İlgili PDF'ler
        pdfs = pdf_mapping.get(subject_name, [])
        if pdfs:
            md_content += "**İlgili PDF'ler:**\n"
            for pdf in pdfs:
                md_content += f"- `docs/{pdf}`\n"
        md_content += "\n"
        
        # Topics'leri çek
        topics_ref = db.collection('topics').where('subjectId', '==', subject_id).stream()
        
        topics_list = []
        for topic_doc in topics_ref:
            topic = topic_doc.to_dict()
            topic_id = topic_doc.id
            topic_name = topic.get('name', 'Bilinmeyen Konu')
            parent_id = topic.get('parentId')
            
            topics_list.append({
                'id': topic_id,
                'name': topic_name,
                'parentId': parent_id
            })
        
        # Ana konuları ve alt konuları ayır
        root_topics = [t for t in topics_list if not t['parentId']]
        
        for root in root_topics:
            md_content += f"### 📝 {root['name']}\n"
            md_content += f"- **Topic ID:** `{root['id']}`\n"
            md_content += f"- **JSON Dosyası:** `{subject_folder}/{root['id']}.json`\n"
            
            # Alt konular
            subtopics = [t for t in topics_list if t['parentId'] == root['id']]
            if subtopics:
                md_content += "- **Alt Konular:**\n"
                for sub in subtopics:
                    md_content += f"  - {sub['name']} (`{sub['id']}`)\n"
            
            md_content += "\n"
            
            # Boş JSON şablonu oluştur
            json_template = {
                "topicId": root['id'],
                "topicName": root['name'],
                "subjectName": subject_name,
                "steps": [
                    {
                        "stepNumber": 1,
                        "title": "Adım 1 Başlığı",
                        "content": "## Başlık\n\nİçerik buraya gelecek..."
                    }
                ],
                "practiceQuestions": [
                    {
                        "question": "Örnek soru metni?",
                        "options": {
                            "A": "Seçenek A",
                            "B": "Seçenek B",
                            "C": "Seçenek C",
                            "D": "Seçenek D"
                        },
                        "correctAnswer": "A",
                        "explanation": "Doğru cevap açıklaması"
                    }
                ],
                "createdAt": ""
            }
            
            json_path = os.path.join(subject_folder, f"{root['id']}.json")
            if not os.path.exists(json_path):
                with open(json_path, 'w', encoding='utf-8') as f:
                    json.dump(json_template, f, ensure_ascii=False, indent=2)
        
        md_content += "---\n\n"
        
        all_data.append({
            'subject_id': subject_id,
            'subject_name': subject_name,
            'topics': topics_list,
            'pdfs': pdfs
        })
    
    # AI Prompt şablonu ekle
    md_content += """
## 🤖 AI Aracınıza Verebileceğiniz Prompt

```
Aşağıdaki PDF içeriğini kullanarak Firestore topic_lessons formatında ders içeriği oluştur:

**Konu:** [KONU ADI]
**Ders:** [DERS ADI]

**Gerekli Format:**
1. "steps" dizisi: 5 adet hap bilgi adımı, her biri:
   - stepNumber: 1-5
   - title: Kısa başlık (max 50 karakter)
   - content: Markdown formatında açıklama (## başlıklar, **kalın**, madde işaretleri kullan)

2. "practiceQuestions" dizisi: 10 adet çoktan seçmeli soru, her biri:
   - question: Soru metni
   - options: {"A": "...", "B": "...", "C": "...", "D": "..."}
   - correctAnswer: "A", "B", "C" veya "D"
   - explanation: Doğru cevabın açıklaması

SADECE JSON formatında çıktı ver, başka açıklama ekleme.
```

## 📤 Firestore'a Yükleme

JSON dosyalarınızı oluşturduktan sonra, `upload_lessons.py` scriptini çalıştırarak toplu yükleme yapabilirsiniz:

```bash
python upload_lessons.py
```
"""
    
    # MD dosyasını kaydet
    md_path = os.path.join(output_dir, "TOPIC_LIST.md")
    with open(md_path, 'w', encoding='utf-8') as f:
        f.write(md_content)
    
    # Özet JSON
    summary_path = os.path.join(output_dir, "all_topics.json")
    with open(summary_path, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ Export tamamlandı!")
    print(f"📁 Klasör: {output_dir}/")
    print(f"📋 Rehber: {md_path}")
    print(f"📊 JSON: {summary_path}")
    
    return all_data

if __name__ == "__main__":
    export_topics()
