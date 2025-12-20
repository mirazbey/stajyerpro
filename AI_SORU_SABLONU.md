# StajyerPro Soru Üretim Şablonu (AI için)

## 🎯 Görev
HMGS (Hukuk Mesleklerine Giriş Sınavı) için çoktan seçmeli sorular üret.

---

## 📋 JSON Formatı

```json
{
  "id": "DERSKODU-001",
  "subject_code": "DERSKODU",
  "topic_path": ["Ana Grup", "Alt Konu"],
  "difficulty": 1,
  "exam_weight_tag": "core",
  "target_roles": ["genel"],
  "stem": "Soru metni (en az 20 karakter)",
  "options": [
    {"label": "A", "text": "Şık A"},
    {"label": "B", "text": "Şık B"},
    {"label": "C", "text": "Şık C"},
    {"label": "D", "text": "Şık D"},
    {"label": "E", "text": "Şık E"}
  ],
  "correct_option": "C",
  "static_explanation": "Doğru cevabın açıklaması (öğretici olmalı)",
  "ai_hint": "Ezber/dikkat ipucu",
  "related_statute": "Kanun maddesi (örn: TCK m.35)",
  "learning_objective": "Bu soruyla kazanılacak öğrenme hedefi",
  "tags": ["etiket1", "etiket2"],
  "status": "approved"
}
```

---

## 📌 ZORUNLU KURALLAR

### 1. subject_code (Ders Kodu)
Sadece bu değerleri kullan:

| Kod | Ders |
|-----|------|
| ANAYASA | Anayasa Hukuku |
| MEDENI | Medeni Hukuk |
| BORCLAR | Borçlar Hukuku |
| TICARET | Ticaret Hukuku |
| CEZA | Ceza Hukuku |
| CMK | Ceza Muhakemesi Hukuku |
| IDARE | İdare Hukuku |
| IYUK | İdari Yargılama Usulü |
| VERGI | Vergi Hukuku |
| ICRA | İcra ve İflas Hukuku |
| IS | İş Hukuku ve Sosyal Güvenlik |
| AVUKATLIK | Avukatlık Hukuku |
| FELSEFE | Hukuk Felsefesi ve Sosyolojisi |
| MILLETLERARASI | Milletlerarası Hukuk |
| MOHUK | Milletlerarası Özel Hukuk |

### 2. topic_path (Konu Yolu)
⚠️ **MAKSİMUM 2 ELEMAN!** Format: `["Ana Grup", "Alt Konu"]`

Aşağıdaki listeden BİREBİR seç (yazım hatasına dikkat!):

---

## 📚 TÜM DERSLER VE KONULAR

### ANAYASA
```
["Anayasa Hukukuna Giriş"]
["Anayasa Hukukuna Giriş", "Anayasa Kavramı"]
["Anayasa Hukukuna Giriş", "Devletin Unsurları"]
["Anayasa Hukukuna Giriş", "Hükümet Sistemleri"]
["Anayasa Hukukuna Giriş", "Egemenlik"]
["Anayasa Hukukuna Giriş", "Kuvvetler Ayrılığı"]
["Temel Hak ve Özgürlükler"]
["Temel Hak ve Özgürlükler", "Temel Hakların Niteliği"]
["Temel Hak ve Özgürlükler", "Sınırlandırma Rejimi"]
["Temel Hak ve Özgürlükler", "Kişi Hakları"]
["Temel Hak ve Özgürlükler", "Sosyal ve Ekonomik Haklar"]
["Temel Hak ve Özgürlükler", "Siyasi Haklar"]
["Yasama"]
["Yasama", "TBMM'nin Görevleri"]
["Yasama", "Milletvekilliği"]
["Yasama", "Kanun Yapım Süreci"]
["Yasama", "Denetim Yolları"]
["Yürütme"]
["Yürütme", "Cumhurbaşkanı'nın Görevleri"]
["Yürütme", "Cumhurbaşkanlığı Kararnameleri"]
["Yürütme", "Bakanlar"]
["Yürütme", "Olağanüstü Hal"]
["Yargı"]
["Yargı", "Hakimler ve Savcılar Kurulu"]
["Yargı", "Yargı Bağımsızlığı"]
["Yargı", "Anayasa Mahkemesi Görevleri"]
["Yargı", "İptal Davası ve İtiraz Yolu"]
["Yargı", "Bireysel Başvuru"]
```

