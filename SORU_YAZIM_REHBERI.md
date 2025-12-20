# 📝 StajyerPro Soru Yazım Rehberi

## ✅ Doğru Format

```json
{
  "id": "CEZA-001",
  "subject_code": "CEZA",
  "topic_path": ["Suçun Özel Görünüş Şekilleri", "Teşebbüs"],
  "difficulty": 2,
  "exam_weight_tag": "core",
  "target_roles": ["genel"],
  "stem": "Soru metni...",
  "options": [
    {"label": "A", "text": "..."},
    {"label": "B", "text": "..."},
    {"label": "C", "text": "..."},
    {"label": "D", "text": "..."},
    {"label": "E", "text": "..."}
  ],
  "correct_option": "B",
  "static_explanation": "Açıklama...",
  "ai_hint": "İpucu...",
  "related_statute": "TCK m.35",
  "learning_objective": "Öğrenme hedefi",
  "tags": ["teşebbüs", "ceza"],
  "status": "approved"
}
```

---

## 📌 subject_code Değerleri

| subject_code | Ders Adı |
|--------------|----------|
| `ANAYASA` | Anayasa Hukuku |
| `MEDENI` | Medeni Hukuk |
| `BORCLAR` | Borçlar Hukuku |
| `TICARET` | Ticaret Hukuku |
| `CEZA` | Ceza Hukuku |
| `CMK` | Ceza Muhakemesi Hukuku |
| `IDARE` | İdare Hukuku |
| `HMK` | Hukuk Muhakemeleri Kanunu |
| `IYUK` | İdari Yargılama Usulü |
| `VERGI` | Vergi Hukuku |
| `ICRA` | İcra ve İflas Hukuku |
| `IS` | İş Hukuku ve Sosyal Güvenlik |
| `AVUKATLIK` | Avukatlık Hukuku |
| `FELSEFE` | Hukuk Felsefesi ve Sosyolojisi |
| `MILLETLERARASI` | Milletlerarası Hukuk |
| `MOHUK` | Milletlerarası Özel Hukuk |

---

## 📌 topic_path Kuralları

### ⚠️ ÖNEMLİ: Maksimum 2 seviye!

**Format:** `["Ana Grup", "Alt Konu"]` veya sadece `["Ana Grup"]`

### Örnek topic_path Değerleri (Derse Göre)

#### ANAYASA
```
["Anayasa Hukukuna Giriş", "Anayasa Kavramı"]
["Anayasa Hukukuna Giriş", "Devletin Unsurları"]
["Anayasa Hukukuna Giriş", "Hükümet Sistemleri"]
["Anayasa Hukukuna Giriş", "Egemenlik"]
["Anayasa Hukukuna Giriş", "Kuvvetler Ayrılığı"]
["Temel Hak ve Özgürlükler", "Temel Hakların Niteliği"]
["Temel Hak ve Özgürlükler", "Sınırlandırma Rejimi"]
["Temel Hak ve Özgürlükler", "Kişi Hakları"]
["Temel Hak ve Özgürlükler", "Sosyal ve Ekonomik Haklar"]
["Temel Hak ve Özgürlükler", "Siyasi Haklar"]
["Yasama", "TBMM'nin Görevleri"]
["Yasama", "Milletvekilliği"]
["Yasama", "Kanun Yapım Süreci"]
["Yasama", "Denetim Yolları"]
["Yürütme", "Cumhurbaşkanı'nın Görevleri"]
["Yürütme", "Cumhurbaşkanlığı Kararnameleri"]
["Yürütme", "Bakanlar"]
["Yürütme", "Olağanüstü Hal"]
["Yargı", "Hakimler ve Savcılar Kurulu"]
["Yargı", "Yargı Bağımsızlığı"]
["Yargı", "Anayasa Mahkemesi Görevleri"]
["Yargı", "İptal Davası ve İtiraz Yolu"]
["Yargı", "Bireysel Başvuru"]
```

