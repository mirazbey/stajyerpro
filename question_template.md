# StajyerPro Soru Üretim Şablonu

Bu şablon, HMGS hazırlık soruları üretirken kullanılacak format ve kuralları içerir.

## 📌 Kritik Kurallar

1. **topic_path ZORUNLU** - Her sorunun doğru konuya atanması için gerekli
2. **Hiyerarşik yapıya uygun olmalı** - Ana Grup → Alt Konu şeklinde
3. **Türkçe karakter kullanılabilir** - Sistem otomatik eşleştirir

---

## 🎯 Müfredat Yapısı

Sorular aşağıdaki hiyerarşiye göre `topic_path` almalı:

```
subjects/
├── anayasa_hukuku
│   ├── Anayasa Hukukuna Giriş (grup)
│   │   ├── Anayasa Kavramı
│   │   ├── Devletin Unsurları
│   │   └── Hükümet Sistemleri
│   ├── Temel Hak ve Özgürlükler (grup)
│   │   ├── Temel Hakların Niteliği
│   │   ├── Sınırlandırma Rejimi
│   │   └── Kişi Hakları
│   └── ...
├── medeni_hukuk
│   ├── Başlangıç Hükümleri (grup)
│   │   ├── Hukukun Uygulanması
│   │   ├── İyiniyet ve Dürüstlük Kuralı
│   │   └── İspat Yükü
│   ├── Kişiler Hukuku (grup)
│   │   ├── Gerçek Kişiler
│   │   ├── Hak ve Fiil Ehliyeti
│   │   └── Kısıtlılık ve Vesayet
│   └── ...
└── ... (diğer dersler)
```

---

## 📝 JSON Şablonu

```json
{
  "id": "MEDENI-001",
  "subject_code": "CIVIL",
  "topic_path": [
    "Kişiler Hukuku",           // Ana grup adı
    "Hak ve Fiil Ehliyeti"      // Alt konu adı (EN SPESIFIK)
  ],
  "difficulty": 2,
  "exam_weight_tag": "core",
  "target_roles": ["avukat", "hakim"],
  "stem": "Türk Medeni Kanunu'na göre, ergin kılınmış (kazai rüşt) bir kişi ile ilgili aşağıdaki ifadelerden hangisi yanlıştır?",
  "options": [
    {"label": "A", "text": "Ergin kılınma kararı, kişiye tam fiil ehliyeti kazandırır."},
    {"label": "B", "text": "Ergin kılınabilmek için kişinin en az 15 yaşını doldurmuş olması gerekir."},
    {"label": "C", "text": "Ergin kılınma için küçüğün ve velinin rızası aranır."},
    {"label": "D", "text": "Ergin kılınma kararı, mahkeme tarafından verilir."},
    {"label": "E", "text": "Ergin kılınan kişi, velayetten çıkar ve vesayet altına alınır."}
  ],
  "correct_option": "E",
  "static_explanation": "Ergin kılınan kişi tam ehliyetli sayılır ve velayetten çıkar; ancak vesayet altına alınmaz. Vesayet, kısıtlılık hallerinde söz konusudur. TMK m. 12'ye göre ergin kılınma şartları belirtilmiştir.",
  "ai_hint": "Ergin kılınma (kazai rüşt) ile vesayet kavramları farklıdır. TMK m.12'deki şartlara odaklanın.",
  "related_statute": "TMK m.12, m.404",
  "learning_objective": "Ergin kılınma kurumunun şartlarını ve sonuçlarını açıklayabilmek.",
  "source_pdf": "medeni_hukuk_notlari.pdf",
  "source_page": 45,
  "tags": ["ergin kılınma", "fiil ehliyeti", "velayet"],
  "created_at": "2025-12-01T12:00:00Z",
  "status": "draft"
}
```

---

## 🏷️ Subject Code Listesi