### MEDENI
```
["Başlangıç Hükümleri"]
["Başlangıç Hükümleri", "Hukukun Uygulanması"]
["Başlangıç Hükümleri", "İyiniyet ve Dürüstlük Kuralı"]
["Başlangıç Hükümleri", "İspat Yükü"]
["Kişiler Hukuku"]
["Kişiler Hukuku", "Gerçek Kişiler"]
["Kişiler Hukuku", "Kişiliğin Başlangıcı ve Sonu"]
["Kişiler Hukuku", "Hak ve Fiil Ehliyeti"]
["Kişiler Hukuku", "Kısıtlılık ve Vesayet"]
["Kişiler Hukuku", "Kişiliğin Korunması"]
["Tüzel Kişiler"]
["Tüzel Kişiler", "Tüzel Kişi Kavramı"]
["Tüzel Kişiler", "Dernekler"]
["Tüzel Kişiler", "Vakıflar"]
["Aile Hukuku"]
["Aile Hukuku", "Nişanlanma"]
["Aile Hukuku", "Evlenme"]
["Aile Hukuku", "Boşanma"]
["Aile Hukuku", "Mal Rejimleri"]
["Aile Hukuku", "Soybağı"]
["Aile Hukuku", "Velayet"]
["Aile Hukuku", "Nafaka"]
["Miras Hukuku"]
["Miras Hukuku", "Yasal Mirasçılar"]
["Miras Hukuku", "Saklı Pay"]
["Miras Hukuku", "Ölüme Bağlı Tasarruflar"]
["Miras Hukuku", "Mirasın Geçişi"]
["Eşya Hukuku"]
["Eşya Hukuku", "Zilyetlik"]
["Eşya Hukuku", "Tapu Sicili"]
["Eşya Hukuku", "Mülkiyet"]
["Eşya Hukuku", "Sınırlı Ayni Haklar"]
["Eşya Hukuku", "Rehin ve İpotek"]
["9. Yargı Paketi (HMK ve TMK Değişiklikleri)"]
["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Temyiz Edilebilir Kararlar"]
["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Temyiz Süresi Değişiklikleri"]
["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Dava Şartlarında Düzenlemeler"]
["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Elektronik Tebligat Sistemi"]
["9. Yargı Paketi (HMK ve TMK Değişiklikleri)", "Aile İçi Şiddet Koruma Tedbirleri"]
```

### BORCLAR
```
["Borç İlişkisinin Kaynakları"]
["Borç İlişkisinin Kaynakları", "Sözleşmeden Doğan Borçlar"]
["Borç İlişkisinin Kaynakları", "Sözleşmenin Kurulması"]
["Borç İlişkisinin Kaynakları", "Geçersizlik Halleri"]
["Borç İlişkisinin Kaynakları", "Temsil"]
["Haksız Fiil"]
["Haksız Fiil", "Haksız Fiil Şartları"]
["Haksız Fiil", "Kusur Sorumluluğu"]
["Haksız Fiil", "Kusursuz Sorumluluk"]
["Haksız Fiil", "Tazminat"]
["Sebepsiz Zenginleşme"]
["Sebepsiz Zenginleşme", "Sebepsiz Zenginleşme Şartları"]
["Sebepsiz Zenginleşme", "İade Borcu"]
["Borcun İfası ve Sona Ermesi"]
["Borcun İfası ve Sona Ermesi", "İfa"]
["Borcun İfası ve Sona Ermesi", "Borçlu Temerrüdü"]
["Borcun İfası ve Sona Ermesi", "Alacaklı Temerrüdü"]
["Borcun İfası ve Sona Ermesi", "Zamanaşımı"]
["Özel Borç İlişkileri"]
["Özel Borç İlişkileri", "Satış Sözleşmesi"]
["Özel Borç İlişkileri", "Kira Sözleşmesi"]
["Özel Borç İlişkileri", "Eser Sözleşmesi"]
["Özel Borç İlişkileri", "Vekalet Sözleşmesi"]
["Özel Borç İlişkileri", "Hizmet Sözleşmesi"]
["Özel Borç İlişkileri", "Kefalet Sözleşmesi"]
```

