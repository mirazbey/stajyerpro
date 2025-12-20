"""
Gemini 2.5 Flash ile PDF Tabanlı Otomatik Soru Üretim Scripti
StajyerPro - HMGS Soru Bankası Oluşturucu

Bu script:
1. docs/ klasöründen PDF'leri otomatik tespit eder
2. Her ders için ilgili PDF'leri gruplar
3. AI_SORU_SABLONU.md formatına tam uygun soru üretir
4. Mevcut soruları kontrol ederek tekrar üretmez
5. Çıktıları sorular/ klasörüne kayder

Kullanım:
    python generate_questions_with_pdf.py --list
    python generate_questions_with_pdf.py --subject ANAYASA --count 10
    python generate_questions_with_pdf.py --all --count 5
"""

import os
import json
import argparse
import time
import re
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

# API Key - Ortam değişkeninden veya doğrudan
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyApIRbm-RF9dHQ_99duUH4QUz6_NNJz65E")

# Model: Gemini 2.5 Flash
MODEL_NAME = "gemini-2.5-flash"

# Proje dizinleri
BASE_DIR = Path(__file__).parent.parent
DOCS_DIR = BASE_DIR / "docs"
SORULAR_DIR = BASE_DIR / "sorular"
TEMPLATE_FILE = BASE_DIR / "AI_SORU_SABLONU.md"

# ============================================
# PDF OTOMATİK TESPİT VE GRUPLAMA
# ============================================

def scan_docs_folder():
    """docs/ klasöründeki tüm PDF'leri tespit et"""
    pdfs = []
    if DOCS_DIR.exists():
        for f in DOCS_DIR.iterdir():
            if f.suffix.lower() == ".pdf":
                pdfs.append(f.name)
    return sorted(pdfs)


def turkish_lower(text: str) -> str:
    """Türkçe karakterleri doğru şekilde küçük harfe çevirir"""
    tr_map = str.maketrans("ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZQWX", "abcçdefgğhıijklmnoöprsştuüvyzqwx")
    return text.translate(tr_map).lower()


def auto_group_pdfs(all_pdfs: list) -> dict:
    """PDF'leri derslere göre otomatik grupla (akıllı eşleştirme)"""
    
    # Anahtar kelime eşleştirme kuralları
    keyword_rules = {
        "ANAYASA": ["anayasa", "kemal gözler"],
        "MEDENI": ["medeni", "tmk", "hukuk muhakemeleri"],
        "BORCLAR": ["borçlar", "tbk"],
        "TICARET": ["ticaret", "ttk"],
        "CEZA": ["ceza kanunu", "tck", "ceza hukuku genel", "ceza hukuku özel"],
        "CMK": ["muhakemesi kanunu", "cmk", "7188", "7499", "kanunlarda değişiklik", "bazı kanunlarda"],
        "IDARE": ["idare", "idari yargı"],
        "IYUK": ["yargılama usülü", "iyuk"],
        "VERGI": ["vergi"],
        "ICRA": ["icra", "iflas", "iik"],
        "IS": ["iş kanunu", "iş mahkemeleri", "sosyal sigorta", "sgk"],
        "AVUKATLIK": ["avukatlık", "baro", "hmgs", "hukuk meslek"],
        "FELSEFE": ["felsefe", "sosyoloji", "genel kamu", "tarihi hukuku"],
        "MILLETLERARASI": ["milletlerarası hukuk ders"],
        "MOHUK": ["milletlerarası özel", "möhuk", "usul hukuku"]
    }
    
    # 9. Yargı Paketi kullanan dersler
    yargi_paketi_subjects = ["MEDENI", "TICARET", "CEZA", "CMK", "IDARE", "IYUK", "ICRA", "IS", "AVUKATLIK"]
    
    # HMGS Soru Bankası - TÜM DERSLERE eklenecek (gerçek soru formatı için)
    soru_bankasi_all_subjects = list(keyword_rules.keys())
    
    grouped = {code: [] for code in keyword_rules.keys()}
    
    for pdf in all_pdfs:
        pdf_lower = turkish_lower(pdf)
        
        # Her ders için kontrol
        for subject_code, keywords in keyword_rules.items():
            for keyword in keywords:
                if keyword in pdf_lower:
                    if pdf not in grouped[subject_code]:
                        grouped[subject_code].append(pdf)
                    break
    
    # 9. Yargı Paketi ekle
    yargi_pdf = None
    for pdf in all_pdfs:
        if "yargı paketi" in pdf.lower() or "yargi paketi" in pdf.lower():
            yargi_pdf = pdf
            break
    
    if yargi_pdf:
        for subject in yargi_paketi_subjects:
            if yargi_pdf not in grouped[subject]:
                grouped[subject].append(yargi_pdf)
    
    # HMGS Soru Bankası - tüm derslere ekle
    soru_bankasi_pdf = None
    for pdf in all_pdfs:
        if "soru-bankasi" in pdf.lower() or "soru bankası" in pdf.lower():
            soru_bankasi_pdf = pdf
            break
    
    if soru_bankasi_pdf:
        for subject in soru_bankasi_all_subjects:
            if soru_bankasi_pdf not in grouped[subject]:
                grouped[subject].append(soru_bankasi_pdf)
    
    return grouped


# ============================================
# DERS BİLGİLERİ (AI_SORU_SABLONU.md'den)
# ============================================

