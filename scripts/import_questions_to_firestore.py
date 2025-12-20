"""
Soru Import Script - sorular/*.md dosyalarından Firestore'a
1006 soruyu Firestore 'questions' koleksiyonuna yükler

Kullanım:
    python scripts/import_questions_to_firestore.py --dry-run   # Test (yüklemez)
    python scripts/import_questions_to_firestore.py             # Gerçek yükleme
    python scripts/import_questions_to_firestore.py --clear     # Önce mevcut soruları sil
"""

import json
import re
import argparse
from pathlib import Path
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, firestore

# ============================================
# KONFİGÜRASYON
# ============================================

BASE_DIR = Path(__file__).parent.parent
SORULAR_DIR = BASE_DIR / "sorular"
SERVICE_ACCOUNT_PATH = BASE_DIR / "service-account.json"

# Firebase init
if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ============================================
# SUBJECT CODE → FIRESTORE ID MAPPING
# ============================================
# NOT: Bu ID'ler Firestore'daki subjects koleksiyonundaki document ID'leri ile birebir eşleşmeli!
# Firestore'daki aktif subjects: anayasa_hukuku, medeni_hukuk, borclar_hukuku, ticaret_hukuku,
# ceza_hukuku, ceza_muhakemesi, idare_hukuku, idari_yargilama, vergi_hukuku, icra_iflas,
# is_hukuku, avukatlik_hukuku, hukuk_felsefesi, milletlerarasi_hukuk, mohuk

SUBJECT_MAPPING = {
    "ANAYASA": "anayasa_hukuku",
    "MEDENI": "medeni_hukuk",       # Düzeltildi: medeni_hukuku -> medeni_hukuk
    "BORCLAR": "borclar_hukuku",
    "TICARET": "ticaret_hukuku",
    "CEZA": "ceza_hukuku",
    "CMK": "ceza_muhakemesi",
    "IDARE": "idare_hukuku",
    "IYUK": "idari_yargilama",
    "VERGI": "vergi_hukuku",
    "ICRA": "icra_iflas",
    "IS": "is_hukuku",
    "AVUKATLIK": "avukatlik_hukuku",
    "FELSEFE": "hukuk_felsefesi",
    "MILLETLERARASI": "milletlerarasi_hukuk",
    "MOHUK": "mohuk"
}

# ============================================
# TOPIC PATH → TOPIC ID MAPPING
# ============================================