### TICARET
```
["Ticari İşletme"]
["Ticari İşletme", "Ticari İşletme Kavramı"]
["Ticari İşletme", "Tacir"]
["Ticari İşletme", "Ticaret Unvanı"]
["Ticari İşletme", "Ticaret Sicili"]
["Ticari İşletme", "Haksız Rekabet"]
["Şirketler Hukuku"]
["Şirketler Hukuku", "Şirket Kavramı"]
["Şirketler Hukuku", "Adi Şirket"]
["Şirketler Hukuku", "Kollektif ve Komandit Şirket"]
["Şirketler Hukuku", "Anonim Şirket Organları"]
["Şirketler Hukuku", "Limited Şirket"]
["Kıymetli Evrak"]
["Kıymetli Evrak", "Kıymetli Evrak Temel Hükümler"]
["Kıymetli Evrak", "Poliçe"]
["Kıymetli Evrak", "Bono"]
["Kıymetli Evrak", "Çek"]
["9. Yargı Paketi (Ticari Uyuşmazlık Değişiklikleri)"]
["9. Yargı Paketi (Ticari Uyuşmazlık Değişiklikleri)", "Ticari Davalarda Zorunlu Arabuluculuk Kapsamı"]
```

### CEZA
```
["Ceza Hukukuna Giriş"]
["Ceza Hukukuna Giriş", "Ceza Hukukunun Temel İlkeleri"]
["Ceza Hukukuna Giriş", "Suçta ve Cezada Kanunilik"]
["Ceza Hukukuna Giriş", "Ceza Kanunlarının Uygulanması"]
["Suçun Genel Teorisi"]
["Suçun Genel Teorisi", "Maddi Unsur"]
["Suçun Genel Teorisi", "Manevi Unsur"]
["Suçun Genel Teorisi", "Hukuka Aykırılık"]
["Suçun Genel Teorisi", "Kusur"]
["Suçun Özel Görünüş Şekilleri"]
["Suçun Özel Görünüş Şekilleri", "Teşebbüs"]
["Suçun Özel Görünüş Şekilleri", "İştirak"]
["Suçun Özel Görünüş Şekilleri", "İçtima"]
["Yaptırımlar"]
["Yaptırımlar", "Cezalar"]
["Yaptırımlar", "Güvenlik Tedbirleri"]
["Özel Suçlar"]
["Özel Suçlar", "Hayata Karşı Suçlar"]
["Özel Suçlar", "Vücut Dokunulmazlığına Karşı Suçlar"]
["Özel Suçlar", "Malvarlığına Karşı Suçlar"]
["Özel Suçlar", "Kamu İdaresine Karşı Suçlar"]
["9. Yargı Paketi (TCK Değişiklikleri)"]
["9. Yargı Paketi (TCK Değişiklikleri)", "Uzlaştırma Kapsamında Değişiklikler"]
["9. Yargı Paketi (TCK Değişiklikleri)", "Cinsel Suçların Kapsamı"]
["9. Yargı Paketi (TCK Değişiklikleri)", "Etki Ajanlığı (Influence Agent)"]
```