SUBJECTS = {
    "ANAYASA": {
        "name": "Anayasa Hukuku",
        "topics": [
            ["Anayasa Hukukuna Giriş"],
            ["Anayasa Hukukuna Giriş", "Anayasa Kavramı"],
            ["Anayasa Hukukuna Giriş", "Devletin Unsurları"],
            ["Anayasa Hukukuna Giriş", "Hükümet Sistemleri"],
            ["Anayasa Hukukuna Giriş", "Egemenlik"],
            ["Anayasa Hukukuna Giriş", "Kuvvetler Ayrılığı"],
            ["Temel Hak ve Özgürlükler"],
            ["Temel Hak ve Özgürlükler", "Temel Hakların Niteliği"],
            ["Temel Hak ve Özgürlükler", "Sınırlandırma Rejimi"],
            ["Temel Hak ve Özgürlükler", "Kişi Hakları"],
            ["Temel Hak ve Özgürlükler", "Sosyal ve Ekonomik Haklar"],
            ["Temel Hak ve Özgürlükler", "Siyasi Haklar"],
            ["Yasama"],
            ["Yasama", "TBMM'nin Görevleri"],
            ["Yasama", "Milletvekilliği"],
            ["Yasama", "Kanun Yapım Süreci"],
            ["Yasama", "Denetim Yolları"],
            ["Yürütme"],
            ["Yürütme", "Cumhurbaşkanı'nın Görevleri"],
            ["Yürütme", "Cumhurbaşkanlığı Kararnameleri"],
            ["Yürütme", "Bakanlar"],
            ["Yürütme", "Olağanüstü Hal"],
            ["Yargı"],
            ["Yargı", "Hakimler ve Savcılar Kurulu"],
            ["Yargı", "Yargı Bağımsızlığı"],
            ["Yargı", "Anayasa Mahkemesi Görevleri"],
            ["Yargı", "İptal Davası ve İtiraz Yolu"],
            ["Yargı", "Bireysel Başvuru"]
        ]
    },
    "MEDENI": {
        "name": "Medeni Hukuk",
        "topics": [
            ["Başlangıç Hükümleri"],
            ["Başlangıç Hükümleri", "Hukukun Uygulanması"],
            ["Başlangıç Hükümleri", "İyiniyet ve Dürüstlük Kuralı"],
            ["Başlangıç Hükümleri", "İspat Yükü"],
            ["Kişiler Hukuku"],
            ["Kişiler Hukuku", "Gerçek Kişiler"],
            ["Kişiler Hukuku", "Kişiliğin Başlangıcı ve Sonu"],
            ["Kişiler Hukuku", "Hak ve Fiil Ehliyeti"],
            ["Kişiler Hukuku", "Kısıtlılık ve Vesayet"],
            ["Kişiler Hukuku", "Kişiliğin Korunması"],
            ["Tüzel Kişiler"],
            ["Tüzel Kişiler", "Tüzel Kişi Kavramı"],
            ["Tüzel Kişiler", "Dernekler"],
            ["Tüzel Kişiler", "Vakıflar"],
            ["Aile Hukuku"],
            ["Aile Hukuku", "Nişanlanma"],
            ["Aile Hukuku", "Evlenme"],
            ["Aile Hukuku", "Boşanma"],
            ["Aile Hukuku", "Mal Rejimleri"],
            ["Aile Hukuku", "Soybağı"],
            ["Aile Hukuku", "Velayet"],
            ["Aile Hukuku", "Nafaka"],
            ["Miras Hukuku"],
            ["Miras Hukuku", "Yasal Mirasçılar"],
            ["Miras Hukuku", "Saklı Pay"],
            ["Miras Hukuku", "Ölüme Bağlı Tasarruflar"],
            ["Miras Hukuku", "Mirasın Geçişi"],
            ["Eşya Hukuku"],
            ["Eşya Hukuku", "Zilyetlik"],
            ["Eşya Hukuku", "Tapu Sicili"],
            ["Eşya Hukuku", "Mülkiyet"],
            ["Eşya Hukuku", "Sınırlı Ayni Haklar"],
            ["Eşya Hukuku", "Rehin ve İpotek"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Temyiz Edilebilir Kararlar"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Temyiz Süresi Değişiklikleri"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Dava Şartlarında Düzenlemeler"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Elektronik Tebligat Sistemi"],
            ["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Aile İçi Şiddet Koruma Tedbirleri"]
        ]
    },
    "BORCLAR": {
        "name": "Borçlar Hukuku",
        "topics": [
            ["Borç İlişkisinin Kaynakları"],
            ["Borç İlişkisinin Kaynakları", "Sözleşmeden Doğan Borçlar"],
            ["Borç İlişkisinin Kaynakları", "Sözleşmenin Kurulması"],
            ["Borç İlişkisinin Kaynakları", "Geçersizlik Halleri"],
            ["Borç İlişkisinin Kaynakları", "Temsil"],
            ["Haksız Fiil"],
            ["Haksız Fiil", "Haksız Fiil Şartları"],
            ["Haksız Fiil", "Kusur Sorumluluğu"],
            ["Haksız Fiil", "Kusursuz Sorumluluk"],
            ["Haksız Fiil", "Tazminat"],
            ["Sebepsiz Zenginleşme"],
            ["Sebepsiz Zenginleşme", "Sebepsiz Zenginleşme Şartları"],
            ["Sebepsiz Zenginleşme", "İade Borcu"],
            ["Borcun İfası ve Sona Ermesi"],
            ["Borcun İfası ve Sona Ermesi", "İfa"],
            ["Borcun İfası ve Sona Ermesi", "Borçlu Temerrüdü"],
            ["Borcun İfası ve Sona Ermesi", "Alacaklı Temerrüdü"],
            ["Borcun İfası ve Sona Ermesi", "Zamanaşımı"],
            ["Özel Borç İlişkileri"],
            ["Özel Borç İlişkileri", "Satış Sözleşmesi"],
            ["Özel Borç İlişkileri", "Kira Sözleşmesi"],
            ["Özel Borç İlişkileri", "Eser Sözleşmesi"],
            ["Özel Borç İlişkileri", "Vekalet Sözleşmesi"],
            ["Özel Borç İlişkileri", "Hizmet Sözleşmesi"],
            ["Özel Borç İlişkileri", "Kefalet Sözleşmesi"]
        ]
    },
    "TICARET": {
        "name": "Ticaret Hukuku",
        "topics": [
            ["Ticari İşletme"],
            ["Ticari İşletme", "Ticari İşletme Kavramı"],
            ["Ticari İşletme", "Tacir"],
            ["Ticari İşletme", "Ticaret Unvanı"],
            ["Ticari İşletme", "Ticaret Sicili"],
            ["Ticari İşletme", "Haksız Rekabet"],
            ["Şirketler Hukuku"],
            ["Şirketler Hukuku", "Şirket Kavramı"],
            ["Şirketler Hukuku", "Adi Şirket"],
            ["Şirketler Hukuku", "Kollektif ve Komandit Şirket"],
            ["Şirketler Hukuku", "Anonim Şirket Organları"],
            ["Şirketler Hukuku", "Limited Şirket"],
            ["Kıymetli Evrak"],
            ["Kıymetli Evrak", "Kıymetli Evrak Temel Hükümler"],
            ["Kıymetli Evrak", "Poliçe"],
            ["Kıymetli Evrak", "Bono"],
            ["Kıymetli Evrak", "Çek"],
            ["9. Yargı Paketi (Ticari Uyuşmazlık Değişiklikleri)"],
            ["9. Yargı Paketi (Ticari Uyuşmazlık Değişiklikleri)", "Ticari Davalarda Zorunlu Arabuluculuk Kapsamı"]
        ]
    },
    "CEZA": {
        "name": "Ceza Hukuku",
        "topics": [
            ["Ceza Hukukuna Giriş"],
            ["Ceza Hukukuna Giriş", "Ceza Hukukunun Temel İlkeleri"],
            ["Ceza Hukukuna Giriş", "Suçta ve Cezada Kanunilik"],
            ["Ceza Hukukuna Giriş", "Ceza Kanunlarının Uygulanması"],
            ["Suçun Genel Teorisi"],
            ["Suçun Genel Teorisi", "Maddi Unsur"],
            ["Suçun Genel Teorisi", "Manevi Unsur"],
            ["Suçun Genel Teorisi", "Hukuka Aykırılık"],
            ["Suçun Genel Teorisi", "Kusur"],
            ["Suçun Özel Görünüş Şekilleri"],
            ["Suçun Özel Görünüş Şekilleri", "Teşebbüs"],
            ["Suçun Özel Görünüş Şekilleri", "İştirak"],
            ["Suçun Özel Görünüş Şekilleri", "İçtima"],
            ["Yaptırımlar"],
            ["Yaptırımlar", "Cezalar"],
            ["Yaptırımlar", "Güvenlik Tedbirleri"],
            ["Özel Suçlar"],
            ["Özel Suçlar", "Hayata Karşı Suçlar"],
            ["Özel Suçlar", "Vücut Dokunulmazlığına Karşı Suçlar"],
            ["Özel Suçlar", "Malvarlığına Karşı Suçlar"],
            ["Özel Suçlar", "Kamu İdaresine Karşı Suçlar"],
            ["9. Yargı Paketi (TCK Değişiklikleri)"],
            ["9. Yargı Paketi (TCK Değişiklikleri)", "Uzlaştırma Kapsamında Değişiklikler"],
            ["9. Yargı Paketi (TCK Değişiklikleri)", "Cinsel Suçların Kapsamı"],
            ["9. Yargı Paketi (TCK Değişiklikleri)", "Etki Ajanlığı (Influence Agent)"]
        ]
    },
    "CMK": {
        "name": "Ceza Muhakemesi Hukuku",
        "topics": [
            ["Ceza Muhakemesine Giriş"],
            ["Ceza Muhakemesine Giriş", "CMK Temel İlkeleri"],
            ["Ceza Muhakemesine Giriş", "Yetki Kuralları"],
            ["Soruşturma"],
            ["Soruşturma", "Soruşturma Aşaması"],
            ["Soruşturma", "Gözaltı"],
            ["Soruşturma", "Tutuklama"],
            ["Soruşturma", "Adli Kontrol"],
            ["Deliller"],
            ["Deliller", "Arama ve Elkoyma"],
            ["Deliller", "İletişimin Denetlenmesi"],
            ["Deliller", "Delil Değerlendirmesi"],
            ["Kovuşturma"],
            ["Kovuşturma", "İddianame"],
            ["Kovuşturma", "Duruşma"],
            ["Kovuşturma", "Hüküm"],
            ["Kanun Yolları"],
            ["Kanun Yolları", "İtiraz"],
            ["Kanun Yolları", "İstinaf"],
            ["Kanun Yolları", "Temyiz"],
            ["9. Yargı Paketi (CMK Değişiklikleri)"],
            ["9. Yargı Paketi (CMK Değişiklikleri)", "Tutuklama Şartlarında Değişiklik"],
            ["9. Yargı Paketi (CMK Değişiklikleri)", "Dijital Delil Toplama Usulleri"]
        ]
    },
    "IDARE": {
        "name": "İdare Hukuku",
        "topics": [
            ["İdarenin Kuruluşu"],
            ["İdarenin Kuruluşu", "Merkezi İdare"],
            ["İdarenin Kuruluşu", "Yerinden Yönetim"],
            ["İdarenin Kuruluşu", "Kamu Tüzel Kişileri"],
            ["İdari İşlemler"],
            ["İdari İşlemler", "Düzenleyici İşlemler"],
            ["İdari İşlemler", "Bireysel İşlemler"],
            ["İdari İşlemler", "İdari İşlemin Unsurları"],
            ["Kamu Görevlileri"],
            ["Kamu Görevlileri", "Memur Kavramı"],
            ["Kamu Görevlileri", "Memurun Hakları"],
            ["Kamu Görevlileri", "Memurun Yükümlülükleri"],
            ["Kamu Görevlileri", "Disiplin"],
            ["Kolluk"],
            ["Kolluk", "Kolluk Kavramı"],
            ["Kolluk", "Kolluk Yetkileri"],
            ["Kamu Malları"],
            ["Kamu Malları", "Kamu Malı Kavramı"],
            ["Kamu Malları", "Kamulaştırma"],
            ["İdarenin Sorumluluğu"],
            ["İdarenin Sorumluluğu", "Hizmet Kusuru"],
            ["İdarenin Sorumluluğu", "Kusursuz Sorumluluk"]
        ]
    },
    "IYUK": {
        "name": "İdari Yargılama Usulü",
        "topics": [
            ["Dava Türleri"],
            ["Dava Türleri", "İptal Davası"],
            ["Dava Türleri", "Tam Yargı Davası"],
            ["Dava Şartları"],
            ["Dava Şartları", "Ehliyet"],
            ["Dava Şartları", "Hak Düşürücü Süreler"],
            ["Dava Şartları", "İdari Merci Tecavüzü"],
            ["Yargılama"],
            ["Yargılama", "Yürütmenin Durdurulması"],
            ["Yargılama", "Yargılama Aşamaları"],
            ["Yargılama", "Karar"],
            ["Kanun Yolları"],
            ["Kanun Yolları", "İstinaf"],
            ["Kanun Yolları", "Temyiz"],
            ["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)"],
            ["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)", "UYAP Düzenlemeleri"],
            ["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)", "Arabuluculuk Kapsamının Genişletilmesi"]
        ]
    },
    "VERGI": {
        "name": "Vergi Hukuku",
        "topics": [
            ["Vergi Hukuku Genel"],
            ["Vergi Hukuku Genel", "Vergi Kanunlarının Uygulanması"],
            ["Vergi Hukuku Genel", "Mükellefiyet"],
            ["Vergi Hukuku Genel", "Vergi Sorumluluğu"],
            ["Vergilendirme Süreci"],
            ["Vergilendirme Süreci", "Tarh"],
            ["Vergilendirme Süreci", "Tebliğ"],
            ["Vergilendirme Süreci", "Tahakkuk"],
            ["Vergilendirme Süreci", "Tahsil"],
            ["Vergi Borcunun Sona Ermesi"],
            ["Vergi Borcunun Sona Ermesi", "Ödeme"],
            ["Vergi Borcunun Sona Ermesi", "Zamanaşımı"],
            ["Vergi Borcunun Sona Ermesi", "Terkin"],
            ["Vergi Suç ve Cezaları"],
            ["Vergi Suç ve Cezaları", "Vergi Kabahatleri"],
            ["Vergi Suç ve Cezaları", "Vergi Suçları"],
            ["Vergi Uyuşmazlıkları"],
            ["Vergi Uyuşmazlıkları", "Uzlaşma"],
            ["Vergi Uyuşmazlıkları", "Vergi Davaları"]
        ]
    },
    "ICRA": {
        "name": "İcra ve İflas Hukuku",
        "topics": [
            ["İcra Takip Yolları"],
            ["İcra Takip Yolları", "İlamsız Takip"],
            ["İcra Takip Yolları", "İlamlı Takip"],
            ["İcra Takip Yolları", "Kambiyo Senetlerine Özgü Takip"],
            ["İcra Takip Yolları", "Kiralanan Taşınmazların Tahliyesi"],
            ["Haciz"],
            ["Haciz", "Haciz İşlemi"],
            ["Haciz", "Haczi Caiz Olmayan Mallar"],
            ["Haciz", "İstihkak"],
            ["Rehnin Paraya Çevrilmesi"],
            ["Rehnin Paraya Çevrilmesi", "Taşınır Rehni"],
            ["Rehnin Paraya Çevrilmesi", "Taşınmaz Rehni"],
            ["İflas"],
            ["İflas", "İflas Sebepleri"],
            ["İflas", "İflas Tasfiyesi"],
            ["Konkordato"],
            ["Konkordato", "Konkordato Şartları"],
            ["Konkordato", "Konkordato Süreci"],
            ["9. Yargı Paketi (İİK Değişiklikleri)"],
            ["9. Yargı Paketi (İİK Değişiklikleri)", "Elektronik Satış Usulü"]
        ]
    },
    "IS": {
        "name": "İş Hukuku ve Sosyal Güvenlik",
        "topics": [
            ["Bireysel İş Hukuku"],
            ["Bireysel İş Hukuku", "İş Sözleşmesi Türleri"],
            ["Bireysel İş Hukuku", "Ücret"],
            ["Bireysel İş Hukuku", "Çalışma Süreleri"],
            ["Fesih"],
            ["Fesih", "Bildirimli Fesih"],
            ["Fesih", "Haklı Nedenle Fesih"],
            ["Fesih", "İş Güvencesi"],
            ["Tazminatlar"],
            ["Tazminatlar", "Kıdem Tazminatı"],
            ["Tazminatlar", "İhbar Tazminatı"],
            ["Sosyal Güvenlik"],
            ["Sosyal Güvenlik", "Sosyal Sigortalar"],
            ["Sosyal Güvenlik", "Emeklilik"],
            ["Toplu İş Hukuku"],
            ["Toplu İş Hukuku", "Sendika"],
            ["Toplu İş Hukuku", "Toplu İş Sözleşmesi"],
            ["Toplu İş Hukuku", "Grev"],
            ["9. Yargı Paketi (Arabuluculuk ve İş Hukuku Değişiklikleri)"],
            ["9. Yargı Paketi (Arabuluculuk ve İş Hukuku Değişiklikleri)", "Zorunlu Arabuluculukta Süre ve Usul"]
        ]
    },
    "AVUKATLIK": {
        "name": "Avukatlık Hukuku",
        "topics": [
            ["Avukatlık Mesleğine Giriş"],
            ["Avukatlık Mesleğine Giriş", "Avukatlığa Kabul Şartları"],
            ["Avukatlık Mesleğine Giriş", "Staj Şartları"],
            ["Avukatlık Mesleğine Giriş", "Staj Süreci"],
            ["Avukatın Hak ve Yükümlülükleri"],
            ["Avukatın Hak ve Yükümlülükleri", "Avukatın Hakları"],
            ["Avukatın Hak ve Yükümlülükleri", "Avukatın Yükümlülükleri"],
            ["Avukatın Hak ve Yükümlülükleri", "Avukatlık Sözleşmesi"],
            ["Avukatın Hak ve Yükümlülükleri", "Avukatlık Ücreti"],
            ["Baro ve Disiplin"],
            ["Baro ve Disiplin", "Baro Teşkilatı"],
            ["Baro ve Disiplin", "Türkiye Barolar Birliği"],
            ["Baro ve Disiplin", "Disiplin İşlemleri"],
            ["9. Yargı Paketi (Avukatlık Mesleği Değişiklikleri)"],
            ["9. Yargı Paketi (Avukatlık Mesleği Değişiklikleri)", "Avukatların Arabuluculuk Faaliyetleri"]
        ]
    },
    "FELSEFE": {
        "name": "Hukuk Felsefesi ve Sosyolojisi",
        "topics": [
            ["Hukuk Felsefesi"],
            ["Hukuk Felsefesi", "Doğal Hukuk"],
            ["Hukuk Felsefesi", "Hukuki Pozitivizm"],
            ["Hukuk Sosyolojisi"],
            ["Hukuk Sosyolojisi", "Hukuk ve Toplum İlişkisi"],
            ["Hukuk Sosyolojisi", "Hukukun İşlevleri"]
        ]
    },
    "MILLETLERARASI": {
        "name": "Milletlerarası Hukuk",
        "topics": [
            ["Devletler Genel Hukuku"],
            ["Devletler Genel Hukuku", "Uluslararası Hukuk Kaynakları"],
            ["Devletler Genel Hukuku", "Devlet ve Tanıma"],
            ["Devletler Genel Hukuku", "Uluslararası Örgütler"],
            ["Devletler Genel Hukuku", "Temel Anlaşmalar"]
        ]
    },
    "MOHUK": {
        "name": "Milletlerarası Özel Hukuk",
        "topics": [
            ["MÖHUK Genel"],
            ["MÖHUK Genel", "Kanunlar İhtilafı"],
            ["MÖHUK Genel", "Uygulanacak Hukuk"],
            ["MÖHUK Genel", "Yabancılar Hukuku"],
            ["MÖHUK Genel", "Milletlerarası Usul Hukuku"]
        ]
    }
}


