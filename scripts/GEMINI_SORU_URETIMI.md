# 🤖 Gemini ile Otomatik Soru Üretimi

## 📋 Genel Bakış

Bu sistem, Google Gemini 2.0 Flash API'sini kullanarak HMGS (Hukuk Mesleklerine Giriş Sınavı) 
için otomatik çoktan seçmeli soru üretir.

### 🎯 İki Script Mevcut:

| Script | Açıklama | Avantaj |
|--------|----------|---------|
| `generate_questions_gemini.py` | Sadece prompt tabanlı | Hızlı, API limiti az kullanır |
| `generate_questions_with_pdf.py` | **PDF'leri Gemini'ye yükler** ⭐ | Kaynak bazlı, daha doğru |

---

## Kurulum

### 1. Gerekli Paket
```powershell
pip install google-generativeai
```

### 2. API Key Alma
1. https://aistudio.google.com/ adresine gidin
2. "Get API Key" butonuna tıklayın
3. Yeni API key oluşturun

### 3. API Key Ayarlama

**Windows (PowerShell):**
```powershell
$env:GEMINI_API_KEY = "your-api-key-here"
```

**Kalıcı Ayar (Windows):**
```powershell
[System.Environment]::SetEnvironmentVariable("GEMINI_API_KEY", "your-api-key-here", "User")
```

---

## 🌟 PDF Tabanlı Soru Üretimi (ÖNERİLEN)

Bu yöntem, `docs/` klasöründeki PDF'leri doğrudan Gemini'ye yükleyerek kaynak bazlı soru üretir.

### Nasıl Çalışır?

```
┌─────────────────────────────────────────────────────────────┐
│                    ÇALIŞMA AKIŞI                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  docs/ Klasörü          Gemini 2.0 Flash        Çıktı      │
│  ┌────────────┐         ┌─────────────┐      ┌──────────┐  │
│  │ Kanunlar   │ ──────► │             │      │ JSON     │  │
│  │ ders notları│        │   ANALIZ    │ ───► │ Sorular  │  │
│  │ 9.yargı pak│ ──────► │   + ÜRETIM  │      │          │  │
│  └────────────┘         └─────────────┘      └──────────┘  │
│        │                       │                   │       │
│        ▼                       ▼                   ▼       │
│  TC Anayasası.pdf    AI_SORU_SABLONU.md    ANAYASA-001    │
│  türk ceza kanunu    Topic Validation      ANAYASA-002    │
│  9.yargı paketi.pdf  Zorunlu Format        ANAYASA-003    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Komutlar

```powershell
# Dersleri ve PDF kaynaklarını listele
python scripts/generate_questions_with_pdf.py --list

# Anayasa için 10 soru üret (PDF'lerden)
python scripts/generate_questions_with_pdf.py --subject ANAYASA --count 10

# CMK için 20 soru üret
python scripts/generate_questions_with_pdf.py -s CMK -c 20

# Tüm dersler için 5'er soru üret
python scripts/generate_questions_with_pdf.py --all --count 5

# Kaydetmeden önizle
python scripts/generate_questions_with_pdf.py -s MEDENI -c 3 --no-save
```

### Her Ders İçin Kullanılan PDF'ler

| Ders | PDF Kaynakları |
|------|----------------|
| ANAYASA | TC Anayasası.pdf, Kemal Gözler notları |
| MEDENI | Türk Medeni Kanunu, ders notları, 9.yargı paketi |
| BORCLAR | Türk Borçlar Kanunu, ders notları |
| TICARET | Türk Ticaret Kanunu, ders notları, 9.yargı paketi |
| CEZA | TCK, genel/özel hükümler notları, 9.yargı paketi |
| CMK | CMK, 7188, 7499 kanunlar, 9.yargı paketi |
| IDARE | İdari yargı notları, 9.yargı paketi |
| IYUK | İYUK, idari yargı notları |
| VERGI | VUK, Türk Vergi Sistemi |
| ICRA | İİK, ders notları, 9.yargı paketi |
| IS | İş Kanunu, İş Mahkemeleri, SGK, 9.yargı paketi |
| AVUKATLIK | Avukatlık Kanunu, HMGS yönetmeliği, 9.yargı paketi |
| FELSEFE | Hukuk felsefesi, Genel kamu hukuku notları |
| MILLETLERARASI | Milletlerarası hukuk ders notları |
| MOHUK | MÖHUK kanunu |

---

## 📝 Prompt Tabanlı Soru Üretimi

PDF yüklemeden, sadece prompt ile soru üretir. Daha hızlıdır ama kaynak referansı yoktur.

```powershell
# Mevcut dersleri listele
python scripts/generate_questions_gemini.py --list

# Belirli bir ders için 10 soru üret
python scripts/generate_questions_gemini.py --subject ANAYASA --count 10