| subject_code | Firestore ID | Ders Adı |
|--------------|--------------|----------|
| `CIVIL`, `MEDENI` | medeni_hukuk | Medeni Hukuk |
| `OBLIGATIONS`, `BORCLAR` | borclar_hukuku | Borçlar Hukuku |
| `CRIMINAL`, `CEZA`, `TCK` | ceza_hukuku | Ceza Hukuku |
| `CRIM_PROC`, `CMK` | ceza_muhakemesi | Ceza Muhakemesi |
| `COMMERCIAL`, `TTK` | ticaret_hukuku | Ticaret Hukuku |
| `ADMIN`, `IDARE` | idare_hukuku | İdare Hukuku |
| `IYUK` | idari_yargilama | İdari Yargılama Usulü |
| `CONSTITUTION`, `ANAYASA` | anayasa_hukuku | Anayasa Hukuku |
| `HMK` | hukuk_muhakemeleri | Hukuk Muhakemeleri |
| `ICRA`, `IIK` | icra_iflas | İcra ve İflas Hukuku |
| `VERGI`, `TAX` | vergi_hukuku | Vergi Hukuku |
| `IS`, `LABOR` | is_hukuku | İş Hukuku |
| `ATTORNEY`, `AVUKATLIK` | avukatlik_hukuku | Avukatlık Hukuku |
| `FELSEFE`, `PHILOSOPHY` | hukuk_felsefesi | Hukuk Felsefesi |
| `INTERNATIONAL` | milletlerarasi_hukuk | Milletlerarası Hukuk |
| `MOHUK` | mohuk | Milletlerarası Özel Hukuk |

---

## ✅ topic_path Örnekleri

### Doğru Kullanım ✅

```json
// En spesifik konuya kadar
"topic_path": ["Suçun Genel Teorisi", "Teşebbüs"]

// Grup seviyesinde (alt konu belirsizse)
"topic_path": ["Aile Hukuku"]

// 9. Yargı Paketi konuları
"topic_path": ["9. Yargı Paketi (CMK Değişiklikleri)", "Tutuklama Şartlarında Değişiklik"]
```

### Yanlış Kullanım ❌

```json
// Çok genel - eşleşmez
"topic_path": ["Genel"]

// Ders adı değil grup/konu adı olmalı
"topic_path": ["Medeni Hukuk", "Kişiler Hukuku"]  // ❌ Ders adı gereksiz

// Doğrusu:
"topic_path": ["Kişiler Hukuku", "Gerçek Kişiler"]  // ✅
```

---

## 🔧 AI Prompt Örneği

Soru üretirken AI'a şu prompt verilebilir:

```
HMGS sınavı için {ders_adı} dersinden {konu_adı} konusunda 5 soru üret.

Kurallar:
1. Her soru JSON formatında olmalı
2. topic_path: ["{ana_grup}", "{alt_konu}"] şeklinde olmalı
3. difficulty: 1 (kolay), 2 (orta), 3 (zor)
4. static_explanation: Doğru cevabın neden doğru olduğunu açıkla
5. ai_hint: Öğrenciye pratik ipucu ver
6. related_statute: İlgili kanun maddelerini belirt

Örnek topic_path değerleri:
- Teşebbüs için: ["Suçun Özel Görünüş Şekilleri", "Teşebbüs"]
- Boşanma için: ["Aile Hukuku", "Boşanma"]
- Tutuklama için: ["Soruşturma", "Tutuklama"]
```

---

## 📊 Kalite Kontrol Checklist

Soru import etmeden önce kontrol edin:

- [ ] `stem` dolu mu?
- [ ] `options` en az 4 şık içeriyor mu?
- [ ] `correct_option` A-E arasında mı?
- [ ] `topic_path` müfredattaki bir konuyla eşleşiyor mu?
- [ ] `static_explanation` öğretici mi?
- [ ] `related_statute` varsa doğru mu?

---

## 🚀 Import Komutu

```bash
# Müfredat haritasını güncelle (konular değiştiyse)
python scripts/export_curriculum_map.py

# Soruları import et
python import_questions_v2.py
```