# ============================================
# MEVCUT SORU KONTROLÜ
# ============================================

def load_existing_questions(subject_code: str) -> tuple:
    """Mevcut soruları yükle ve stem'leri çıkar"""
    output_file = SORULAR_DIR / f"{subject_code}_SORULAR.md"
    
    existing_questions = []
    existing_stems = set()
    max_id = 0
    
    if output_file.exists():
        content = output_file.read_text(encoding="utf-8")
        
        # JSON bloğunu bul
        if "```json" in content:
            try:
                json_start = content.find("```json") + 7
                json_end = content.find("```", json_start)
                existing_json = content[json_start:json_end].strip()
                existing_questions = json.loads(existing_json)
                
                # Stem'leri ve max ID'yi çıkar
                for q in existing_questions:
                    stem = q.get("stem", "").strip().lower()
                    if stem:
                        # İlk 50 karakter yeterli benzersizlik için
                        existing_stems.add(stem[:50])
                    
                    # Max ID bul
                    try:
                        num = int(q["id"].split("-")[1])
                        max_id = max(max_id, num)
                    except:
                        pass
                        
            except json.JSONDecodeError:
                pass
    
    return existing_questions, existing_stems, max_id


# ============================================
# GEMINI API FONKSİYONLARI
# ============================================

def init_gemini():
    """Gemini API'yi başlat"""
    genai.configure(api_key=GEMINI_API_KEY)
    print(f"✅ Gemini API bağlandı (Model: {MODEL_NAME})")
    return True