### CMK
```
["Ceza Muhakemesine Giriş"]
["Ceza Muhakemesine Giriş", "CMK Temel İlkeleri"]
["Ceza Muhakemesine Giriş", "Yetki Kuralları"]
["Soruşturma"]
["Soruşturma", "Soruşturma Aşaması"]
["Soruşturma", "Gözaltı"]
["Soruşturma", "Tutuklama"]
["Soruşturma", "Adli Kontrol"]
["Deliller"]
["Deliller", "Arama ve Elkoyma"]
["Deliller", "İletişimin Denetlenmesi"]
["Deliller", "Delil Değerlendirmesi"]
["Kovuşturma"]
["Kovuşturma", "İddianame"]
["Kovuşturma", "Duruşma"]
["Kovuşturma", "Hüküm"]
["Kanun Yolları"]
["Kanun Yolları", "İtiraz"]
["Kanun Yolları", "İstinaf"]
["Kanun Yolları", "Temyiz"]
["9. Yargı Paketi (CMK Değişiklikleri)"]
["9. Yargı Paketi (CMK Değişiklikleri)", "Tutuklama Şartlarında Değişiklik"]
["9. Yargı Paketi (CMK Değişiklikleri)", "Dijital Delil Toplama Usulleri"]
```

### IDARE
```
["İdarenin Kuruluşu"]
["İdarenin Kuruluşu", "Merkezi İdare"]
["İdarenin Kuruluşu", "Yerinden Yönetim"]
["İdarenin Kuruluşu", "Kamu Tüzel Kişileri"]
["İdari İşlemler"]
["İdari İşlemler", "Düzenleyici İşlemler"]
["İdari İşlemler", "Bireysel İşlemler"]
["İdari İşlemler", "İdari İşlemin Unsurları"]
["Kamu Görevlileri"]
["Kamu Görevlileri", "Memur Kavramı"]
["Kamu Görevlileri", "Memurun Hakları"]
["Kamu Görevlileri", "Memurun Yükümlülükleri"]
["Kamu Görevlileri", "Disiplin"]
["Kolluk"]
["Kolluk", "Kolluk Kavramı"]
["Kolluk", "Kolluk Yetkileri"]
["Kamu Malları"]
["Kamu Malları", "Kamu Malı Kavramı"]
["Kamu Malları", "Kamulaştırma"]
["İdarenin Sorumluluğu"]
["İdarenin Sorumluluğu", "Hizmet Kusuru"]
["İdarenin Sorumluluğu", "Kusursuz Sorumluluk"]
```

### IYUK
```
["Dava Türleri"]
["Dava Türleri", "İptal Davası"]
["Dava Türleri", "Tam Yargı Davası"]
["Dava Şartları"]
["Dava Şartları", "Ehliyet"]
["Dava Şartları", "Hak Düşürücü Süreler"]
["Dava Şartları", "İdari Merci Tecavüzü"]
["Yargılama"]
["Yargılama", "Yürütmenin Durdurulması"]
["Yargılama", "Yargılama Aşamaları"]
["Yargılama", "Karar"]
["Kanun Yolları"]
["Kanun Yolları", "İstinaf"]
["Kanun Yolları", "Temyiz"]
["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)"]
["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)", "UYAP Düzenlemeleri"]
["9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)", "Arabuluculuk Kapsamının Genişletilmesi"]
```

### VERGI
```
["Vergi Hukuku Genel"]
["Vergi Hukuku Genel", "Vergi Kanunlarının Uygulanması"]
["Vergi Hukuku Genel", "Mükellefiyet"]
["Vergi Hukuku Genel", "Vergi Sorumluluğu"]
["Vergilendirme Süreci"]
["Vergilendirme Süreci", "Tarh"]
["Vergilendirme Süreci", "Tebliğ"]
["Vergilendirme Süreci", "Tahakkuk"]
["Vergilendirme Süreci", "Tahsil"]
["Vergi Borcunun Sona Ermesi"]
["Vergi Borcunun Sona Ermesi", "Ödeme"]
["Vergi Borcunun Sona Ermesi", "Zamanaşımı"]
["Vergi Borcunun Sona Ermesi", "Terkin"]
["Vergi Suç ve Cezaları"]
["Vergi Suç ve Cezaları", "Vergi Kabahatleri"]
["Vergi Suç ve Cezaları", "Vergi Suçları"]
["Vergi Uyuşmazlıkları"]
["Vergi Uyuşmazlıkları", "Uzlaşma"]
["Vergi Uyuşmazlıkları", "Vergi Davaları"]
```

