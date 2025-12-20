# 📖 Ders İçeriği Üretim Formatı (AI Referansı)

Bu dosyayı AI aracınıza vererek ders içeriği ürettirin.

---

## 🎯 Hedef Yapı

Her konu için şu JSON yapısında içerik üretilmeli:

```json
{
  "topicId": "TOPIC_ID_BURAYA",
  "topicName": "Konu Adı",
  "subjectName": "Ders Adı",
  "steps": [
    {
      "stepNumber": 1,
      "title": "Adım 1 Başlığı (max 50 karakter)",
      "content": "## Alt Başlık\n\nİçerik metni burada. **Kalın** ve *italik* kullanılabilir.\n\n### Önemli Noktalar:\n- Madde 1\n- Madde 2\n- Madde 3\n\n> 💡 Önemli ipucu veya uyarı"
    },
    {
      "stepNumber": 2,
      "title": "Adım 2 Başlığı",
      "content": "..."
    },
    {
      "stepNumber": 3,
      "title": "Adım 3 Başlığı",
      "content": "..."
    },
    {
      "stepNumber": 4,
      "title": "Adım 4 Başlığı",
      "content": "..."
    },
    {
      "stepNumber": 5,
      "title": "Adım 5 Başlığı",
      "content": "..."
    }
  ],
  "practiceQuestions": [
    {
      "question": "Soru metni burada?",
      "options": {
        "A": "Birinci seçenek",
        "B": "İkinci seçenek",
        "C": "Üçüncü seçenek",
        "D": "Dördüncü seçenek"
      },
      "correctAnswer": "B",
      "explanation": "Doğru cevap B'dir çünkü..."
    }
  ],
  "createdAt": ""
}
```

---

## 📋 Gereksinimler

### Steps (Hap Bilgiler)
| Alan | Açıklama |
|------|----------|
| `stepNumber` | 1-5 arası sıra numarası |
| `title` | Kısa başlık (max 50 karakter) |
| `content` | Markdown formatında içerik |

**Content Formatı:**
- `## Başlık` - Ana başlık
- `### Alt Başlık` - Alt başlık  
- `**kalın**` - Önemli terimler
- `- madde` - Madde işaretleri
- `> alıntı` - İpucu kutuları
- `\n` - Satır sonu

### Practice Questions (Sorular)
| Alan | Açıklama |
|------|----------|
| `question` | Soru metni |
| `options` | A, B, C, D seçenekleri |
| `correctAnswer` | "A", "B", "C" veya "D" |
| `explanation` | Neden doğru olduğunun açıklaması |

**Soru Sayısı:** Her konu için 10 soru üretilmeli.

---

## 📝 Örnek Prompt

AI aracınıza şu formatta istek gönderin:

```
Aşağıdaki PDF içeriğini kullanarak ders içeriği oluştur:

**Konu:** Temel Hak ve Özgürlükler
**Ders:** Anayasa Hukuku
**Topic ID:** qyJyS3u01x1hlTozZ0Iz

Yukarıdaki JSON formatında:
- 5 adım (hap bilgi)
- 10 çoktan seçmeli soru

SADECE JSON çıktısı ver.
```

---

## ✅ Kontrol Listesi

JSON üretildikten sonra kontrol edin:
- [ ] 5 adet step var mı?
- [ ] Her step'te stepNumber, title, content var mı?
- [ ] Content markdown formatında mı?
- [ ] 10 adet soru var mı?
- [ ] Her soruda A, B, C, D seçenekleri var mı?
- [ ] correctAnswer "A", "B", "C" veya "D" mi?
- [ ] Her soruda explanation var mı?
- [ ] topicId doğru mu?

---

## 📂 Kaydetme

Üretilen JSON'u şu konuma kaydedin:
```
lesson_content/[Ders Adı]/[topicId].json
```

Örnek:
```
lesson_content/Anayasa Hukuku/qyJyS3u01x1hlTozZ0Iz.json
```