def upload_pdf_to_gemini(pdf_path: Path) -> object:
    """PDF dosyasını Gemini'ye yükle"""
    if not pdf_path.exists():
        print(f"   ⚠️ PDF bulunamadı: {pdf_path.name}")
        return None
    
    print(f"   📄 Yükleniyor: {pdf_path.name}")
    
    try:
        uploaded_file = genai.upload_file(
            path=str(pdf_path),
            display_name=pdf_path.name
        )
        
        # Yükleme tamamlanana kadar bekle
        while uploaded_file.state.name == "PROCESSING":
            time.sleep(2)
            uploaded_file = genai.get_file(uploaded_file.name)
        
        if uploaded_file.state.name == "FAILED":
            print(f"   ❌ Yükleme başarısız: {pdf_path.name}")
            return None
            
        return uploaded_file
        
    except Exception as e:
        print(f"   ❌ Yükleme hatası: {e}")
        return None


def load_template() -> str:
    """AI_SORU_SABLONU.md dosyasını oku"""
    if TEMPLATE_FILE.exists():
        return TEMPLATE_FILE.read_text(encoding="utf-8")
    return ""


def create_prompt(subject_code: str, subject_info: dict, count: int, 
                  existing_stems: set, start_id: int) -> str:
    """Soru üretim promptunu oluştur"""
    
    timestamp = datetime.now().isoformat() + "Z"
    
    # Mevcut soru örnekleri (tekrarı önlemek için)
    existing_examples = ""
    if existing_stems:
        sample = list(existing_stems)[:5]
        existing_examples = f"""
⚠️ TEKRAR ETME! Aşağıdaki sorulara benzer sorular zaten mevcut:
{chr(10).join(f'- "{s}..."' for s in sample)}

Bu sorulardan FARKLI, ÖZGÜN sorular üret!
"""

    prompt = f"""
# GÖREV
Sen HMGS (Hukuk Mesleklerine Giriş Sınavı) için profesyonel soru yazarısın.
{subject_info['name']} dersi için {count} adet ÖZGÜN çoktan seçmeli soru üret.

{existing_examples}

# KAYNAK PDF'LER
Yukarıda yüklenen PDF dosyalarını analiz et ve bu kaynaklardan:
- Kanun maddelerini doğru şekilde kullan
- Tanımları ve kavramları referans al
- Güncel değişiklikleri (9. Yargı Paketi vb.) dikkate al

# ZORUNLU TOPIC_PATH LİSTESİ
⚠️ SADECE aşağıdaki topic_path değerlerini kullan (BİREBİR kopyala):
```json
{json.dumps(subject_info['topics'], ensure_ascii=False, indent=2)}
```

# ZORUNLU JSON FORMATI
Her soru için tam olarak bu formatı kullan:
```json
{{
  "id": "{subject_code}-{str(start_id + 1).zfill(3)}",
  "subject_code": "{subject_code}",
  "topic_path": ["Ana Grup", "Alt Konu"],
  "difficulty": 1,
  "exam_weight_tag": "core",
  "target_roles": ["genel"],
  "stem": "Soru metni - en az 20 karakter, açık ve net olmalı",
  "options": [
    {{"label": "A", "text": "Şık A metni"}},
    {{"label": "B", "text": "Şık B metni"}},
    {{"label": "C", "text": "Şık C metni"}},
    {{"label": "D", "text": "Şık D metni"}},
    {{"label": "E", "text": "Şık E metni"}}
  ],
  "correct_option": "C",
  "static_explanation": "Detaylı açıklama - neden bu cevabın doğru olduğunu açıkla, diğer şıkların neden yanlış olduğunu belirt, ilgili kanun maddesine atıf yap",
  "ai_hint": "Ezber/dikkat ipucu - kısa ve akılda kalıcı",
  "related_statute": "İlgili kanun maddesi (örn: TCK m.35) veya null",
  "learning_objective": "Bu soruyla test edilen öğrenme hedefi",
  "tags": ["etiket1", "etiket2", "etiket3"],
  "status": "approved"
}}
```

# ZORUNLU KURALLAR

1. **topic_path**: MUTLAKA yukarıdaki listeden BİREBİR seç, maksimum 2 eleman
2. **id**: {subject_code}-{str(start_id + 1).zfill(3)}, {subject_code}-{str(start_id + 2).zfill(3)}, ... şeklinde sıralı
3. **difficulty**: 1=Kolay, 2=Orta, 3=Zor (dengeli dağılım)
4. **exam_weight_tag**: "core"=sık çıkan, "supporting"=destekleyici, "longtail"=nadir
5. **target_roles**: ["genel"] veya ["avukat"], ["hakim"], ["savci"], ["noter"]
6. **options**: TAM 5 şık (A-E), mantıklı çeldiriciler
7. **static_explanation**: Öğretici olmalı, neden doğru olduğunu açıkla
8. **related_statute**: Varsa ilgili kanun maddesi, yoksa null
9. **Tekrar Yok**: Birbirinin aynısı veya çok benzer sorular üretme

# SORU TÜRLERİ
Çeşitlilik için farklı soru türleri kullan:
- Tanım soruları ("X kavramı nedir?")
- Karşılaştırma ("Aşağıdakilerden hangisi A'dan farklıdır?")
- Uygulama ("Bu durumda hangi hüküm uygulanır?")
- Negatif ("Aşağıdakilerden hangisi X değildir?")
- Kanun maddesi ("X Kanunu m.Y'ye göre...")

# ÇIKTI
SADECE JSON array döndür, başka açıklama ekleme:
[soru1, soru2, soru3, ...]
"""
    return prompt