### ICRA
```
["İcra Takip Yolları"]
["İcra Takip Yolları", "İlamsız Takip"]
["İcra Takip Yolları", "İlamlı Takip"]
["İcra Takip Yolları", "Kambiyo Senetlerine Özgü Takip"]
["İcra Takip Yolları", "Kiralanan Taşınmazların Tahliyesi"]
["Haciz"]
["Haciz", "Haciz İşlemi"]
["Haciz", "Haczi Caiz Olmayan Mallar"]
["Haciz", "İstihkak"]
["Rehnin Paraya Çevrilmesi"]
["Rehnin Paraya Çevrilmesi", "Taşınır Rehni"]
["Rehnin Paraya Çevrilmesi", "Taşınmaz Rehni"]
["İflas"]
["İflas", "İflas Sebepleri"]
["İflas", "İflas Tasfiyesi"]
["Konkordato"]
["Konkordato", "Konkordato Şartları"]
["Konkordato", "Konkordato Süreci"]
["9. Yargı Paketi (İİK Değişiklikleri)"]
["9. Yargı Paketi (İİK Değişiklikleri)", "Elektronik Satış Usulü"]
```

### IS
```
["Bireysel İş Hukuku"]
["Bireysel İş Hukuku", "İş Sözleşmesi Türleri"]
["Bireysel İş Hukuku", "Ücret"]
["Bireysel İş Hukuku", "Çalışma Süreleri"]
["Fesih"]
["Fesih", "Bildirimli Fesih"]
["Fesih", "Haklı Nedenle Fesih"]
["Fesih", "İş Güvencesi"]
["Tazminatlar"]
["Tazminatlar", "Kıdem Tazminatı"]
["Tazminatlar", "İhbar Tazminatı"]
["Sosyal Güvenlik"]
["Sosyal Güvenlik", "Sosyal Sigortalar"]
["Sosyal Güvenlik", "Emeklilik"]
["Toplu İş Hukuku"]
["Toplu İş Hukuku", "Sendika"]
["Toplu İş Hukuku", "Toplu İş Sözleşmesi"]
["Toplu İş Hukuku", "Grev"]
["9. Yargı Paketi (Arabuluculuk ve İş Hukuku Değişiklikleri)"]
["9. Yargı Paketi (Arabuluculuk ve İş Hukuku Değişiklikleri)", "Zorunlu Arabuluculukta Süre ve Usul"]
```

### AVUKATLIK
```
["Avukatlık Mesleğine Giriş"]
["Avukatlık Mesleğine Giriş", "Avukatlığa Kabul Şartları"]
["Avukatlık Mesleğine Giriş", "Staj Şartları"]
["Avukatlık Mesleğine Giriş", "Staj Süreci"]
["Avukatın Hak ve Yükümlülükleri"]
["Avukatın Hak ve Yükümlülükleri", "Avukatın Hakları"]
["Avukatın Hak ve Yükümlülükleri", "Avukatın Yükümlülükleri"]
["Avukatın Hak ve Yükümlülükleri", "Avukatlık Sözleşmesi"]
["Avukatın Hak ve Yükümlülükleri", "Avukatlık Ücreti"]
["Baro ve Disiplin"]
["Baro ve Disiplin", "Baro Teşkilatı"]
["Baro ve Disiplin", "Türkiye Barolar Birliği"]
["Baro ve Disiplin", "Disiplin İşlemleri"]
["9. Yargı Paketi (Avukatlık Mesleği Değişiklikleri)"]
["9. Yargı Paketi (Avukatlık Mesleği Değişiklikleri)", "Avukatların Arabuluculuk Faaliyetleri"]
```

