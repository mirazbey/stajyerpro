"""
Gemini 2.5 Flash ile Otomatik Soru Üretim Scripti
StajyerPro - HMGS Soru Bankası Oluşturucu

Kullanım:
    python generate_questions_gemini.py --subject ANAYASA --count 10
    python generate_questions_gemini.py --subject CMK --count 20 --topic "Tutuklama"
    python generate_questions_gemini.py --all --count 5
"""

import os
import json
import argparse
import time
from datetime import datetime
from pathlib import Path

try:
    import google.generativeai as genai
except ImportError:
    print("❌ google-generativeai paketi yüklü değil!")
    print("   Yüklemek için: pip install google-generativeai")
    exit(1)

# ============================================
# KONFIGÜRASYON
# ============================================

# Gemini API Key - Environment variable olarak ayarlayın
# Windows: set GEMINI_API_KEY=your-api-key
# veya buraya direkt yazın (güvenlik riski!)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "YOUR_API_KEY_HERE")

# Proje dizinleri
BASE_DIR = Path(__file__).parent.parent
DOCS_DIR = BASE_DIR / "docs"
SORULAR_DIR = BASE_DIR / "sorular"
TEMPLATE_FILE = BASE_DIR / "AI_SORU_SABLONU.md"

# ============================================
# DERS TANIMLARI VE KAYNAKLARI
# ============================================