def generate_questions_with_pdfs(subject_code: str, pdf_files: list, count: int = 10) -> list:
    """PDF'leri kullanarak soru üret"""
    
    if subject_code not in SUBJECTS:
        print(f"❌ Geçersiz subject_code: {subject_code}")
        return None
    
    subject = SUBJECTS[subject_code]
    print(f"\n{'='*60}")
    print(f"📚 {subject['name']} için soru üretimi")
    print(f"{'='*60}")
    
    # Mevcut soruları yükle
    existing_questions, existing_stems, max_id = load_existing_questions(subject_code)
    print(f"📊 Mevcut soru sayısı: {len(existing_questions)}")
    
    # PDF'leri yükle
    print(f"\n📤 PDF'ler Gemini'ye yükleniyor...")
    uploaded_files = []
    
    for pdf_name in pdf_files:
        pdf_path = DOCS_DIR / pdf_name
        uploaded = upload_pdf_to_gemini(pdf_path)
        if uploaded:
            uploaded_files.append(uploaded)
    
    if not uploaded_files:
        print("❌ Hiçbir PDF yüklenemedi!")
        return None
    
    print(f"✅ {len(uploaded_files)} PDF başarıyla yüklendi")
    
    # Model oluştur
    model = genai.GenerativeModel(
        model_name=MODEL_NAME,
        generation_config={
            "temperature": 0.8,  # Daha yaratıcı sorular için
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 32768,
        }
    )
    
    # Prompt oluştur
    prompt = create_prompt(subject_code, subject, count, existing_stems, max_id)
    
    # İçerik listesi oluştur (PDF'ler + prompt)
    content_parts = uploaded_files + [prompt]
    
    print(f"\n🔄 {count} soru üretiliyor...")
    
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
        print(f"✅ {len(questions)} soru başarıyla üretildi!")
        
        # Yüklenen dosyaları temizle
        print("🧹 Geçici dosyalar temizleniyor...")
        for f in uploaded_files:
            try:
                genai.delete_file(f.name)
            except:
                pass
        
        return questions
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON parse hatası: {e}")
        print(f"   Ham yanıt (ilk 1000 karakter):\n{response_text[:1000]}")
        return None
    except Exception as e:
        print(f"❌ API hatası: {e}")
        return None