### FELSEFE
```
["Hukuk Felsefesi"]
["Hukuk Felsefesi", "Doğal Hukuk"]
["Hukuk Felsefesi", "Hukuki Pozitivizm"]
["Hukuk Sosyolojisi"]
["Hukuk Sosyolojisi", "Hukuk ve Toplum İlişkisi"]
["Hukuk Sosyolojisi", "Hukukun İşlevleri"]
```

### MILLETLERARASI
```
["Devletler Genel Hukuku"]
["Devletler Genel Hukuku", "Uluslararası Hukuk Kaynakları"]
["Devletler Genel Hukuku", "Devlet ve Tanıma"]
["Devletler Genel Hukuku", "Uluslararası Örgütler"]
["Devletler Genel Hukuku", "Temel Anlaşmalar"]
```

### MOHUK
```
["MÖHUK Genel"]
["MÖHUK Genel", "Kanunlar İhtilafı"]
["MÖHUK Genel", "Uygulanacak Hukuk"]
["MÖHUK Genel", "Yabancılar Hukuku"]
["MÖHUK Genel", "Milletlerarası Usul Hukuku"]
```

---

## 📌 Diğer Alanlar

| Alan | Açıklama | Değerler |
|------|----------|----------|
| difficulty | Zorluk | 1=Kolay, 2=Orta, 3=Zor |
| exam_weight_tag | Sınav ağırlığı | core, supporting, longtail |
| target_roles | Hedef kitle | ["genel"], ["avukat"], ["hakim"], ["savci"], ["noter"] |
| status | Durum | approved, draft |

---

## ✅ ÖRNEK SORU

```json
{
  "id": "CEZA-001",
  "subject_code": "CEZA",
  "topic_path": ["Suçun Özel Görünüş Şekilleri", "Teşebbüs"],
  "difficulty": 2,
  "exam_weight_tag": "core",
  "target_roles": ["genel"],
  "stem": "TCK'ya göre, failin elinde olmayan nedenlerle icra hareketlerini tamamlayamaması halinde aşağıdakilerden hangisi söz konusu olur?",
  "options": [
    {"label": "A", "text": "Tam teşebbüs"},
    {"label": "B", "text": "Eksik teşebbüs"},
    {"label": "C", "text": "İşlenemez suç"},
    {"label": "D", "text": "Gönüllü vazgeçme"},
    {"label": "E", "text": "Etkin pişmanlık"}
  ],
  "correct_option": "B",
  "static_explanation": "İcra hareketlerinin tamamlanamaması 'eksik teşebbüs' olarak adlandırılır. TCK m.35'e göre teşebbüs, suçun icrasına elverişli hareketlerle doğrudan doğruya başlanıp da elde olmayan nedenlerle tamamlanamamasıdır.",
  "ai_hint": "İcra tamamlanamadıysa EKSİK, tamamlandı ama netice yok ise TAM teşebbüs.",
  "related_statute": "TCK m.35",
  "learning_objective": "Eksik ve tam teşebbüs ayrımını yapabilmek",
  "tags": ["teşebbüs", "eksik teşebbüs", "icra hareketleri"],
  "status": "approved"
}
```

---

## ⚠️ DİKKAT

1. **topic_path maksimum 2 eleman** olmalı
2. Konu adlarını **birebir** yukarıdaki listeden kopyala
3. **target_roles boş bırakma**, en az `["genel"]` yaz
4. **static_explanation mutlaka doldur** (öğretici olmalı)
5. **id formatı:** DERSKODU-001, DERSKODU-002 şeklinde sıralı