#### MEDENI
```
["Başlangıç Hükümleri", "Hukukun Uygulanması"]
["Başlangıç Hükümleri", "İyiniyet ve Dürüstlük Kuralı"]
["Başlangıç Hükümleri", "İspat Yükü"]
["Kişiler Hukuku", "Gerçek Kişiler"]
["Kişiler Hukuku", "Kişiliğin Başlangıcı ve Sonu"]
["Kişiler Hukuku", "Hak ve Fiil Ehliyeti"]
["Kişiler Hukuku", "Kısıtlılık ve Vesayet"]
["Kişiler Hukuku", "Kişiliğin Korunması"]
["Tüzel Kişiler", "Tüzel Kişi Kavramı"]
["Tüzel Kişiler", "Dernekler"]
["Tüzel Kişiler", "Vakıflar"]
["Aile Hukuku", "Nişanlanma"]
["Aile Hukuku", "Evlenme"]
["Aile Hukuku", "Boşanma"]
["Aile Hukuku", "Mal Rejimleri"]
["Aile Hukuku", "Soybağı"]
["Aile Hukuku", "Velayet"]
["Aile Hukuku", "Nafaka"]
["Miras Hukuku", "Yasal Mirasçılar"]
["Miras Hukuku", "Saklı Pay"]
["Miras Hukuku", "Ölüme Bağlı Tasarruflar"]
["Miras Hukuku", "Mirasın Geçişi"]
["Eşya Hukuku", "Zilyetlik"]
["Eşya Hukuku", "Tapu Sicili"]
["Eşya Hukuku", "Mülkiyet"]
["Eşya Hukuku", "Sınırlı Ayni Haklar"]
["Eşya Hukuku", "Rehin ve İpotek"]
```

#### BORCLAR
```
["Borç İlişkisinin Kaynakları", "Sözleşmeden Doğan Borçlar"]
["Borç İlişkisinin Kaynakları", "Sözleşmenin Kurulması"]
["Borç İlişkisinin Kaynakları", "Geçersizlik Halleri"]
["Borç İlişkisinin Kaynakları", "Temsil"]
["Haksız Fiil", "Haksız Fiil Şartları"]
["Haksız Fiil", "Kusur Sorumluluğu"]
["Haksız Fiil", "Kusursuz Sorumluluk"]
["Haksız Fiil", "Tazminat"]
["Sebepsiz Zenginleşme", "Sebepsiz Zenginleşme Şartları"]
["Sebepsiz Zenginleşme", "İade Borcu"]
["Borcun İfası ve Sona Ermesi", "İfa"]
["Borcun İfası ve Sona Ermesi", "Borçlu Temerrüdü"]
["Borcun İfası ve Sona Ermesi", "Alacaklı Temerrüdü"]
["Borcun İfası ve Sona Ermesi", "Zamanaşımı"]
["Özel Borç İlişkileri", "Satış Sözleşmesi"]
["Özel Borç İlişkileri", "Kira Sözleşmesi"]
["Özel Borç İlişkileri", "Eser Sözleşmesi"]
["Özel Borç İlişkileri", "Vekalet Sözleşmesi"]
["Özel Borç İlişkileri", "Hizmet Sözleşmesi"]
["Özel Borç İlişkileri", "Kefalet Sözleşmesi"]
```

#### TICARET
```
["Ticari İşletme", "Ticari İşletme Kavramı"]
["Ticari İşletme", "Tacir"]
["Ticari İşletme", "Ticaret Unvanı"]
["Ticari İşletme", "Ticaret Sicili"]
["Ticari İşletme", "Haksız Rekabet"]
["Şirketler Hukuku", "Şirket Kavramı"]
["Şirketler Hukuku", "Adi Şirket"]
["Şirketler Hukuku", "Kollektif ve Komandit Şirket"]
["Şirketler Hukuku", "Anonim Şirket Organları"]
["Şirketler Hukuku", "Limited Şirket"]
["Kıymetli Evrak", "Kıymetli Evrak Temel Hükümler"]
["Kıymetli Evrak", "Poliçe"]
["Kıymetli Evrak", "Bono"]
["Kıymetli Evrak", "Çek"]
```