SUBJECTS = {
    "ANAYASA": {
        "name": "Anayasa Hukuku",
        "pdfs": [
            "TC Anayasası.pdf",
            "Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf",
            "idari yargı ve anayasa yargısı.pdf"
        ],
        "topics": [
            ["Anayasa Kavramı"],
            ["Anayasa Kavramı", "Anayasa Türleri"],
            ["Anayasa Kavramı", "Anayasacılık"],
            ["Temel Hak ve Hürriyetler"],
            ["Temel Hak ve Hürriyetler", "Kişi Hakları"],
            ["Temel Hak ve Hürriyetler", "Sosyal ve Ekonomik Haklar"],
            ["Temel Hak ve Hürriyetler", "Siyasi Haklar ve Ödevler"],
            ["Devletin Temel Organları"],
            ["Devletin Temel Organları", "Yasama"],
            ["Devletin Temel Organları", "Yürütme"],
            ["Devletin Temel Organları", "Yargı"],
            ["Anayasa Yargısı"],
            ["Anayasa Yargısı", "Norm Denetimi"],
            ["Anayasa Yargısı", "Bireysel Başvuru"]
        ]
    },
    "MEDENI": {
        "name": "Medeni Hukuk",
        "pdfs": [
            "türk medeni kanunu.pdf",
            "medeni hukuk ders notları.pdf",
            "hukuk muhakemeleri kanunu.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["Kişiler Hukuku"],
            ["Kişiler Hukuku", "Gerçek Kişiler"],
            ["Kişiler Hukuku", "Tüzel Kişiler"],
            ["Aile Hukuku"],
            ["Aile Hukuku", "Evlilik Hukuku"],
            ["Aile Hukuku", "Hısımlık"],
            ["Aile Hukuku", "Vesayet"],
            ["Miras Hukuku"],
            ["Miras Hukuku", "Yasal Mirasçılar"],
            ["Miras Hukuku", "Ölüme Bağlı Tasarruflar"],
            ["Eşya Hukuku"],
            ["Eşya Hukuku", "Mülkiyet"],
            ["Eşya Hukuku", "Sınırlı Ayni Haklar"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Temyiz Edilebilir Kararlar"]
        ]
    },
    "BORCLAR": {
        "name": "Borçlar Hukuku",
        "pdfs": [
            "türk borçlar kanunu.pdf",
            "borçlar hukuku ders notları.pdf"
        ],
        "topics": [
            ["Borç İlişkisinin Kaynakları"],
            ["Borç İlişkisinin Kaynakları", "Sözleşmeden Doğan Borçlar"],
            ["Borç İlişkisinin Kaynakları", "Haksız Fiil"],
            ["Borç İlişkisinin Kaynakları", "Sebepsiz Zenginleşme"],
            ["Borcun İfası"],
            ["Borcun İfası", "İfa Yeri ve Zamanı"],
            ["Borçların Sona Ermesi"],
            ["Özel Borç İlişkileri"],
            ["Özel Borç İlişkileri", "Satış Sözleşmesi"],
            ["Özel Borç İlişkileri", "Kira Sözleşmesi"],
            ["Özel Borç İlişkileri", "Eser Sözleşmesi"]
        ]
    },
    "TICARET": {
        "name": "Ticaret Hukuku",
        "pdfs": [
            "türk ticaret kanunu.pdf",
            "ticaret hukuku ders notları.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["Ticari İşletme"],
            ["Ticari İşletme", "Tacir"],
            ["Ticari İşletme", "Ticaret Sicili"],
            ["Şirketler Hukuku"],
            ["Şirketler Hukuku", "Anonim Şirket"],
            ["Şirketler Hukuku", "Limited Şirket"],
            ["Kıymetli Evrak"],
            ["Kıymetli Evrak", "Poliçe"],
            ["Kıymetli Evrak", "Bono"],
            ["Kıymetli Evrak", "Çek"],
            ["9. Yargı Paketi (Ticari Uyuşmazlık Değişiklikleri)"]
        ]
    },
    "CEZA": {
        "name": "Ceza Hukuku",
        "pdfs": [
            "türk ceza kanunu.pdf",
            "ceza hukuku genel hükümler ders notları.pdf",
            "ceza hukuku özel hükümler ders notları.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["Ceza Hukukuna Giriş"],
            ["Ceza Hukukuna Giriş", "Suç Teorisi"],
            ["Suçun Unsurları"],
            ["Suçun Unsurları", "Maddi Unsur"],
            ["Suçun Unsurları", "Manevi Unsur"],
            ["Suçun Unsurları", "Hukuka Aykırılık"],
            ["Ceza Sorumluluğunu Kaldıran Haller"],
            ["Yaptırımlar"],
            ["Yaptırımlar", "Hapis Cezası"],
            ["Yaptırımlar", "Adli Para Cezası"],
            ["9. Yargı Paketi (TCK Değişiklikleri)"],
            ["9. Yargı Paketi (TCK Değişiklikleri)", "Uzlaştırma Kapsamında Değişiklikler"]
        ]
    },
    "CMK": {
        "name": "Ceza Muhakemesi Hukuku",
        "pdfs": [
            "ceza muhakemesi kanunu.pdf",
            "CEZA MUHAKEMESİ KANUNU VE BAZI KANUNLARDA (7188).pdf",
            "1.5.7499.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["Ceza Muhakemesine Giriş"],
            ["Ceza Muhakemesine Giriş", "Temel İlkeler"],
            ["Soruşturma"],
            ["Soruşturma", "Delil Toplama"],
            ["Kovuşturma"],
            ["Kovuşturma", "Duruşma"],
            ["Koruma Tedbirleri"],
            ["Koruma Tedbirleri", "Yakalama ve Gözaltı"],
            ["Koruma Tedbirleri", "Tutuklama"],
            ["Kanun Yolları"],
            ["Kanun Yolları", "İstinaf"],
            ["Kanun Yolları", "Temyiz"],
            ["9. Yargı Paketi (CMK Değişiklikleri)"],
            ["9. Yargı Paketi (CMK Değişiklikleri)", "Tutuklama Şartlarında Değişiklik"]
        ]
    },
    "IDARE": {
        "name": "İdare Hukuku",
        "pdfs": [
            "idari yargı ve anayasa yargısı.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["İdare Hukukuna Giriş"],
            ["İdare Teşkilatı"],
            ["İdare Teşkilatı", "Merkezi İdare"],
            ["İdare Teşkilatı", "Yerinden Yönetim"],
            ["İdari İşlemler"],
            ["İdari İşlemler", "Bireysel İşlemler"],
            ["İdari İşlemler", "Düzenleyici İşlemler"],
            ["İdari Sözleşmeler"],
            ["Kamu Görevlileri"],
            ["İdarenin Sorumluluğu"],
            ["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)"]
        ]
    },
    "IYUK": {
        "name": "İdari Yargılama Usulü",
        "pdfs": [
            "idari yargılama usülü kanunu.pdf",
            "idari yargı ve anayasa yargısı.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["İdari Yargı Teşkilatı"],
            ["İdari Dava Türleri"],
            ["İdari Dava Türleri", "İptal Davası"],
            ["İdari Dava Türleri", "Tam Yargı Davası"],
            ["Dava Açma Süresi"],
            ["Yürütmenin Durdurulması"],
            ["Kanun Yolları"],
            ["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)"]
        ]
    },
    "VERGI": {
        "name": "Vergi Hukuku",
        "pdfs": [
            "vergi usul kanunu.pdf",
            "Turk Vergi Sistemi (2019 Guncel).pdf"
        ],
        "topics": [
            ["Vergi Hukukuna Giriş"],
            ["Vergi Hukukuna Giriş", "Verginin Tarafları"],
            ["Vergilendirme Süreci"],
            ["Vergilendirme Süreci", "Tarh"],
            ["Vergilendirme Süreci", "Tebliğ"],
            ["Vergilendirme Süreci", "Tahakkuk"],
            ["Vergilendirme Süreci", "Tahsil"],
            ["Vergi Suç ve Cezaları"],
            ["Gelir Vergisi"],
            ["Kurumlar Vergisi"],
            ["KDV"]
        ]
    },
    "ICRA": {
        "name": "İcra ve İflas Hukuku",
        "pdfs": [
            "icra ve iflas kanunu.pdf",
            "icra ve iflas hukuku ders notları.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["İcra Hukukuna Giriş"],
            ["İcra Hukukuna Giriş", "İcra Teşkilatı"],
            ["İlamsız İcra"],
            ["İlamsız İcra", "Genel Haciz Yolu"],
            ["İlamlı İcra"],
            ["Haciz"],
            ["Haciz", "Haczi Caiz Olmayan Mallar"],
            ["İflas Hukuku"],
            ["İflas Hukuku", "İflas Yolları"],
            ["9. Yargı Paketi (İİK Değişiklikleri)"],
            ["9. Yargı Paketi (İİK Değişiklikleri)", "Elektronik Satış Usulü"]
        ]
    },
    "IS": {
        "name": "İş Hukuku",
        "pdfs": [
            "iş kanunu.pdf",
            "iş mahkemeleri kanunu.pdf",
            "sosyal sigortalar ve genel sağlık sigortası kanunu.pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["İş Hukukuna Giriş"],
            ["İş Sözleşmesi"],
            ["İş Sözleşmesi", "Türleri"],
            ["İş Sözleşmesi", "Sona Ermesi"],
            ["İşçi Hakları"],
            ["İşçi Hakları", "Ücret"],
            ["İşçi Hakları", "İzinler"],
            ["Kıdem Tazminatı"],
            ["İhbar Tazminatı"],
            ["Sosyal Güvenlik"],
            ["9. Yargı Paketi (Arabuluculuk ve İş Hukuku Değişiklikleri)"]
        ]
    },
    "AVUKATLIK": {
        "name": "Avukatlık Hukuku",
        "pdfs": [
            "avukatlık kanunu.pdf",
            "avukatlık hukuku.pdf",
            "HMGS ve İYÖS sınavı Başvuru Klavuzu.pdf",
            "Hukuk Mesleklerine Giriş Sınavı Yönetmeliği (Resmî Gazete PDF).pdf",
            "9.yargı paketi.pdf"
        ],
        "topics": [
            ["Avukatlık Mesleği"],
            ["Avukatlık Mesleği", "Avukatlığa Kabul"],
            ["Avukatlık Mesleği", "Avukatın Hakları"],
            ["Avukatlık Mesleği", "Avukatın Yükümlülükleri"],
            ["Baro Teşkilatı"],
            ["Avukatlık Sözleşmesi"],
            ["Vekalet Ücreti"],
            ["Disiplin Hukuku"],
            ["9. Yargı Paketi (Avukatlık Mesleği Değişiklikleri)"]
        ]
    },
    "FELSEFE": {
        "name": "Hukuk Felsefesi",
        "pdfs": [
            "hukuk felsefesi ders notları.pdf",
            "türk tarihi hukuku.pdf",
            "genel kamu hukuku ders notları.pdf"
        ],
        "topics": [
            ["Doğal Hukuk"],
            ["Hukuki Pozitivizm"],
            ["Hukuk ve Toplum İlişkisi"],
            ["Hukukun İşlevleri"]
        ]
    },
    "MILLETLERARASI": {
        "name": "Milletlerarası Hukuk",
        "pdfs": [
            "Milletlerarası Hukuk ders notları.pdf"
        ],
        "topics": [
            ["Milletlerarası Hukukun Kaynakları"],
            ["Milletlerarası Hukukun Kaynakları", "Antlaşmalar"],
            ["Milletlerarası Hukukun Kaynakları", "Örf ve Adet"],
            ["Devletler"],
            ["Devletler", "Tanıma"],
            ["Devletler", "Devlet Sorumluluğu"],
            ["Uluslararası Örgütler"],
            ["Uluslararası Örgütler", "Birleşmiş Milletler"],
            ["İnsan Hakları"]
        ]
    },
    "MOHUK": {
        "name": "Milletlerarası Özel Hukuk",
        "pdfs": [
            "MİLLETLERARASI ÖZEL HUKUK VE USUL HUKUKU.pdf"
        ],
        "topics": [
            ["Kanunlar İhtilafı"],
            ["Kanunlar İhtilafı", "Bağlama Kuralları"],
            ["Kanunlar İhtilafı", "Atıf"],
            ["Vatandaşlık"],
            ["Vatandaşlık", "Kazanma"],
            ["Vatandaşlık", "Kaybetme"],
            ["Yabancılar Hukuku"],
            ["Milletlerarası Usul Hukuku"],
            ["Milletlerarası Usul Hukuku", "Yetki"],
            ["Milletlerarası Usul Hukuku", "Tenfiz"]
        ]
    }
}

# ============================================
# SORU ŞABLONU
# ============================================

QUESTION_TEMPLATE = '''
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için profesyonel soru yazarısın.

## GÖREV
{subject_name} konusunda {count} adet çoktan seçmeli soru üret.

## KONU KISITLAMASI
Sadece şu topic_path'lerden birini kullan:
{topics_json}

## JSON FORMAT (HER SORU İÇİN)
```json
{{
  "id": "{subject_code}-XXX",
  "subject_code": "{subject_code}",
  "topic_path": ["Ana Konu"] veya ["Ana Konu", "Alt Konu"],
  "difficulty": 1-3 arası (1=kolay, 2=orta, 3=zor),
  "exam_weight_tag": "core" veya "supporting" veya "longtail",
  "target_roles": ["avukat", "hakim", "savci", "noter"] içinden uygun olanlar,
  "stem": "Soru metni?",
  "options": [
    {{"label": "A", "text": "Şık A"}},
    {{"label": "B", "text": "Şık B"}},
    {{"label": "C", "text": "Şık C"}},
    {{"label": "D", "text": "Şık D"}},
    {{"label": "E", "text": "Şık E"}}
  ],
  "correct_option": "A-E arası doğru cevap",
  "static_explanation": "Detaylı açıklama, **kalın** ile önemli kısımları vurgula",
  "ai_hint": "Yapay zeka için kısa ipucu",
  "related_statute": "İlgili kanun maddesi veya null",
  "learning_objective": "Bu soruyla test edilen öğrenme hedefi",
  "source_pdf": "Kaynak PDF adı",
  "source_page": sayfa numarası veya null,
  "tags": ["etiket1", "etiket2"],
  "created_at": "{timestamp}",
  "status": "approved"
}}
```

## KURALLAR
1. topic_path MUTLAKA yukarıdaki listeden olmalı (max 2 seviye)
2. Şıklar mantıklı ve çeldirici olmalı
3. Doğru cevap açıklaması kanun maddesiyle desteklenmeli
4. Soru HMGS sınav formatına uygun olmalı
5. Türkçe dil bilgisi kurallarına dikkat et

## ÇIKTI
Sadece JSON array döndür, başka açıklama yazma:
[soru1, soru2, ...]
'''

# ============================================
# GEMINI API FONKSİYONLARI
# ============================================

def init_gemini():
    """Gemini API'yi başlat"""
    if GEMINI_API_KEY == "YOUR_API_KEY_HERE":
        print("❌ GEMINI_API_KEY ayarlanmamış!")
        print("   Environment variable olarak ayarlayın:")
        print("   Windows: set GEMINI_API_KEY=your-api-key")
        print("   Linux/Mac: export GEMINI_API_KEY=your-api-key")
        exit(1)
    
    genai.configure(api_key=GEMINI_API_KEY)
    
    # Gemini 2.5 Flash modeli
    model = genai.GenerativeModel(
        model_name="gemini-2.0-flash-exp",
        generation_config={
            "temperature": 0.7,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 8192,
        }
    )
    return model


def read_pdf_content(pdf_path: Path) -> str:
    """PDF içeriğini oku (basit metin çıkarma)"""
    # Not: Gerçek PDF okuma için PyPDF2 veya pdfplumber gerekli
    # Bu fonksiyon şimdilik dosya adını döndürür
    return f"[PDF İçeriği: {pdf_path.name}]"


def generate_questions(model, subject_code: str, count: int = 10, specific_topic: str = None):
    """Belirli bir ders için soru üret"""
    
    if subject_code not in SUBJECTS:
        print(f"❌ Geçersiz subject_code: {subject_code}")
        print(f"   Geçerli kodlar: {', '.join(SUBJECTS.keys())}")
        return None
    
    subject = SUBJECTS[subject_code]
    
    # Topic filtreleme
    topics = subject["topics"]
    if specific_topic:
        topics = [t for t in topics if specific_topic.lower() in str(t).lower()]
        if not topics:
            print(f"⚠️ '{specific_topic}' ile eşleşen topic bulunamadı")
            topics = subject["topics"]
    
    # Prompt oluştur
    timestamp = datetime.now().isoformat() + "Z"
    prompt = QUESTION_TEMPLATE.format(
        subject_name=subject["name"],
        subject_code=subject_code,
        count=count,
        topics_json=json.dumps(topics, ensure_ascii=False, indent=2),
        timestamp=timestamp
    )
    
    print(f"\n🔄 {subject['name']} için {count} soru üretiliyor...")
    print(f"   Kullanılacak topic sayısı: {len(topics)}")
    
    try:
        response = model.generate_content(prompt)
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
        print(f"✅ {len(questions)} soru başarıyla üretildi!")
        return questions
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON parse hatası: {e}")
        print(f"   Ham yanıt: {response_text[:500]}...")
        return None
    except Exception as e:
        print(f"❌ API hatası: {e}")
        return None


def save_questions(questions: list, subject_code: str, append: bool = True):
    """Soruları markdown dosyasına kaydet"""
    
    output_file = SORULAR_DIR / f"{subject_code}_SORULAR.md"
    
    # Mevcut soruları oku
    existing_questions = []
    if output_file.exists() and append:
        content = output_file.read_text(encoding="utf-8")
        if "```json" in content:
            try:
                json_start = content.find("```json") + 7
                json_end = content.find("```", json_start)
                existing_json = content[json_start:json_end].strip()
                existing_questions = json.loads(existing_json)
            except:
                pass
    
    # Yeni ID'ler ata
    max_id = 0
    for q in existing_questions:
        try:
            num = int(q["id"].split("-")[1])
            max_id = max(max_id, num)
        except:
            pass
    
    for i, q in enumerate(questions):
        q["id"] = f"{subject_code}-{str(max_id + i + 1).zfill(3)}"
    
    # Birleştir
    all_questions = existing_questions + questions
    
    # Markdown oluştur
    subject_name = SUBJECTS.get(subject_code, {}).get("name", subject_code)
    md_content = f"""# {subject_name} Soruları

**Toplam Soru Sayısı:** {len(all_questions)}
**Son Güncelleme:** {datetime.now().strftime("%Y-%m-%d %H:%M")}

```json
{json.dumps(all_questions, ensure_ascii=False, indent=2)}
```
"""
    
    output_file.write_text(md_content, encoding="utf-8")
    print(f"💾 Kaydedildi: {output_file}")
    print(f"   Toplam soru: {len(all_questions)}")
    
    return output_file


def validate_questions(questions: list, subject_code: str) -> list:
    """Soruları doğrula ve düzelt"""
    
    valid_topics = SUBJECTS.get(subject_code, {}).get("topics", [])
    valid_questions = []
    
    for q in questions:
        # Topic kontrolü
        topic_valid = any(
            q.get("topic_path") == t or 
            (len(q.get("topic_path", [])) > 0 and q["topic_path"][0] == t[0])
            for t in valid_topics
        )
        
        if not topic_valid:
            print(f"⚠️ Geçersiz topic_path: {q.get('topic_path')} - Düzeltiliyor...")
            # En yakın topic'i bul
            if valid_topics:
                q["topic_path"] = valid_topics[0]
        
        # Zorunlu alanlar kontrolü
        required = ["id", "subject_code", "topic_path", "stem", "options", "correct_option"]
        if all(k in q for k in required):
            valid_questions.append(q)
        else:
            print(f"⚠️ Eksik alanlar: {q.get('id', 'ID yok')}")
    
    return valid_questions


# ============================================
# ANA FONKSİYON
# ============================================

def main():
    parser = argparse.ArgumentParser(description="Gemini ile HMGS Soru Üretici")
    parser.add_argument("--subject", "-s", type=str, help="Ders kodu (örn: ANAYASA, CMK)")
    parser.add_argument("--count", "-c", type=int, default=10, help="Üretilecek soru sayısı")
    parser.add_argument("--topic", "-t", type=str, help="Belirli bir topic için filtrele")
    parser.add_argument("--all", "-a", action="store_true", help="Tüm dersler için soru üret")
    parser.add_argument("--list", "-l", action="store_true", help="Mevcut dersleri listele")
    parser.add_argument("--no-save", action="store_true", help="Kaydetmeden sadece üret")
    
    args = parser.parse_args()
    
    # Ders listesi
    if args.list:
        print("\n📚 Mevcut Dersler:")
        print("-" * 50)
        for code, info in SUBJECTS.items():
            print(f"  {code:15} - {info['name']}")
            print(f"                   Topics: {len(info['topics'])}, PDFs: {len(info['pdfs'])}")
        return
    
    # Gemini başlat
    model = init_gemini()
    
    # Tüm dersler
    if args.all:
        print("\n🚀 Tüm dersler için soru üretimi başlıyor...")
        for subject_code in SUBJECTS.keys():
            questions = generate_questions(model, subject_code, args.count)
            if questions:
                questions = validate_questions(questions, subject_code)
                if not args.no_save:
                    save_questions(questions, subject_code)
            time.sleep(2)  # Rate limit için bekle
        return
    
    # Tek ders
    if args.subject:
        subject_code = args.subject.upper()
        questions = generate_questions(model, subject_code, args.count, args.topic)
        if questions:
            questions = validate_questions(questions, subject_code)
            if not args.no_save:
                save_questions(questions, subject_code)
            else:
                print("\n📋 Üretilen Sorular:")
                print(json.dumps(questions, ensure_ascii=False, indent=2))
        return
    
    # Yardım
    parser.print_help()


if __name__ == "__main__":
    main()
