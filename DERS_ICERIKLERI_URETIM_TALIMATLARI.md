# DERS İÇERİKLERİ ÜRETİM TALİMATLARI

## AMAÇ

Flutter uygulamasındaki **Dersler** kartı, Firestore'daki `topics` collection'ından konuları çeker. Her konu tıklandığında:

1. `topic_lessons` collection'ından o konunun içeriği sorgulanır (topicId ile eşleştirme)
2. İçerik bulunursa: 5 adımlı ders + 5 pratik soru gösterilir
3. İçerik bulunamazsa: Boş ekran veya hata

**SORUN:** `flutter clean` komutu `build/all_pdf_outputs/` klasöründeki 349 JSON dosyasını sildi. Bu dosyalar Firestore'a hiç yüklenmediği için `topic_lessons` collection'ı boştu (0 döküman). Sonuç: Uygulama boş içerik gösteriyordu.

**ÇÖZÜM:** 297 boş topic için AI ile yeniden içerik üret, `generated_lessons/` klasörüne kaydet (flutter clean'den güvende), Firestore'a otomatik yükle.

## MEVCUT DURUM

✅ 19 topic başarıyla üretildi (generated_lessons/ klasöründe)
✅ 19 topic Firestore'a yüklendi (topic_lessons collection)
❌ 278 topic eksik - bunlar üretilmeli!

## KULLANILACAK DOSYALAR

### Ana Script
- Dosya: generate_comprehensive.py
- Çıktı Klasörü: generated_lessons/ (flutter clean'den etkilenmez)
- Firestore Collection: topic_lessons

### PDF Kaynaklar (docs/ klasöründe)
- Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf (her topic için)
- 2025 hukuk meslekleri soru bankasi.pdf (her topic için)
- Konuya özel PDFler (ceza hukuku, medeni hukuk, vs.)

### Firestore Bağlantı
- Credentials: service-account.json
- API Key: .env dosyasında GEMINI_API_KEY
- Yedek API Keyler: Script içinde tanımlı

## YAPILMASI GEREKEN 4 DEŞKLK

### 1. Otomatik Başlatma (Satır 166 civarı)

ESK KOD (SL):
if input("Start? (y/n): ").lower() != "y":
    sys.exit(0)

YEN KOD (YAZ):
print("AUTO-STARTING...")

### 2. PDF Yükleme Fonksiyonu (Satır 56-65 civarı)

Tüm find_pdfs fonksiyonunu değiştir:

def find_pdfs(subject, topic):
    texts = []
    if not DOCS_DIR.exists(): 
        return texts
    
    # Referans kitaplar HER ZAMAN yükle
    reference_books = [
        "Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf",
        "2025 hukuk meslekleri soru bankasi.pdf"
    ]
    
    for ref_name in reference_books:
        for pdf in DOCS_DIR.glob(f"**/{ref_name}"):
            print(f"  [REF] {ref_name}", flush=True)
            txt = extract_pdf(pdf, max_chars=5000)
            if txt: 
                texts.append(txt)
    
    # Konu-spesifik PDFler
    subj_slug = slugify(subject)
    for pdf in DOCS_DIR.glob("**/*.pdf"):
        if pdf.name in reference_books: 
            continue
        if subj_slug in slugify(pdf.stem):
            print(f"  [PDF] {pdf.name}", flush=True)
            txt = extract_pdf(pdf)
            if txt: 
                texts.append(txt)
    
    return texts

### 3. Gelişmiş Loglama (Satır 177-195 civarı)

TÜM print() komutlarına flush=True ekle:

print(f"\n[{idx}/{len(empty)}] {tname} ({sname})", flush=True)

pdfs = find_pdfs(sname, tname)
print(f"  PDFs found: {len(pdfs)}", flush=True)

api_key = get_api_key()
data = generate(tname, sname, pdfs, api_key)

if data:
    slug = f"{slugify(sname)}__{slugify(tname)}"
    jpath = OUTPUT_DIR / f"{slug}.json"
    with open(jpath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"  [OK] Saved: {jpath.name}", flush=True)
    success += 1
    
    if upload(tid, data):
        print(f"  [UPLOAD] Firestore OK", flush=True)
        uploaded += 1
    else:
        print(f"  [UPLOAD] Firestore FAILED", flush=True)
    
    time.sleep(3)
else:
    print(f"  [FAIL] Generation failed", flush=True)
    failed.append((tid, tname, sname))
    time.sleep(1)

### 4. Model Ayarı (Satır 108 civarı)

DORU MODEL:
model = genai.GenerativeModel("gemini-2.5-flash")

## ÇALIŞTIRMA

PowerShell'de çalıştır:
python -u generate_comprehensive.py

NOT: -u parametresi buffering'i kapatır, logları anında görürsün.

## BEKLENEN ÇIKTI

================================================================================
COMPREHENSIVE LESSON GENERATOR
================================================================================
Output: C:\Users\HP\Desktop\StajyerPro\generated_lessons
PDFs: C:\Users\HP\Desktop\StajyerPro\docs
API Keys: 1

Topics: 348, Empty: 278
Estimated time: ~139 minutes
AUTO-STARTING...

[1/278] Hukuka Aykırılık (Ceza Hukuku)
  [REF] Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf
  [REF] 2025 hukuk meslekleri soru bankasi.pdf
  [PDF] ceza hukuku genel hükümler ders notları.pdf
  PDFs found: 3
  [OK] Saved: ceza_hukuku__hukuka_aykirlik.json
  [UPLOAD] Firestore OK

Progress: 10/278 | Success: 10 | Uploaded: 10
Time: 5.2min | Remaining: ~135min

## LERLEME TAKB

Kaç dosya üretildi:
Get-ChildItem generated_lessons -Filter "*.json" | Measure-Object | Select-Object -ExpandProperty Count

Firestore'da kaç lesson var:
python -c "import firebase_admin; from firebase_admin import credentials, firestore; cred = credentials.Certificate('service-account.json') if not firebase_admin._apps else None; firebase_admin.initialize_app(cred) if cred else None; db = firestore.client(); print(len(list(db.collection('topic_lessons').stream())))"

Script çalışıyor mu:
Get-Process python -ErrorAction SilentlyContinue

Son üretilen dosya:
Get-ChildItem generated_lessons -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

## SORUN GDERME

Script duruyor:
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item -Recurse -Force __pycache__, *.pyc -ErrorAction SilentlyContinue
python -u generate_comprehensive.py

PDF'ler yüklenmiyor:
Get-ChildItem docs -Recurse -Filter "*.pdf"

API Quota aşıldı (429 error):
Script otomatik başka key'e geçer, bekle

## BEKLENEN SÜRE

- Toplam: 278 topic
- Ortalama: 30-40 saniye/topic
- Tahmini: 2.5-3 saat

## TAMAMLANINCA

1. Kontrol: 278 JSON dosyası var mı?
2. Firestore: 297 topic_lessons var mı? (19 eski + 278 yeni)
3. Flutter app test: Dersler bölümünde içerik görünüyor mu?

## YEDEKLEME

Üretim bitince:
Compress-Archive -Path generated_lessons -DestinationPath "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