def validate_and_fix_questions(questions: list, subject_code: str, existing_stems: set, start_id: int) -> list:
    """Soruları doğrula ve düzelt"""
    
    valid_topics = SUBJECTS.get(subject_code, {}).get("topics", [])
    valid_questions = []
    current_id = start_id
    
    for i, q in enumerate(questions):
        errors = []
        
        # Tekrar kontrolü
        stem = q.get("stem", "").strip().lower()[:50]
        if stem in existing_stems:
            print(f"   ⚠️ Soru {i+1}: Tekrar tespit edildi, atlanıyor")
            continue
        existing_stems.add(stem)
        
        # ID düzelt
        current_id += 1
        q["id"] = f"{subject_code}-{str(current_id).zfill(3)}"
        
        # subject_code düzelt
        q["subject_code"] = subject_code
        
        # Topic kontrolü ve düzeltme
        topic_path = q.get("topic_path", [])
        topic_valid = False
        
        for t in valid_topics:
            if topic_path == t:
                topic_valid = True
                break
        
        if not topic_valid:
            # En yakın topic'i bul
            if len(topic_path) > 0:
                for t in valid_topics:
                    if len(t) > 0 and topic_path[0] == t[0]:
                        q["topic_path"] = t
                        topic_valid = True
                        break
            
            if not topic_valid and valid_topics:
                q["topic_path"] = valid_topics[0]
                errors.append(f"Topic düzeltildi: {topic_path} → {valid_topics[0]}")
        
        # Zorunlu alanlar
        if "stem" not in q or len(q.get("stem", "")) < 20:
            errors.append("Stem çok kısa veya eksik")
            continue
        
        if len(q.get("options", [])) != 5:
            errors.append(f"Şık sayısı 5 olmalı")
            continue
        
        # Varsayılan değerler
        if "difficulty" not in q or q["difficulty"] not in [1, 2, 3]:
            q["difficulty"] = 2
        
        if "exam_weight_tag" not in q:
            q["exam_weight_tag"] = "core"
        
        if "target_roles" not in q or not q["target_roles"]:
            q["target_roles"] = ["genel"]
        
        if "status" not in q:
            q["status"] = "approved"
        
        if errors:
            print(f"   ⚠️ Soru {current_id}: {', '.join(errors)}")
        
        valid_questions.append(q)
    
    return valid_questions