# topic_path ilk elemanı → Firestore topic grubu
TOPIC_GROUP_MAPPING = {
    # ANAYASA
    "Anayasa Genel": "anayasa_hukukuna_giris",
    "Anayasa Hukukuna Giriş": "anayasa_hukukuna_giris",
    "Temel Haklar": "temel_hak_ve_ozgurlukler",
    "Temel Hak ve Özgürlükler": "temel_hak_ve_ozgurlukler",
    "Yasama": "yasama",
    "Yürütme": "yurutme",
    "Yargı": "yargi",
    "Anayasa Yargısı": "yargi",
    
    # MEDENI
    "Medeni Genel": "baslangic_hukumleri",
    "Başlangıç Hükümleri": "baslangic_hukumleri",
    "Kişiler Hukuku": "kisiler_hukuku",
    "Tüzel Kişiler": "tuzel_kisiler",
    "Aile Hukuku": "aile_hukuku",
    "Miras Hukuku": "miras_hukuku",
    "Eşya Hukuku": "esya_hukuku",
    
    # BORCLAR
    "Borçlar Genel": "borc_iliskisinin_kaynaklari",
    "Borç İlişkisinin Kaynakları": "borc_iliskisinin_kaynaklari",
    "Sözleşmeler": "borc_iliskisinin_kaynaklari",
    "Haksız Fiil": "haksiz_fiil",
    "Sebepsiz Zenginleşme": "sebepsiz_zenginlesme",
    "Borcun İfası": "borcun_ifasi_ve_sona_ermesi",
    "Borcun İfası ve Sona Ermesi": "borcun_ifasi_ve_sona_ermesi",
    "Özel Borç İlişkileri": "ozel_borc_iliskileri",
    
    # TICARET
    "Ticaret Genel": "ticari_isletme",
    "Ticari İşletme": "ticari_isletme",
    "Şirketler": "sirketler_hukuku",
    "Şirketler Hukuku": "sirketler_hukuku",
    "Kıymetli Evrak": "kiymetli_evrak",
    
    # CEZA
    "Ceza Genel": "ceza_hukukuna_giris",
    "Ceza Hukukuna Giriş": "ceza_hukukuna_giris",
    "Suç Teorisi": "sucun_genel_teorisi",
    "Suçun Genel Teorisi": "sucun_genel_teorisi",
    "Suçun Özel Görünüşleri": "sucun_ozel_gorunus_sekilleri",
    "Suçun Özel Görünüş Şekilleri": "sucun_ozel_gorunus_sekilleri",
    "Yaptırımlar": "yaptirimlar",
    "Özel Suçlar": "ozel_suclar",
    "Ceza Özel": "ozel_suclar",
    
    # CMK
    "CMK Genel": "ceza_muhakemesine_giris",
    "Ceza Muhakemesine Giriş": "ceza_muhakemesine_giris",
    "Soruşturma": "sorusturma",
    "Deliller": "deliller",
    "Kovuşturma": "kovusturma",
    "Kanun Yolları": "kanun_yollari",
    
    # IDARE
    "İdare Genel": "idarenin_kurulusu",
    "İdarenin Kuruluşu": "idarenin_kurulusu",
    "İdari İşlemler": "idari_islemler",
    "Kamu Görevlileri": "kamu_gorevlileri",
    "Kolluk": "kolluk",
    "Kamu Malları": "kamu_mallari",
    "İdarenin Sorumluluğu": "idarenin_sorumlulugu",
    
    # IYUK
    "İYUK Genel": "dava_turleri",
    "Dava Türleri": "dava_turleri",
    "Dava Şartları": "dava_sartlari",
    "Yargılama": "yargilama",
    "İYUK Kanun Yolları": "kanun_yollari_iyuk",
    
    # VERGI
    "Vergi Genel": "vergi_hukuku_genel",
    "Vergi Hukuku Genel": "vergi_hukuku_genel",
    "Vergilendirme Süreci": "vergilendirme_sureci",
    "Vergi Denetimi": "vergi_denetimi",
    "Vergi Uyuşmazlıkları": "vergi_uyusmazliklari",
    "Vergi Suçları": "vergi_suclari",
    
    # ICRA
    "İcra Genel": "icra_takip_yollari",
    "İcra Takip Yolları": "icra_takip_yollari",
    "Haciz": "haciz",
    "İflas": "iflas",
    "Konkordato": "konkordato",
    "İcra Şikâyetleri": "icra_sikayetleri",
    
    # IS
    "İş Genel": "bireysel_is_hukuku",
    "Bireysel İş Hukuku": "bireysel_is_hukuku",
    "İş Sözleşmesi": "is_sozlesmesi",
    "İş Sözleşmesinin Sona Ermesi": "is_sozlesmesinin_sona_ermesi",
    "Toplu İş Hukuku": "toplu_is_hukuku",
    "İş Yargılaması": "is_yargilamasi",
    "Sosyal Güvenlik": "sosyal_guvenlik",
    
    # AVUKATLIK
    "Avukatlık Genel": "avukatlik_meslek_kurallari",
    "Avukatlık Meslek Kuralları": "avukatlik_meslek_kurallari",
    "Avukatın Hakları": "avukatin_haklari",
    "Avukatın Yükümlülükleri": "avukatin_yukumlulukleri",
    "Baro": "baro",
    "Staj": "staj",
    
    # FELSEFE
    "Felsefe Genel": "hukuk_felsefesi_akimlari",
    "Hukuk Felsefesi Akımları": "hukuk_felsefesi_akimlari",
    "Hukuk Sosyolojisi": "hukuk_sosyolojisi",
    "Hukuk Kavramları": "hukuk_kavramlari",
    
    # MILLETLERARASI
    "Milletlerarası Genel": "milletlerarasi_hukukun_kaynaklari",
    "Milletlerarası Hukukun Kaynakları": "milletlerarasi_hukukun_kaynaklari",
    "Devletler": "devletler",
    "Uluslararası Örgütler": "uluslararasi_orgutler",
    "Deniz Hukuku": "deniz_hukuku",
    "İnsan Hakları": "insan_haklari",
    
    # MOHUK
    "MÖHUK Genel": "kanunlar_ihtilafi",
    "Kanunlar İhtilafı": "kanunlar_ihtilafi",
    "Vatandaşlık": "vatandaslik",
    "Yabancılar Hukuku": "yabancilar_hukuku",
    "Milletlerarası Usul": "milletlerarasi_usul"
}

# ============================================
# DIFFICULTY MAPPING
# ============================================

def map_difficulty(diff_value):
    """1-3 değerini easy/medium/hard'a çevir"""
    if isinstance(diff_value, int):
        if diff_value <= 1:
            return "easy"
        elif diff_value == 2:
            return "medium"
        else:
            return "hard"
    return "medium"

# ============================================
# CORRECT OPTION → INDEX
# ============================================

def option_to_index(option_letter):
    """A-E harfini 0-4 index'e çevir"""
    mapping = {"A": 0, "B": 1, "C": 2, "D": 3, "E": 4}
    return mapping.get(option_letter.upper(), 0)

# ============================================
# PARSE QUESTIONS FROM MD FILE
# ============================================

def parse_questions_file(file_path):
    """MD dosyasından soruları parse et"""
    questions = []
    
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # JSON bloklarını bul
    json_pattern = r'```json\s*([\s\S]*?)\s*```'
    matches = re.findall(json_pattern, content)
    
    for match in matches:
        try:
            data = json.loads(match)
            if isinstance(data, list):
                questions.extend(data)
            elif isinstance(data, dict):
                questions.append(data)
        except json.JSONDecodeError as e:
            print(f"  ⚠️ JSON parse hatası: {e}")
            continue
    
    return questions

# ============================================
# CONVERT TO FIRESTORE FORMAT
# ============================================