# Belirli bir topic için soru üret
python scripts/generate_questions_gemini.py -s CEZA -c 15 --topic "Tutuklama"
```

---

## 📚 Ders Kodları

| Kod | Ders |
|-----|------|
| ANAYASA | Anayasa Hukuku |
| MEDENI | Medeni Hukuku |
| BORCLAR | Borçlar Hukuku |
| TICARET | Ticaret Hukuku |
| CEZA | Ceza Hukuku |
| CMK | Ceza Muhakemesi Hukuku |
| IDARE | İdare Hukuku |
| IYUK | İdari Yargılama Usulü |
| VERGI | Vergi Hukuku |
| ICRA | İcra ve İflas Hukuku |
| IS | İş Hukuku |
| AVUKATLIK | Avukatlık Hukuku |
| FELSEFE | Hukuk Felsefesi |
| MILLETLERARASI | Milletlerarası Hukuk |
| MOHUK | Milletlerarası Özel Hukuk |

---

## 📁 Çıktı

Sorular `sorular/` klasörüne kaydedilir:
- `sorular/ANAYASA_SORULAR.md`
- `sorular/CMK_SORULAR.md`
- vb.

Her çalıştırmada mevcut sorulara eklenir (append mode).

---

## 🎯 Örnek Kullanım Senaryoları

### Senaryo 1: Tek Ders İçin PDF'den Toplu Üretim
```powershell
# Anayasa için 50 soru (5x10)
python scripts/generate_questions_with_pdf.py -s ANAYASA -c 10
# ... 5 kez tekrarla
```

### Senaryo 2: 9. Yargı Paketi Soruları (PDF Tabanlı)
```powershell
# 9. Yargı Paketi PDF'ini kullanan dersler
$subjects = @("CMK", "CEZA", "MEDENI", "TICARET", "ICRA", "IS", "IDARE", "AVUKATLIK")
foreach ($s in $subjects) {
    python scripts/generate_questions_with_pdf.py -s $s -c 10
    Start-Sleep -Seconds 10  # Rate limit için bekle
}
```

### Senaryo 3: Günlük Otomatik Üretim Script'i
```powershell
# daily_generate.ps1
$env:GEMINI_API_KEY = "your-key"
$subjects = @("ANAYASA", "MEDENI", "CEZA", "CMK", "IDARE")
foreach ($s in $subjects) {
    Write-Host "Generating questions for $s..."
    python scripts/generate_questions_with_pdf.py -s $s -c 5
    Start-Sleep -Seconds 10
}
Write-Host "Done!"
```

---

## ⚠️ Dikkat Edilecekler

1. **PDF Yükleme Süresi**: Her PDF yüklemesi birkaç saniye sürer

2. **Rate Limiting**: Gemini API'nin günlük limiti var
   - Günde ~1500 istek (ücretsiz)
   - PDF yükleme işlemleri limit sayılır

3. **Topic Kontrolü**: Script otomatik olarak geçersiz topic_path'leri düzeltir

4. **JSON Formatı**: Üretilen sorular doğrudan Firestore'a yüklenmeye hazır

5. **Manuel İnceleme**: Üretilen soruları import etmeden önce gözden geçirin

---

## 🔧 Sorun Giderme

### "GEMINI_API_KEY ayarlanmamış" hatası
```powershell
$env:GEMINI_API_KEY = "your-key"
```

### "PDF bulunamadı" uyarısı
- `docs/` klasöründe ilgili PDF'in olduğundan emin olun
- Script diğer mevcut PDF'lerle devam eder

### JSON parse hatası
- `--count` değerini düşürün (10'dan 5'e)
- Script JSON'u otomatik temizler

### Rate limit hatası
- 10-15 saniye bekleyip tekrar deneyin
- Günlük limiti aştıysanız yarın tekrar deneyin

### PDF yükleme hatası
- PDF dosya boyutu çok büyük olabilir
- Gemini'nin desteklediği PDF boyut limiti: ~50MB

---

## 💰 Maliyet

Gemini 2.0 Flash **ücretsizdir** (belirli limitler dahilinde):
- Günde ~1500 istek
- Dakikada ~15 istek
- PDF yükleme: ~100 dosya/dakika

Ücretli plan için: https://ai.google.dev/pricing

---

## 🔄 NotebookLM vs Gemini API

| Özellik | NotebookLM | Gemini API + PDF |
|---------|------------|------------------|
| PDF Yükleme | ✅ Manuel | ✅ Otomatik |
| Toplu Üretim | ❌ Manuel chat | ✅ Script ile |
| Format Kontrolü | ❌ Manuel | ✅ Otomatik JSON |
| Topic Validation | ❌ Yok | ✅ Otomatik |
| Rate Limit | Belirsiz | Günde ~1500 |
| Kullanım | Tarayıcı | Terminal |

**Önerimiz**: Büyük ölçekli soru üretimi için `generate_questions_with_pdf.py` kullanın.