def save_questions(questions: list, subject_code: str, existing_questions: list):
    """Soruları dosyaya kaydet"""
    
    # sorular/ klasörü yoksa oluştur
    SORULAR_DIR.mkdir(exist_ok=True)
    
    output_file = SORULAR_DIR / f"{subject_code}_SORULAR.md"
    
    # Birleştir
    all_questions = existing_questions + questions
    
    # Markdown oluştur
    subject_name = SUBJECTS.get(subject_code, {}).get("name", subject_code)
    
    # Topic dağılımını hesapla
    topic_counts = {}
    for q in all_questions:
        topic = q.get("topic_path", ["Bilinmeyen"])
        key = " > ".join(topic)
        topic_counts[key] = topic_counts.get(key, 0) + 1
    
    topic_summary = "\n".join([f"- {k}: {v} soru" for k, v in sorted(topic_counts.items())])
    
    md_content = f"""# {subject_name} Soruları

**Toplam Soru Sayısı:** {len(all_questions)}
**Son Güncelleme:** {datetime.now().strftime("%Y-%m-%d %H:%M")}
**Kaynak:** Gemini 2.5 Flash + PDF Analizi

## 📊 Konu Dağılımı
{topic_summary}

---

```json
{json.dumps(all_questions, ensure_ascii=False, indent=2)}
```
"""
    
    output_file.write_text(md_content, encoding="utf-8")
    print(f"\n💾 Kaydedildi: {output_file}")
    print(f"   Yeni eklenen: {len(questions)}")
    print(f"   Toplam soru: {len(all_questions)}")