def convert_to_firestore(question, subject_code):
    """Soru formatını Firestore formatına çevir"""
    
    # Subject ID
    subject_id = SUBJECT_MAPPING.get(subject_code, subject_code.lower())
    
    # Topic ID - topic_path'in ilk elemanını kullan
    topic_path = question.get("topic_path", [])
    topic_group = topic_path[0] if topic_path else f"{subject_code} Genel"
    topic_id = TOPIC_GROUP_MAPPING.get(topic_group, topic_group.lower().replace(" ", "_"))
    
    # Options - label/text formatından sadece text'e çevir
    options_raw = question.get("options", [])
    options = []
    for opt in options_raw:
        if isinstance(opt, dict):
            options.append(opt.get("text", ""))
        else:
            options.append(str(opt))
    
    # Correct index
    correct_option = question.get("correct_option", "A")
    correct_index = option_to_index(correct_option)
    
    # Difficulty
    difficulty = map_difficulty(question.get("difficulty", 2))
    
    # Timestamp
    now = datetime.now()
    
    return {
        "stem": question.get("stem", ""),
        "options": options,
        "correctIndex": correct_index,
        "subjectId": subject_id,
        "topicIds": [topic_id],
        "difficulty": difficulty,
        "detailedExplanation": question.get("static_explanation", ""),
        "source": "AI Generated - HMGS 2025",
        "tags": ["hmgs", "2025", "ai-generated"],
        "targetRoles": question.get("target_roles", ["genel"]),
        "examWeightTag": question.get("exam_weight_tag", "core"),
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
        # Orijinal ID'yi referans olarak sakla
        "originalId": question.get("id", ""),
    }

# ============================================
# MAIN IMPORT FUNCTION
# ============================================

def import_questions(dry_run=False, clear_first=False):
    """Tüm soruları Firestore'a yükle"""
    
    print("=" * 60)
    print("📚 SORU IMPORT - Firestore'a Yükleme")
    print("=" * 60)
    
    if dry_run:
        print("🔍 DRY RUN modu - Yükleme yapılmayacak")
    
    # Önce mevcut soruları sil (opsiyonel)
    if clear_first and not dry_run:
        print("\n🗑️ Mevcut sorular siliniyor...")
        questions_ref = db.collection("questions")
        docs = questions_ref.stream()
        batch = db.batch()
        count = 0
        for doc in docs:
            batch.delete(doc.reference)
            count += 1
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
        if count % 500 != 0:
            batch.commit()
        print(f"  ✅ {count} soru silindi")
    
    # Tüm soru dosyalarını bul
    question_files = list(SORULAR_DIR.glob("*_SORULAR.md"))
    print(f"\n📁 {len(question_files)} soru dosyası bulundu")
    
    total_imported = 0
    total_errors = 0
    subject_stats = {}
    
    for file_path in sorted(question_files):
        # Subject code from filename (e.g., ANAYASA_SORULAR.md → ANAYASA)
        subject_code = file_path.stem.replace("_SORULAR", "")
        
        print(f"\n📄 {file_path.name}")
        
        # Parse questions
        questions = parse_questions_file(file_path)
        print(f"   {len(questions)} soru parse edildi")
        
        if not questions:
            continue
        
        # Import to Firestore
        imported = 0
        errors = 0
        
        if not dry_run:
            batch = db.batch()
        
        for i, q in enumerate(questions):
            try:
                firestore_data = convert_to_firestore(q, subject_code)
                
                if dry_run:
                    # Sadece ilk soruyu göster
                    if i == 0:
                        print(f"   Örnek veri: {json.dumps(firestore_data, ensure_ascii=False, default=str)[:200]}...")
                else:
                    doc_ref = db.collection("questions").document()
                    batch.set(doc_ref, firestore_data)
                    
                    # Her 500 işlemde batch'i commit et
                    if (imported + 1) % 500 == 0:
                        batch.commit()
                        batch = db.batch()
                
                imported += 1
            except Exception as e:
                print(f"   ⚠️ Hata (soru {i+1}): {e}")
                errors += 1
        
        # Son batch'i commit et
        if not dry_run and imported % 500 != 0:
            batch.commit()
        
        print(f"   ✅ {imported} yüklendi, {errors} hata")
        total_imported += imported
        total_errors += errors
        subject_stats[subject_code] = imported
    
    # Özet
    print("\n" + "=" * 60)
    print("📊 ÖZET")
    print("=" * 60)
    print(f"Toplam yüklenen: {total_imported}")
    print(f"Toplam hata: {total_errors}")
    print("\nDers bazlı dağılım:")
    for code, count in sorted(subject_stats.items()):
        print(f"  {code}: {count}")
    
    if dry_run:
        print("\n⚠️ DRY RUN - Gerçek yükleme için --dry-run parametresini kaldırın")

# ============================================
# CLI
# ============================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Soruları Firestore'a yükle")
    parser.add_argument("--dry-run", action="store_true", help="Test modu (yüklemez)")
    parser.add_argument("--clear", action="store_true", help="Önce mevcut soruları sil")
    
    args = parser.parse_args()
    
    import_questions(dry_run=args.dry_run, clear_first=args.clear)
