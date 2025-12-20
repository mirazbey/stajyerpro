# 🤖 AI ile Soru Üretimi - Kullanım Kılavuzu

Bu pipeline, `docs/` klasöründeki PDF'lerden otomatik olarak HMGS tarzı sorular üretir.

## 📋 Gereksinimler

```bash
pip install google-generativeai PyPDF2 firebase-admin
```

## 🔑 API Key Ayarı

Gemini API key'ini environment variable olarak ekle:

```bash
# Windows (PowerShell)
$env:GEMINI_API_KEY="your-api-key-here"

# Linux/Mac
export GEMINI_API_KEY="your-api-key-here"
```

API key almak için: https://aistudio.google.com/app/apikey

## 🚀 Kullanım

### 1. Tek PDF'ten Soru Üret

```bash
python scripts/generate_questions_from_pdf.py --pdf "docs/medeni hukuk ders notları.pdf"
```

### 2. Tüm PDF'lerden Soru Üret

```bash
python scripts/generate_questions_from_pdf.py --dir docs/
```

### 3. Parametreler

- `--pdf`: Tek PDF dosyası işle
- `--dir`: Klasördeki tüm PDF'leri işle (default: `docs/`)
- `--output`: Çıktı klasörü (default: `generated_questions/`)
- `--questions-per-chunk`: Her metin parçası için kaç soru üretilsin (default: 5)

### 4. Firestore'a Import

```bash
# Tek JSON dosyası import
python scripts/import_generated_questions.py --file "generated_questions/medeni_hukuk_questions.json"

# Tüm JSON dosyalarını import
python scripts/import_generated_questions.py --dir generated_questions/
```

## 📊 Örnek Workflow

```bash
# 1. Medeni Hukuku işle (10 soru/chunk)
python scripts/generate_questions_from_pdf.py \
  --pdf "docs/medeni hukuk ders notları.pdf" \
  --questions-per-chunk 10

# 2. Üretilen soruları kontrol et
cat generated_questions/medeni_hukuk_ders_notları_questions.json

# 3. Firestore'a yükle
python scripts/import_generated_questions.py \
  --file "generated_questions/medeni_hukuk_ders_notları_questions.json"
```

## ⚙️ Nasıl Çalışır?

1. **PDF Okuma**: PyPDF2 ile PDF'in ilk 50 sayfası okunur
2. **Chunking**: Metin 6000 karakterlik parçalara bölünür (Gemini token limiti)
3. **AI Soru Üretimi**: Her chunk için Gemini 2.0 Flash ile sorular üretilir
4. **JSON Export**: Sorular `generated_questions/` klasörüne JSON olarak kaydedilir
5. **Firestore Import**: JSON dosyaları Firestore'daki `questions` collection'a eklenir

## 💰 Maliyet

Gemini 2.0 Flash çok ucuz:
- ~6000 token input: $0.00015
- ~500 token output: $0.0006
- **Toplam ~$0.001 per chunk** (5 soru)

Örnek: 20 PDF × 3 chunk × $0.001 = **~$0.06** (60 kuruş!)

## ⚠️ Önemli Notlar

1. **Manuel Review Şart**: AI üretimi sonrası **mutlaka** gözden geçir:
   - Doğru cevap gerçekten doğru mu?
   - Çeldirici şıklar gerçekçi mi?
   - Kanun maddesi doğru mu?

2. **Batch Limiti**: İlk çalıştırmada az PDF ile test et (maliyet kontrolü)

3. **Subject/Topic ID'leri**: JSON'daki `subjectId` ve `topicIds` alanlarını Firestore'daki gerçek ID'lerle eşleştir

## 🎯 Hedef

Bu pipeline ile:
- **500 soru** → ~1 saat
- **2000 soru** → ~4 saat
- **Maliyet** → ~$2-3

Manuel veri girişine göre **100x hızlı**! 🚀