# ============================================
# ANA FONKSİYON
# ============================================

def main():
    parser = argparse.ArgumentParser(
        description="Gemini 2.5 Flash + PDF ile HMGS Soru Üretici",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Örnekler:
  python generate_questions_with_pdf.py --list
  python generate_questions_with_pdf.py -s ANAYASA -c 10
  python generate_questions_with_pdf.py -s CMK -c 20
  python generate_questions_with_pdf.py --all -c 5
        """
    )
    parser.add_argument("--subject", "-s", type=str, help="Ders kodu (örn: ANAYASA)")
    parser.add_argument("--count", "-c", type=int, default=10, help="Üretilecek soru sayısı")
    parser.add_argument("--all", "-a", action="store_true", help="Tüm dersler için üret")
    parser.add_argument("--list", "-l", action="store_true", help="Ders ve PDF eşleştirmesini göster")
    parser.add_argument("--no-save", action="store_true", help="Kaydetmeden sadece göster")
    
    args = parser.parse_args()
    
    # PDF'leri tara ve grupla
    all_pdfs = scan_docs_folder()
    pdf_groups = auto_group_pdfs(all_pdfs)
    
    # Ders listesi
    if args.list:
        print(f"\n📂 docs/ klasöründe {len(all_pdfs)} PDF bulundu")
        print("\n📚 Ders-PDF Eşleştirmesi:")
        print("=" * 70)
        
        for code, info in SUBJECTS.items():
            pdfs = pdf_groups.get(code, [])
            status = "✅" if pdfs else "⚠️"
            print(f"\n{status} {code}: {info['name']}")
            print(f"   Topics: {len(info['topics'])} konu")
            
            if pdfs:
                print(f"   PDFs ({len(pdfs)}):")
                for pdf in pdfs:
                    exists = "✓" if (DOCS_DIR / pdf).exists() else "✗"
                    print(f"      [{exists}] {pdf}")
            else:
                print("   ⚠️ Eşleşen PDF yok!")
        
        return
    
    # API başlat
    init_gemini()
    
    # Tüm dersler
    if args.all:
        print("\n🚀 Tüm dersler için soru üretimi başlıyor...")
        
        for subject_code, info in SUBJECTS.items():
            pdfs = pdf_groups.get(subject_code, [])
            
            if not pdfs:
                print(f"\n⚠️ {subject_code}: PDF bulunamadı, atlanıyor...")
                continue
            
            # Mevcut soruları yükle
            existing_questions, existing_stems, max_id = load_existing_questions(subject_code)
            
            # Soru üret
            questions = generate_questions_with_pdfs(subject_code, pdfs, args.count)
            
            if questions:
                questions = validate_and_fix_questions(questions, subject_code, existing_stems, max_id)
                
                if not args.no_save and questions:
                    save_questions(questions, subject_code, existing_questions)
            
            # Rate limit için bekle
            print("⏳ Rate limit için 10 saniye bekleniyor...")
            time.sleep(10)
        
        print("\n✅ Tüm dersler tamamlandı!")
        return
    
    # Tek ders
    if args.subject:
        subject_code = args.subject.upper()
        
        if subject_code not in SUBJECTS:
            print(f"❌ Geçersiz ders kodu: {subject_code}")
            print(f"   Geçerli kodlar: {', '.join(SUBJECTS.keys())}")
            return
        
        pdfs = pdf_groups.get(subject_code, [])
        
        if not pdfs:
            print(f"⚠️ {subject_code} için PDF bulunamadı!")
            print("   docs/ klasörüne ilgili PDF'leri ekleyin.")
            return
        
        # Mevcut soruları yükle
        existing_questions, existing_stems, max_id = load_existing_questions(subject_code)
        
        # Soru üret
        questions = generate_questions_with_pdfs(subject_code, pdfs, args.count)
        
        if questions:
            questions = validate_and_fix_questions(questions, subject_code, existing_stems, max_id)
            
            if args.no_save:
                print("\n📋 Üretilen Sorular:")
                print(json.dumps(questions, ensure_ascii=False, indent=2))
            elif questions:
                save_questions(questions, subject_code, existing_questions)
        
        return
    
    # Parametre verilmedi
    parser.print_help()


if __name__ == "__main__":
    main()
