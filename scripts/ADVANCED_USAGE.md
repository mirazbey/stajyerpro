# 🚀 Gelişmiş Soru Üretim Sistemi - Kullanım Kılavuzu

## 🎯 Özellikler

✅ **Multi-PDF İşleme**: Aynı ders için birden fazla PDF'yi birleştirerek işler  
✅ **Tekrar Tespit**: Firestore'daki mevcut sorularla %85 benzerlik kontrolü  
✅ **Konu Bazlı**: Her HMGS dersi için ayrı konfigürasyon  
✅ **Büyük PDF Desteği**: 700 sayfalık PDF'leri parça parça işler  
✅ **Progress Tracking**: Kaldığı yerden devam edebilir  
✅ **Akıllı Chunking**: Paragraf sınırlarını koruyarak böler

## 📋 Kurulum

```bash
# Gerekli paketler
pip install google-generativeai PyPDF2 firebase-admin pyyaml

# API key ayarla
$env:GEMINI_API_KEY="your-api-key"
```

## 🎓 Kullanım

### 1. Tek Ders İşle (Örnek: Medeni Hukuk)

```bash
python scripts/advanced_question_generator.py --subject medeni_hukuk
```

Bu komut:
- `medeni hukuk ders notları.pdf` (17MB, 600+ sayfa)
- `türk medeni kanunu.pdf`
- `Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf`

3 PDF'yi **birleştirip** işler ve **200 soru** üretir.

### 2. Tüm Dersleri İşle

```bash
python scripts/advanced_question_generator.py --all
```

⚠️ **DİKKAT**: Bu komut **tüm 13 dersi** işler (~1400 soru), ~2-3 saat sürer!

### 3. Konfigürasyonu Özelleştir

`scripts/subject_config.yaml` dosyasını düzenle:

```yaml
medeni_hukuk:
  target_questions: 300  # 200'den 300'e çıkar
  pdfs:
    - "yeni_pdf.pdf"     # Yeni PDF ekle
```

## 🔄 İşleyiş Akışı

```
1. Config dosyasını oku (subject_config.yaml)
   ↓
2. Dersin PDF'lerini birleştir (örn: 3 PDF → tek metin)
   ↓
3. Metni 8000 karakterlik chunk'lara böl
   ↓
4. Her chunk için Gemini'ye istek
   ↓
5. Üretilen soruları Firestore ile karşılaştır (deduplication)
   ↓
6. Benzersiz soruları JSON'a kaydet
   ↓
7. Progress dosyasını güncelle
```

## 📊 Çıktı Örneği

```bash
====================================================================
📚 Medeni Hukuk İşleniyor
====================================================================

📖 3 PDF birleştiriliyor...
  📄 Okunuyor: medeni hukuk ders notları.pdf
     ✅ 300/642 sayfa okundu
  📄 Okunuyor: türk medeni kanunu.pdf
     ✅ 150/150 sayfa okundu
  📄 Okunuyor: Anayasa Hukukunun Temel Esasları.pdf
     ✅ 200/350 sayfa okundu

✅ Toplam 1,245,832 karakter metin
📦 156 parçaya bölündü

--- Chunk 1/156 ---
🤖 Gemini'ye 8 soru üretimi için istek gönderiliyor...
✅ 8 soru üretildi
✅ Şu ana kadar: 8 soru

--- Chunk 2/156 ---
🤖 Gemini'ye 8 soru üretimi için istek gönderiliyor...
     🔁 Benzer soru bulundu (benzerlik: 91%)
     ⏭️ Tekrar soru atlandı
✅ 7 soru üretildi
✅ Şu ana kadar: 15 soru

...

🎯 Hedef soru sayısına ulaşıldı (200), durduruluyor.

✅ Medeni Hukuk: 200 soru üretildi
💾 Kaydedildi: generated_questions/medeni_hukuk_questions.json
```

## 🎛️ Parametreler (subject_config.yaml)

| Parametre | Açıklama | Varsayılan |
|-----------|----------|------------|
| `max_pages_per_pdf` | Her PDF'den kaç sayfa okunur | 300 |
| `questions_per_chunk` | Her chunk için soru sayısı | 8 |
| `chunk_size` | Chunk boyutu (karakter) | 8000 |
| `enable_deduplication` | Tekrar tespit aktif mi? | true |
| `similarity_threshold` | Benzerlik eşiği (%85) | 0.85 |

## 💡 İpuçları

### 1. Büyük PDF'ler İçin

700 sayfalık PDF → `max_pages_per_pdf: 500` yap (tamamını işle)

```yaml
settings:
  max_pages_per_pdf: 500  # Daha fazla sayfa
```

### 2. Daha Fazla Soru İçin

```yaml
medeni_hukuk:
  target_questions: 500  # 200'den 500'e çıkar
```

### 3. Deduplication Devre Dışı (Test İçin)

```yaml
settings:
  enable_deduplication: false  # Tekrar kontrolü yapma
```

### 4. Kaldığı Yerden Devam

Script otomatik olarak `generated_questions/progress.json` oluşturur.

Tekrar çalıştırınca:
```
✅ Bu ders zaten işlenmiş, atlanıyor.
Yine de işlemek ister misin? (y/n):
```

## 💰 Maliyet Tahmini

| Senaryo | Chunk Sayısı | Maliyet |
|---------|--------------|---------|
| Medeni Hukuk (200 soru) | ~25 chunk | ~$0.025 |
| Tüm Dersler (1400 soru) | ~175 chunk | ~$0.20 |

**Toplam: $0.20 (20 kuruş!)** 🎉

## 🐛 Sorun Giderme

### "Benzer soru bulundu" çok sık

`similarity_threshold` artır:

```yaml
similarity_threshold: 0.90  # %90 benzerlik gerekiyor
```

### Gemini timeout

`chunk_size` küçült:

```yaml
chunk_size: 6000  # 8000 → 6000
```

### PDF okuma hatası

PDF şifreli olabilir. Şifreyi kaldır veya OCR kullan.

## 📝 Örnek Komutlar

```bash
# Ceza hukuku (3 PDF birleşik)
python scripts/advanced_question_generator.py --subject ceza_hukuku

# İdare hukuku
python scripts/advanced_question_generator.py --subject idare_hukuku

# Progress sıfırla (tümünü baştan işle)
rm generated_questions/progress.json
python scripts/advanced_question_generator.py --all
```

## 🎯 Sonuç

Bu sistem ile:
- ✅ **4-5 PDF'yi birleştirerek** işleyebilirsin
- ✅ **Tekrar soru üretmez** (Firestore karşılaştırması)
- ✅ **700 sayfalık PDF'leri** handle eder
- ✅ **Konu bazlı** organize eder

**Tahmini Süre**: 13 ders × 10 dk = **~2 saat** (1400 soru)