#### CEZA
```
["Ceza Hukukuna Giriş", "Ceza Hukukunun Temel İlkeleri"]
["Ceza Hukukuna Giriş", "Suçta ve Cezada Kanunilik"]
["Ceza Hukukuna Giriş", "Ceza Kanunlarının Uygulanması"]
["Suçun Genel Teorisi", "Maddi Unsur"]
["Suçun Genel Teorisi", "Manevi Unsur"]
["Suçun Genel Teorisi", "Hukuka Aykırılık"]
["Suçun Genel Teorisi", "Kusur"]
["Suçun Özel Görünüş Şekilleri", "Teşebbüs"]
["Suçun Özel Görünüş Şekilleri", "İştirak"]
["Suçun Özel Görünüş Şekilleri", "İçtima"]
["Yaptırımlar", "Cezalar"]
["Yaptırımlar", "Güvenlik Tedbirleri"]
["Özel Suçlar", "Hayata Karşı Suçlar"]
["Özel Suçlar", "Vücut Dokunulmazlığına Karşı Suçlar"]
["Özel Suçlar", "Malvarlığına Karşı Suçlar"]
["Özel Suçlar", "Kamu İdaresine Karşı Suçlar"]
```

#### CMK
```
["Ceza Muhakemesine Giriş", "CMK Temel İlkeleri"]
["Ceza Muhakemesine Giriş", "Yetki Kuralları"]
["Soruşturma", "Soruşturma Aşaması"]
["Soruşturma", "Gözaltı"]
["Soruşturma", "Tutuklama"]
["Soruşturma", "Adli Kontrol"]
["Deliller", "Arama ve Elkoyma"]
["Deliller", "İletişimin Denetlenmesi"]
["Deliller", "Delil Değerlendirmesi"]
["Kovuşturma", "İddianame"]
["Kovuşturma", "Duruşma"]
["Kovuşturma", "Hüküm"]
["Kanun Yolları", "İtiraz"]
["Kanun Yolları", "İstinaf"]
["Kanun Yolları", "Temyiz"]
```

#### IDARE
```
["İdarenin Kuruluşu", "Merkezi İdare"]
["İdarenin Kuruluşu", "Yerinden Yönetim"]
["İdarenin Kuruluşu", "Kamu Tüzel Kişileri"]
["İdari İşlemler", "Düzenleyici İşlemler"]
["İdari İşlemler", "Bireysel İşlemler"]
["İdari İşlemler", "İdari İşlemin Unsurları"]
["Kamu Görevlileri", "Memur Kavramı"]
["Kamu Görevlileri", "Memurun Hakları"]
["Kamu Görevlileri", "Memurun Yükümlülükleri"]
["Kamu Görevlileri", "Disiplin"]
["Kolluk", "Kolluk Kavramı"]
["Kolluk", "Kolluk Yetkileri"]
["Kamu Malları", "Kamu Malı Kavramı"]
["Kamu Malları", "Kamulaştırma"]
["İdarenin Sorumluluğu", "Hizmet Kusuru"]
["İdarenin Sorumluluğu", "Kusursuz Sorumluluk"]
```

#### IYUK
```
["Dava Türleri", "İptal Davası"]
["Dava Türleri", "Tam Yargı Davası"]
["Dava Şartları", "Ehliyet"]
["Dava Şartları", "Hak Düşürücü Süreler"]
["Dava Şartları", "İdari Merci Tecavüzü"]
["Yargılama", "Yürütmenin Durdurulması"]
["Yargılama", "Yargılama Aşamaları"]
["Yargılama", "Karar"]
["Kanun Yolları", "İstinaf"]
["Kanun Yolları", "Temyiz"]
```

#### VERGI
```
["Vergi Hukuku Genel", "Vergi Kanunlarının Uygulanması"]
["Vergi Hukuku Genel", "Mükellefiyet"]
["Vergi Hukuku Genel", "Vergi Sorumluluğu"]
["Vergilendirme Süreci", "Tarh"]
["Vergilendirme Süreci", "Tebliğ"]
["Vergilendirme Süreci", "Tahakkuk"]
["Vergilendirme Süreci", "Tahsil"]
["Vergi Borcunun Sona Ermesi", "Ödeme"]
["Vergi Borcunun Sona Ermesi", "Zamanaşımı"]
["Vergi Borcunun Sona Ermesi", "Terkin"]
["Vergi Suç ve Cezaları", "Vergi Kabahatleri"]
["Vergi Suç ve Cezaları", "Vergi Suçları"]
["Vergi Uyuşmazlıkları", "Uzlaşma"]
["Vergi Uyuşmazlıkları", "Vergi Davaları"]
```

#### ICRA
```
["İcra Takip Yolları", "İlamsız Takip"]
["İcra Takip Yolları", "İlamlı Takip"]
["İcra Takip Yolları", "Kambiyo Senetlerine Özgü Takip"]
["İcra Takip Yolları", "Kiralanan Taşınmazların Tahliyesi"]
["Haciz", "Haciz İşlemi"]
["Haciz", "Haczi Caiz Olmayan Mallar"]
["Haciz", "İstihkak"]
["Rehnin Paraya Çevrilmesi", "Taşınır Rehni"]
["Rehnin Paraya Çevrilmesi", "Taşınmaz Rehni"]
["İflas", "İflas Sebepleri"]
["İflas", "İflas Tasfiyesi"]
["Konkordato", "Konkordato Şartları"]
["Konkordato", "Konkordato Süreci"]
```

#### IS
```
["Bireysel İş Hukuku", "İş Sözleşmesi Türleri"]
["Bireysel İş Hukuku", "Ücret"]
["Bireysel İş Hukuku", "Çalışma Süreleri"]
["Fesih", "Bildirimli Fesih"]
["Fesih", "Haklı Nedenle Fesih"]
["Fesih", "İş Güvencesi"]
["Tazminatlar", "Kıdem Tazminatı"]
["Tazminatlar", "İhbar Tazminatı"]
["Sosyal Güvenlik", "Sosyal Sigortalar"]
["Sosyal Güvenlik", "Emeklilik"]
["Toplu İş Hukuku", "Sendika"]
["Toplu İş Hukuku", "Toplu İş Sözleşmesi"]
["Toplu İş Hukuku", "Grev"]
```

#### AVUKATLIK
```
["Avukatlık Mesleğine Giriş", "Avukatlığa Kabul Şartları"]
["Avukatlık Mesleğine Giriş", "Staj Şartları"]
["Avukatlık Mesleğine Giriş", "Staj Süreci"]
["Avukatın Hak ve Yükümlülükleri", "Avukatın Hakları"]
["Avukatın Hak ve Yükümlülükleri", "Avukatın Yükümlülükleri"]
["Avukatın Hak ve Yükümlülükleri", "Avukatlık Sözleşmesi"]
["Avukatın Hak ve Yükümlülükleri", "Avukatlık Ücreti"]
["Baro ve Disiplin", "Baro Teşkilatı"]
["Baro ve Disiplin", "Türkiye Barolar Birliği"]
["Baro ve Disiplin", "Disiplin İşlemleri"]
```

#### FELSEFE
```
["Hukuk Felsefesi", "Doğal Hukuk"]
["Hukuk Felsefesi", "Hukuki Pozitivizm"]
["Hukuk Sosyolojisi", "Hukuk ve Toplum İlişkisi"]
["Hukuk Sosyolojisi", "Hukukun İşlevleri"]
```

#### MILLETLERARASI
```
["Devletler Genel Hukuku", "Uluslararası Hukuk Kaynakları"]
["Devletler Genel Hukuku", "Devlet ve Tanıma"]
["Devletler Genel Hukuku", "Uluslararası Örgütler"]
["Devletler Genel Hukuku", "Temel Anlaşmalar"]
```

#### MOHUK
```
["MÖHUK Genel", "Kanunlar İhtilafı"]
["MÖHUK Genel", "Uygulanacak Hukuk"]
["MÖHUK Genel", "Yabancılar Hukuku"]
["MÖHUK Genel", "Milletlerarası Usul Hukuku"]
```

---

## 🔴 YAPILMAMASI GEREKENLER

### ❌ YANLIŞ: 3 seviyeli topic_path
```json
"topic_path": ["Hukuk Felsefesi", "Antik Yunan Felsefesi", "Sofistler"]
```

### ✅ DOĞRU: 2 seviyeli topic_path  
```json
"topic_path": ["Hukuk Felsefesi", "Doğal Hukuk"]
```

### ❌ YANLIŞ: Müfredatta olmayan konu
```json
"topic_path": ["Hukuk Felsefesi", "Sofistler"]
```
> "Sofistler" müfredatta yok. "Doğal Hukuk" veya "Hukuki Pozitivizm" kullan.

### ❌ YANLIŞ: Eski subject_code formatı
```json
"subject_code": "PHIL_SOCIOLOGY"
```

### ✅ DOĞRU: Yeni subject_code
```json
"subject_code": "FELSEFE"
```

### ❌ YANLIŞ: Boş target_roles
```json
"target_roles": []
```

### ✅ DOĞRU: En az bir değer
```json
"target_roles": ["genel"]
```

---

## 📋 Tam Örnek Soru

```json
{
  "id": "FELSEFE-001",
  "subject_code": "FELSEFE",
  "topic_path": ["Hukuk Felsefesi", "Hukuki Pozitivizm"],
  "difficulty": 2,
  "exam_weight_tag": "supporting",
  "target_roles": ["genel"],
  "stem": "Hans Kelsen'in Saf Hukuk Kuramı'nda, hukuk düzenindeki en üstteki norm olan Anayasa'nın yürürlüğünü ve geçerliliğini sağlayan, varsayımsal olarak kabul edilen kavram aşağıdakilerden hangisidir?",
  "options": [
    {"label": "A", "text": "Sosyal Sözleşme"},
    {"label": "B", "text": "Doğal Yasa"},
    {"label": "C", "text": "Temel Norm (Grundnorm)"},
    {"label": "D", "text": "Egemenin İradesi"},
    {"label": "E", "text": "Yargısal İçtihatlar"}
  ],
  "correct_option": "C",
  "static_explanation": "Kelsen'e göre Anayasa normları kendi yürürlüklerini Grundnorm'dan (Temel Norm'dan) alırlar. Temel norm, hukuksal düzende yer alan diğer normların geçerliliğine ilişkindir.",
  "ai_hint": "Kelsen'in piramit şeklindeki normlar hiyerarşisinin en tepesinde yer alan kavramı hatırla.",
  "related_statute": null,
  "learning_objective": "Kelsen'in Saf Hukuk Kuramı'ndaki Temel Norm kavramını açıklayabilme.",
  "tags": ["kelsen", "pozitivizm", "temel norm"],
  "created_at": "2025-12-01T10:00:00Z",
  "status": "approved"
}
```

---

## ⚠️ 9. Yargı Paketi Konuları

9. Yargı Paketi soruları için subject_code'a göre farklı topic_path kullan:

| Ders | topic_path örneği |
|------|-------------------|
| MEDENI | `["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Temyiz Edilebilir Kararlar"]` |
| TICARET | `["9. Yargı Paketi (Ticari Uyuşmazlık Değişiklikleri)", "Ticari Davalarda Zorunlu Arabuluculuk Kapsamı"]` |
| CEZA | `["9. Yargı Paketi (TCK Değişiklikleri)", "Uzlaştırma Kapsamında Değişiklikler"]` |
| CMK | `["9. Yargı Paketi (CMK Değişiklikleri)", "Tutuklama Şartlarında Değişiklik"]` |
| ICRA | `["9. Yargı Paketi (İİK Değişiklikleri)", "Elektronik Satış Usulü"]` |
| IS | `["9. Yargı Paketi (Arabuluculuk ve İş Hukuku Değişiklikleri)", "Zorunlu Arabuluculukta Süre ve Usul"]` |
| AVUKATLIK | `["9. Yargı Paketi (Avukatlık Mesleği Değişiklikleri)", "Avukatların Arabuluculuk Faaliyetleri"]` |
| IYUK | `["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)", "UYAP Düzenlemeleri"]` |

---

## 🚀 Hızlı Kontrol Listesi

Soru yazmadan önce kontrol et:

- [ ] `subject_code` yukarıdaki tabloda var mı?
- [ ] `topic_path` maksimum 2 eleman mı?
- [ ] `topic_path` değerleri müfredatta birebir var mı?
- [ ] `target_roles` boş değil mi? (en az `["genel"]`)
- [ ] `static_explanation` dolu mu?
- [ ] `difficulty` 1-3 arasında mı?
