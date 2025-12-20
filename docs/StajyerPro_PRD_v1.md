# 7.6 Gelişmiş İstatistik ve Bildirimler Teknik Yol Haritası

### Amaç:
Kullanıcı, konu bazlı başarı, hız, hata analizi ve güncel bildirimleri görebilir.

### Akış:
1. Kullanıcı istatistik ekranında, konu/ders bazlı başarı, hız, hata analizini görür.
2. API: `getAdvancedStats(userId)` çağrılır.
3. Backend, kullanıcıya ait istatistikleri (doğru/yanlış, süre, başarı oranı) döner.
4. Bildirimler için: `getNotifications(userId)` ile güncel sınav/mevzuat/duyuru alınır.
5. Kullanıcıya bildirim merkezi ve istatistik paneli sunulur.

### Teknik Gereksinimler:
- Stat modeli: userId, subjectId, topicId, correctCount, wrongCount, avgDuration
- Notification modeli: id, userId, type, title, content, createdAt, read
- Backend’de istatistik ve bildirim yönetimi.
- UI’da istatistik paneli, grafikler, bildirim merkezi.

### UI Gereksinimleri:
- Konu/ders bazlı başarı ve hız grafikleri.
- Hata ve eksik analiz tablosu.
- Bildirim merkezi ve okundu/okunmadı durumu.
# 7.5 Sınav Simülasyonu ve Zaman Yönetimi Teknik Yol Haritası

### Amaç:
Kullanıcı, gerçek sınav formatında süreli deneme çözebilir ve zaman yönetimi analizini görebilir.

### Akış:
1. Kullanıcı “Deneme Sınavı” başlatır, sınav tipi ve süre seçer.
2. API: `getExamSimulation({userId, examType})` çağrılır.
3. Sistem, ilgili formatta soruları rastgele seçer ve sınavı başlatır.
4. Sınav sırasında kalan süre ve her soruya harcanan süre izlenir.
5. Sınav sonunda, toplam süre, her soruya harcanan süre, doğru/yanlış/boş analizi yapılır.
6. Kullanıcıya sonuç ekranında zaman yönetimi raporu ve konu bazlı analiz sunulur.

### Teknik Gereksinimler:
- Exam modeli: id, userId, type, questionIds[], startedAt, finishedAt, duration, score, perQuestionDuration[]
- Backend’de sınav formatı ve süre yönetimi.
- UI’da süreli sınav ekranı, kalan süre göstergesi, sonuç ve zaman yönetimi raporu.

### UI Gereksinimleri:
- Sınav başlatma ekranı (tip ve süre seçimi).
- Süreli sınav çözüm ekranı (kronometre, kalan süre).
- Sonuç ve zaman yönetimi raporu ekranı.
# 7.4 Kişiselleştirilmiş Analiz ve Çalışma Planı Teknik Yol Haritası

### Amaç:
Kullanıcının test/deneme sonuçlarına göre zayıf olduğu konuların otomatik analiz edilip, kişiye özel çalışma planı önerilmesi.

### Akış:
1. Kullanıcı test/deneme çözdükçe, sonuçlar backend’de analiz edilir.
2. Her konu için doğru/yanlış oranı, son çözüm zamanı, toplam soru sayısı gibi istatistikler tutulur.
3. API: `getPersonalizedAnalysis(userId)` çağrılır.
4. Sistem, doğru/yanlış oranı düşük ve uzun süredir çalışılmayan konuları tespit eder.
5. Bu konular için otomatik çalışma planı (tarih, öneri notu) oluşturulur.
6. Kullanıcıya analiz ekranında zayıf konular ve öneri planı gösterilir.

### Teknik Gereksinimler:
- UserStats modeli: userId, subjectId, topicId, correctCount, wrongCount, lastTestedAt
- Plan modeli: userId, topicId, recommendedDate, note
- Analiz algoritması backend’de çalışır, admin tarafından güncellenebilir.
- UI’da analiz ve öneri planı ekranı.

### UI Gereksinimleri:
- Analiz ekranında konu bazlı başarı grafiği.
- Zayıf konular ve öneri planı listesi.
# 7.3 Yanlış Soruda AI/Uzman Açıklaması Teknik Yol Haritası

### Amaç:
Kullanıcı yanlış cevap verdiğinde, AI veya uzman tarafından hazırlanmış kısa açıklama ve özetle hatasını anında kavrar.

### Akış:
1. Kullanıcı bir soruya yanlış cevap verdiğinde, doğru şık ve açıklama paneli açılır.
2. Önce ilgili sorunun `detailedExplanation` alanı kontrol edilir.
3. Eğer doluysa, bu açıklama gösterilir.
4. Eğer boşsa, AI servisine (ör. Gemini, OpenAI) prompt ile soru, şıklar ve doğru cevap gönderilir.
5. AI, kısa ve öğretici bir açıklama üretir (ör: “Bu şık yanlıştır çünkü ...”, “Doğru cevap ... çünkü ...” gibi).
6. Üretilen açıklama kullanıcıya gösterilir ve Firestore’daki ilgili sorunun `detailedExplanation` alanına kaydedilir (caching).

### Teknik Gereksinimler:
- Soru veri modelinde `detailedExplanation` (String, opsiyonel) alanı olmalı.
- AI servisine prompt formatı: Soru metni + şıklar + doğru cevap + “Kısa, öğretici açıklama üret.”
- Firestore veya backend’de açıklama cache’lenmeli.
- UI’da yanlış cevap sonrası modal veya alt panelde açıklama gösterilmeli.

### UI Gereksinimleri:
- Yanlış cevap sonrası belirgin açıklama paneli/modalı.
- Açıklama yoksa, “Açıklama hazırlanıyor...” veya “AI açıklaması üretilemedi” mesajı.
# 7.2 AI İpucu Baloncuğu Teknik Yol Haritası

### Amaç:
Kullanıcı soru çözüm ekranında, AI tarafından üretilen kısa, pratik ipucu veya ezber baloncuğuna tıklayarak anında destek alır.

### Akış:
1. Soru çözüm ekranında, her sorunun yanında “İpucu” baloncuğu/ikonu görünür.
2. Kullanıcı baloncuğa tıkladığında, önce ilgili sorunun `aiTip` alanı kontrol edilir.
3. Eğer `aiTip` alanı doluysa, doğrudan bu metin gösterilir.
4. Eğer boşsa, sistem AI servisine (ör. Gemini, OpenAI) prompt ile sorunun metni ve şıkları gönderir.
5. AI, kısa ve pratik bir ipucu üretir (ör: “Bu tip sorularda anahtar kelimeye dikkat et”, “Tanım sorusu, genellikle ... ile başlar” gibi).
6. Üretilen ipucu, kullanıcıya gösterilir ve Firestore’daki ilgili sorunun `aiTip` alanına kaydedilir (caching).

### Teknik Gereksinimler:
- Soru veri modelinde `aiTip` (String, opsiyonel) alanı olmalı.
- AI servisine prompt formatı: Soru metni + şıklar + “Kısa, pratik, ezber ipucu üret.”
- Firestore veya backend’de ipucu cache’lenmeli.
- UI’da baloncuk/tooltip, tıklanınca açılır ve ipucu gösterilir.
- Kullanıcı başına günlük/aylık ipucu limiti (Free/Pro için farklı olabilir).

### UI Gereksinimleri:
- Soru çözüm ekranında belirgin bir “İpucu” baloncuğu/ikonu.
- Tıklanınca açılan tooltip/modalda ipucu metni.
- Hata/limit durumunda uygun uyarı mesajı.
# 7. Teknik Yol Haritası ve Gereksinimler

## 7.1 Konu Bazlı Rastgele Test Akışı
### Akış:
- Kullanıcı, ana ekrandan “Test Başlat” veya “Konu Seç” butonuna tıklar.
- Açılan listeden ders ve/veya alt konu seçer.
- Soru sayısı (10/20/40/sınırsız) seçilir.
- API: `getFastTestQuestions({subjectId, topicId, count})` çağrılır.
- Firestore’dan ilgili konuya ait sorular rastgele çekilir.
- Test başlar, her soru için çözüm ekranı açılır.
### Veri Modeli:
- Soru: id, subjectId, topicId, text, options[], correctOption, detailedExplanation, aiTip
- Test: id, userId, subjectId, topicId, questionIds[], startedAt, finishedAt, duration, score
### UI:
- Konu/ders seçici dropdown, soru sayısı seçici, test ekranı, sonuç ekranı.

## 7.2 AI İpucu Baloncuğu
### Akış:
- Soru çözüm ekranında “İpucu” baloncuğu/ikonu görünür.
- Kullanıcı tıklayınca, ilgili sorunun `aiTip` alanı gösterilir.
- Eğer yoksa, AI servisine prompt ile soru ve şıklar gönderilir, kısa pratik ipucu döner.
### Veri Modeli:
- Soru: aiTip (String, opsiyonel)
### UI:
- Soru ekranında baloncuk/tooltip, tıklanınca açılır.

## 7.3 Yanlış Soruda AI/Uzman Açıklaması
### Akış:
- Kullanıcı yanlış cevap verirse, doğru şık ve `detailedExplanation` gösterilir.
- Eğer açıklama yoksa, AI servisine prompt ile detaylı açıklama istenir.
### Veri Modeli:
- Soru: detailedExplanation (String, opsiyonel)
### UI:
- Yanlış cevap sonrası modal veya alt panelde açıklama.

## 7.4 Kişiselleştirilmiş Analiz ve Çalışma Planı
### Akış:
- Kullanıcının tüm test/deneme sonuçları analiz edilir.
- Zayıf olunan konular belirlenir (doğru/yanlış oranı düşük olanlar).
- API: `getPersonalizedAnalysis(userId)` çağrılır.
- Sistem, eksik konulara göre otomatik çalışma planı önerir.
### Veri Modeli:
- UserStats: userId, subjectId, topicId, correctCount, wrongCount, lastTestedAt
- Plan: userId, topicId, recommendedDate, note
### UI:
- Analiz ekranı, öneri listesi, çalışma planı takvimi.

## 7.5 Sınav Simülasyonu ve Zaman Yönetimi
### Akış:
- Kullanıcı “Deneme Sınavı” başlatır, sınav tipi ve süre seçer.
- API: `getExamSimulation({userId, examType})` çağrılır.
- Sınav başlar, süreli ve gerçek formatta sorular gelir.
- Sınav sonunda, toplam süre, her soruya harcanan süre, doğru/yanlış/boş analizi yapılır.
### Veri Modeli:
- Exam: id, userId, type, questionIds[], startedAt, finishedAt, duration, score, perQuestionDuration[]
### UI:
- Sınav başlatma ekranı, süreli sınav ekranı, sonuç ve zaman yönetimi raporu.

## 7.6 Gelişmiş İstatistik ve Bildirimler
### Akış:
- Kullanıcı, istatistik ekranında konu bazlı başarı, hız, hata analizini görür.
- API: `getAdvancedStats(userId)` çağrılır.
- Bildirimler için: `getNotifications(userId)` ile güncel sınav/mevzuat/duyuru alınır.
### Veri Modeli:
- Stat: userId, subjectId, topicId, correctCount, wrongCount, avgDuration
- Notification: id, userId, type, title, content, createdAt, read
### UI:
- İstatistik paneli, grafikler, bildirim merkezi.
# StajyerPro – Hukuk Mesleklerine Giriş Sınavı (HMGS) Hazırlık Uygulaması  
**Product Requirements Document (PRD)**  
**Version:** 1.0  
**Owner:** Product & Engineering  
**Platform:** Flutter (Android / iOS), Firestore backend, Gemini 2.5 tabanlı AI servisleri  

---

## 1. Executive Summary

StajyerPro, Türkiye’de **Hukuk Mesleklerine Giriş Sınavı (HMGS)**’na hazırlanan hukuk fakültesi öğrencileri ve mezunları için tasarlanmış, **AI destekli sınav koçu** mobil uygulamasıdır.  

Uygulama, kullanıcıya:  

- HMGS’nin resmi konu başlıklarına göre yapılandırılmış **soru bankası**,  
- Gerçek sınav formatına yakın **deneme sınavları**,  
- AI destekli **soru çözüm açıklamaları**,  
- Kişiselleştirilmiş **çalışma planları** ve  
 - HMGS’nin resmi konu başlıklarına göre yapılandırılmış **soru bankası**
 - **Konu bazlı rastgele soru çözümü** (kullanıcı seçtiği konuda hızlı test başlatabilir)
 - Soru çözüm ekranında **AI destekli ipucu baloncuğu** (pratik, ezber, püf noktası)
 - Yanlış yapılan sorularda **AI/uzman açıklaması** ve kısa özet
 - Zayıf alan analizine göre uyarlanan **kişiselleştirilmiş öğrenme yolları**
 - **Kişiselleştirilmiş analiz ve çalışma planı** (eksik konulara göre otomatik öneri)
 - **Sınav simülasyonu ve zaman yönetimi** (gerçek sınav formatında, süreli deneme)
 - **Gelişmiş istatistikler ve raporlama** (konu bazlı başarı, hız, hata analizi)
 - **Güncel içerik ve bildirimler** (sınav takvimi, mevzuat değişikliği, yeni paketler)
- **Free (reklamlı, limitli)**: Günde belirli sayıda soru/AI etkileşimi, aylık limitli deneme, reklam gösterimi.  
- **Pro (haftalık / yıllık abonelik)**: Sınırsız soru ve analiz, reklamsız deneyim, gelişmiş AI koçluk, tüm istatistik ve planlama özellikleri.  
- **Ek gelir:** Deneme sınavlarının **ayrı paketler** hâlinde satışı (bundle).  

---


HMGS, avukatlık stajı, noterlik stajı ve hâkim/savcı yardımcılığı sınavına giden yolda zorunlu bir ön eleme sınavıdır.  
Mevcut durumda:

- Hazırlık süreci **parçalı**: PDF notlar, kurs dokümanları, dağınık online testler.  
 - **Pro (haftalık / yıllık abonelik)**: Sınırsız soru ve analiz, reklamsız deneyim, gelişmiş AI koçluk, tüm istatistik ve planlama özellikleri, konu bazlı rastgele test, AI ipucu baloncuğu, sınav simülasyonu, kişiselleştirilmiş analiz ve bildirimler.  
- HMGS’ye özel, mobil odaklı, **tam kapsamlı** bir uygulama yok.  
- Öğrenciler kendi zayıf alanlarını sistematik olarak göremiyor; ne kadar çalışsalar da “barajı geçecek miyim?” sorusuna net yanıt alamıyorlar.  
- Soru bankaları çoğunlukla statik; değişen kanun ve yönetmeliklere göre **dinamik güncelleme** zayıf.  


> “Kullanıcıya HMGS için **tamamen dijital bir çalışma ekosistemi** sunmak ve AI destekli analizle 70 barajını geçme olasılığını belirgin şekilde artırmak.”
 - Konu bazlı **test modu** (hızlı/rastgele soru çözme, AI ipucu baloncuğu ile destekli)  

- HMGS müfredatına tam uyumlu, güncel, kategorize bir **soru bankası** sağlamak,  
- Kullanıcının performansını sürekli izleyerek **konu bazlı zayıf noktalarını** çıkarmak,  
- AI kullanarak her cevap sonrası anlamlı **öğretici açıklama** ve ipuçları sunmak,  
- Mobil deneyimi hızlı, modern, reklamsız (pro’da) ve motive edici bir yapıda sunmak.  
### 2.3. Başarı Kriterleri (Success Metrics)

 - **Sonuç analizi:** Gelişmiş istatistik, konu bazlı başarı, hız, hata ve eksik analizleri, kişiselleştirilmiş çalışma planı önerileri, sınav simülasyonu sonrası zaman yönetimi raporu, güncel bildirimler.
- Kullanıcı memnuniyeti (store rating) ≥ 4.5  

**Orta vade (1 yıl):**

  - **Barajı geçme oranında +%15 artış**  
- Churn (Pro’dan düşüş) < %8 / ay  

---

 - Kullanıcının performansını sürekli izleyerek **konu bazlı zayıf noktalarını** çıkarmak,  
 - AI kullanarak her cevap sonrası anlamlı **öğretici açıklama**, ipucu baloncuğu ve pratik öneriler sunmak, yanlış sorularda kısa özet ve püf noktası göstermek,  
- 3. veya 4. sınıf hukuk öğrencisi veya yeni mezun  
- Öncelikli hedef: **Avukatlık stajına başlamak** / **Hakimlik sınavına girmek**  
- Zamanı kısıtlı, dershaneye gitse bile mobil destek istiyor  
- Motivasyonu: Tek seferde barajı geçmek, en az yorucu ama verimli çalışma planı  

### 3.2. İkincil Persona – “Tekrar Deneyen”

- Daha önce HMGS’ye girip 70 barajını geçememiş  
- Nerede hata yaptığını bilmiyor  
- Öncelikli ihtiyacı: **zayıf konularını görme**, hangi alanda eksik olduğunu netleştirme  

### 3.3. Üçüncül Persona – “Uzun Vadeli Planlayan”

- 2. sınıf sonu / 3. sınıf başı öğrencisi  
- HMGS’yi **2 yıl sonrasına** hedefliyor  
- Yavaş ama planlı çalışmak istiyor  
- Yıllık abonelik hedef kitlesi  

---

## 4. Ürün Kapsamı (Scope)

### 4.1. Dahil Olanlar

- HMGS resmi konu başlıklarına uygun **ders/konu modülleri**  
- Konu bazlı **test modu** (hızlı soru çözme)  
- Gerçek sınav formatına yakın **deneme sınavları**  
- **Sonuç analizi:**  
  - Ders / alt konu bazlı netler  
  - HMGS baraj simülasyonu  
- AI tabanlı:  
  - Soru çözüm açıklamaları  
  - Yanlış cevaplara göre **mini ders anlatımı**  
  - Kişiselleştirilmiş çalışma planı üretimi  
  - Soru önerisi (weak area drilling)  
- Kullanıcı profil ve istatistik ekranları  
- Free / Pro erişim seviyeleri  
- Deneme paketlerinin ayrıca satışı  

### 4.2. Kapsam Dışı (V1 için)

- Yurt dışı hukuk sınavları (bar exam vb.)  
- Tam kapsamlı Hakimlik / Savcılık / İYÖS sınav modülleri (ileriki faz)  
- Web (browser) arayüzü (isteğe bağlı V2)  
- Kullanıcılar arası sosyal etkileşim (forum, chat)  

---

## 5. HMGS – Alan Özeti (Ürün Tasarımına Etkisi)

> PRD içinde kısa hatırlatma: Bu bölüm ürünün “sınav gerçekleri” ile uyumunu sağlar.

### 5.1. Sınavın Temel Özellikleri

- Organizatör: ÖSYM (Adalet Bakanlığı protokolü ile)  
- Format: Çoktan seçmeli test  
- Soru sayısı: **Kanunen en az 100**, pratikte 120 soru (2024–2025 uygulamaları)  
- Süre: ~130–155 dakika aralığında tek oturum  
- Değerlendirme: 100 tam puan üzerinden, baraj 70  
- İçerik:  
  - Medeni, Borçlar, Ticaret, Ceza, İdare, HMK, CMK, İcra-İflas, İş, Vergi, Avukatlık Hukuku, Hukuk Felsefesi, Türk Hukuk Tarihi, Milletlerarası / Milletlerarası Özel  

### 5.2. Konu Ağırlıkları (Örnek Dağılım Mantığı)

Uygulama içinde her ders için soru ağırlıkları **config** üzerinden yönetilecek; tipik ağırlık mantığı:

- Medeni Hukuk ≈ %10–12  
- Borçlar Hukuku ≈ %8–10  
- Ticaret Hukuku ≈ %8–10  
- Hukuk Yargılama Usulü (HMK) ≈ %8–10  
- Ceza Hukuku & CMK ≈ %10–12 toplam  
- İdare & İYUK ≈ %8–10  
- İş Hukuku, Sosyal Güvenlik, İcra-İflas, Vergi + VUK ≈ %4–7’lik dilimler  
- Avukatlık Hukuku, Hukuk Felsefesi, Türk Hukuk Tarihi, Milletlerarası / Özel ≈ düşük ama ihmal edilemeyecek ağırlıklar  

Bu dağılım **admin panelinden değiştirilebilir** olmalı, çünkü ÖSYM ileride oranlarda oynama yapabilir.

---

## 6. Ürün Özellikleri (Functional Requirements)

### 6.1. Kimlik Doğrulama ve Profil

**FR-01 – Kayıt / Giriş**  
- Kullanıcı e-posta + şifre veya Google ile kayıt olur/giriş yapar.  
- Firestore Authentication kullanılacak.  

**FR-02 – Profil Ayarları**  
- Hedef rol: Avukatlık / Hakimlik / Savcılık / Noterlik (çoklu seçilebilir).  
- Sınava giriş hedef tarihi: (tarih seçimi).  
- Çalışma yoğunluğu tercihi:  
  - Hafif (günlük 20–30 soru)  
  - Orta (günlük 40–60 soru)  
  - Yoğun (günlük 80+ soru)  

Bu bilgiler AI çalışma planı için input olarak kullanılacak.

---

### 6.2. Ders / Konu Modülleri

**FR-03 – Ders Listesi**  
- HMGS resmi konularına göre ana ders listesi:  
  - Anayasa Hukuku  
  - İdare Hukuku & İYUK  
  - Medeni Hukuk  
  - Borçlar Hukuku  
  - Ticaret Hukuku  
  - Hukuk Yargılama Usulü (HMK)  
  - Ceza Hukuku & CMK  
  - İcra ve İflas Hukuku  
  - İş ve Sosyal Güvenlik Hukuku  
  - Vergi Hukuku & VUK  
  - Avukatlık Hukuku  
  - Hukuk Felsefesi ve Sosyolojisi  
  - Türk Hukuk Tarihi  
  - Milletlerarası Hukuk  
  - Milletlerarası Özel Hukuk  

**FR-04 – Alt Konular (Topic Tree)**  
- Her ders kendi içinde alt konulara bölünecek (örneğin Medeni Hukuk → Başlangıç Hükümleri, Kişiler Hukuku, Aile Hukuku, Miras Hukuku vb.).  
- Bu ağaç yapısı Firestore’da konfigüre edilebilir olacak.  

---

### 6.3. Test Modu (Konu Bazlı Soru Çözme)

**FR-05 – Hızlı Test (Quick Quiz)**  
- Kullanıcı bir ders veya alt konu seçer.  
- Soru sayısı seçebilir: 10 / 20 / 40 / “sınırsız mod” (Pro için).  
- Sorular Firestore soru bankasından rastgele (veya zorluk/etiket filtresiyle) çekilir.  

**FR-06 – Soru Türü**  
- V1’de tamamen **çoktan seçmeli (4–5 seçenekli)**.  
- V2’de “Maddeyi işaretle” / “Doğru–Yanlış” varyasyonları eklenebilir.  

**FR-07 – Çözüm Sonrası Geri Bildirim**  
- Kullanıcı cevabı işaretledikten sonra:  
  - Doğru/yanlış gösterilir.  
  - Doğru cevap ve kısa statik açıklama gösterilir.  
  - Pro kullanıcıları için “Detaylı AI Açıklaması” butonu aktif:  
    - AI, ilgili kanun maddesine referans vererek çözüme giden yolu açıklar.  
    - Kullanıcının seçtiği yanlış şıkkın neden yanlış olduğunu yorumlar.  

---

### 6.4. Deneme Sınavı Modu

**FR-08 – HMGS Full Deneme**  
- Gerçek sınav formatına mümkün olduğunca yakın:  
  - Örn. 120 soru, 130–155 dk.  
- Ders bazlı soru sayıları admin paneli / config dosyasından yönetilebilir.  

**FR-09 – Deneme Sonuç Analizi**  
- Toplam doğru, yanlış, boş, net  
- 100 üzerinden puan hesabı  
- 70 barajını geçip geçmediği bilgisinin gösterimi  
- Ders bazlı net tablosu (bar chart + list)  
- “Zayıf dersler” listesi (toplam soru içinde % doğru düşük olan alanlar)  

**FR-10 – Deneme Türleri**  
- Ücretsiz kullanıcıya:  
  - Aylık 1 ücretsiz deneme (veya onboarding’de 1 deneme).  
- Pro kullanıcıya:  
  - Sınırsız deneme çözme hakkı (veya aylık yüksek limit: örn. 30).  
- **Ayrı satılan paketler:**  
  - “Profesyonel Deneme Paketi 5’li / 10’lu” – satın alınan denemeler, Pro olunsa da olmasa da ekstra hak olarak tanımlanır.  

---

### 6.5. AI Koçluk (Law Coach)

**FR-11 – Soru Çözüm Koçu**  
- Kullanıcı, çözdüğü bir soru için “AI’den detaylı açıklama iste” butonuna basar.  
- AI:  
  - Soruyu ve şıkları analiz eder.  
  - Doğru cevabın dayandığı hükmü, mantığı, tipik tuzağı anlatır.  
  - Kullanıcının seçtiği şık üzerinden geri bildirim verir.  

**FR-12 – Serbest Hukuk Sorusu (Chat)**  
- Kullanıcı, HMGS kapsamındaki dersler hakkında soru sorabilir (konu açıklaması, kavram farkı, madde mantığı vb.).  
- AI, kesin hukuki danışmanlık vermeden, “öğretici” formatta cevaplar.  
- Free: günlük mesaj limiti (örneğin 5 soru/gün).  
- Pro: pratikte sınırsız veya yüksek limit.  

**FR-13 – Çalışma Planı Oluşturucu**  
- Kullanıcı hedef tarih + günlük çalışma süresini belirtir (veya onboarding’de alınır).  
- AI, HMGS konu dağılımı ve kullanıcının zayıf alan bilgisine göre:  
  - 30 / 60 / 90 günlük çalışma planı oluşturur.  
  - Her gün için: “x soru Medeni, y soru Ceza, z dk tekrar” gibi görevler listeler.  

---

### 6.6. Analitik ve İstatistikler

**FR-14 – İlerleme Ekranı**  
- Günlük/haftalık çözülen soru sayısı (line chart).  
- Ders bazlı başarı yüzdeleri.  
- Son 5 deneme puan grafiği.  

**FR-15 – Zayıf Konular Listesi**  
- Firestore’da user-progress dokümanlarından türeyen:  
  - En düşük doğru oranına sahip 3–5 ders  
  - Her ders için en problemli alt konular  
- “Bu zayıf konulara göre önerilen quiz başlat” butonu.  

---

### 6.7. Bildirimler

**FR-16 – Hatırlatıcı Bildirimler**  
- Çalışma planına göre:  
  - Günlük “Bugünkü hedefin: 40 soru – Hazır mısın?”  
- HMGS tarihine yaklaştıkça:  
  - “Sınava X gün kaldı: Bugün mutlaka deneme çöz.”  

---

### 6.8. Monetization ve Erişim Seviyeleri

**FR-17 – Free Plan (Reklamlı)**  
- Günlük soru çözme limiti (örneğin 40 soru).  
- Daily AI açıklama limiti (örneğin 3–5 istekte bulunabilir).  
- Aylık 1–2 deneme sınavı.  
- Ekranların belirli yerlerinde banner reklamlar (AdMob / benzeri).  

**FR-18 – Pro Plan**  
- Haftalık abonelik (ör. 129 TL)  
- Yıllık abonelik (ör. 999 TL)  
- Özellikler:  
  - Soru çözme limiti çok yüksek veya fiilen sınırsız (sistem ölçeğine göre limit).  
  - AI koçluk mesajları için yüksek limit (örneğin 200/gün)  
  - Reklamsız deneyim  
  - Gelişmiş analitik (detaylı grafikler, uzun dönem trend)  
  - Çalışma planlarını sınırsız güncelleme  

**FR-19 – Deneme Sınavı Paketleri**  
- 5’li, 10’lu ve “Pro Premium pack” gibi paketler.  
- Satın alınan paketler:  
  - Kullanıcı planından bağımsız olarak, Firestore’da “extra_exam_credits” alanına yazılır.  

---

## 7. AI Mimarisi ve Kullanım Kuralları

### 7.1. Kullanılacak Modeller

- Metin tabanlı açıklamalar, çalışma planı, koçluk için:  
  - **Gemini 2.5 Flash (veya benzeri hızlı, düşük maliyetli model)**  
- Gelecekte:  
  - Mevzuat/güncel değişiklik takibi için arka planda batch işlemler (cron).  

### 7.2. AI Kullanım Senaryoları

1. **Soru Açıklama Üretimi:**  
   - Prompta soru metni, şıklar, doğru cevap, kullanıcının cevabı, konu başlığı verilecek.  
   - Modelden beklenen:  
     - Kısa özet + sonra adım adım mantık + madde numarası / ilgili kurum.  

2. **Çalışma Planı:**  
   - Input:  
     - Kullanıcının hedef sınav tarihi, güncel başarı istatistikleri, günlük çalışma süresi.  
   - Output:  
     - Gün-gün veya hafta-hafta görev listesi, “yüksek öncelikli konular” etiketi.  

3. **Serbest Koçluk Chat’i:**  
   - Guardrail:  
     - Hukuki danışmanlık yerine “sınav odaklı açıklama” vermesi istenir.  
     - Belirli uyarı mesajları sabit promptta yer alır.  

### 7.3. AI Rate Limiting

- Kullanıcı başına günlük limit:  
  - Free: örn. 20 AI isteği  
  - Pro: örn. 200 AI isteği  
- Sunucu tarafında basit rate-limit mekanizması:  
  - Firestore’da günlük usage counter alanları.  

---

## 8. Teknik Mimarî – Firestore + Flutter

### 8.1. Genel Mimari

- **Client:** Flutter (Android öncelikli, iOS opsiyonel)  
- **Backend:**  
  - Firestore (NoSQL) – soru bankası, kullanıcı verisi, istatistikler  
  - Firebase Auth – kimlik doğrulama  
  - Cloud Functions – AI çağrıları, skor hesaplama, ödeme web-hook’ları  
  - Storage – büyük boyutlu dosyalar (ileride PDF, video vs.)  

### 8.2. Firestore Şema Taslağı

> Not: Bu sadece örnek; gerçek projede koleksiyon isimleri ve alanlar revize edilebilir.

```text
users (collection)
  uid (doc)
    email
    name
    target_roles: [ "avukat", "hakimlik" ]
    exam_target_date
    study_intensity
    plan_type: "free" | "pro"
    created_at
    updated_at

subscriptions (collection)
  subscription_id (doc)
    user_id
    type: "weekly" | "yearly"
    status: "active" | "canceled" | "expired"
    start_date
    end_date
    platform: "google_play" | "ios" | "manual"

exam_credits (collection)
  credit_id (doc)
    user_id
    total_credits
    used_credits

subjects (collection)
  subject_id (doc)
    name: "Medeni Hukuk"
    code: "MED"
    weight_percent
    order_index

topics (collection)
  topic_id (doc)
    subject_id
    name
    code
    parent_topic_id (nullable)
    order_index

questions (collection)
  question_id (doc)
    subject_id
    topic_ids: [topic_id]
    difficulty: 1 | 2 | 3
    stem: "..."
    options: [ "A şıkkı", "B şıkkı", ... ]
    correct_index: 0..3
    explanation_static: "Kısa açıklama..."
    source_type: "human" | "ai_reviewed"
    created_at
    updated_at
    is_active: true

exams (collection)
  exam_id (doc)
    name: "HMGS Deneme 1"
    type: "full" | "mini"
    duration_minutes
    question_ids: [ ... ]
    created_at
    updated_at

exam_attempts (collection)
  attempt_id (doc)
    exam_id
    user_id
    started_at
    finished_at
    answers: [
      { question_id, selected_index, is_correct }
    ]
    score_raw
    score_scaled_100
    passed_bar: true/false

daily_stats (collection)
  stats_id (doc)
    user_id
    date (YYYY-MM-DD)
    questions_solved
    correct_count
    ai_requests
    study_minutes

ai_sessions (collection)
  session_id (doc)
    user_id
    type: "explanation" | "chat" | "study_plan"
    input_metadata
    token_usage
    created_at
```

---

## 9. Flutter Uygulama Yapısı

### 9.1. Ana Ekranlar

1. **Splash / Onboarding**  
2. **Auth Ekranı** (giriş / kayıt / Google sign-in)  
3. **Ana Dashboard**  
   - Günlük hedef  
   - Hızlı başlat (Quiz / Deneme / Koçluk)  
   - Kısa istatistik widget’ları  
4. **Ders Listesi Ekranı**  
   - Medeni, Borçlar, Ceza, vb.  
5. **Konu Detay & Test Başlat Ekranı**  
6. **Quiz Ekranı** (soru çözüm akışı)  
7. **Deneme Sınavı Ekranı**  
8. **Sonuç & Analiz Ekranı**  
9. **AI Koç Ekranı (Chat UI)**  
10. **Çalışma Planı Ekranı**  
11. **Profil & Ayarlar**  
12. **Pro / Abonelik Ekranı** (paywall)  
13. **Deneme Mağazası Ekranı** (paket satın alma)  

### 9.2. State Yönetimi

- Önerilen: **Riverpod** veya Bloc (projede Riverpod kullanımı basit ve güçlü).  
- Ana state domain’leri:  
  - AuthState  
  - UserProfileState  
  - QuestionsState (quiz)  
  - ExamsState  
  - AnalyticsState  
  - SubscriptionState  
  - AiCoachState  

---

## 10. Non-Functional Requirements

- **Performans:**  
  - Bir quiz oturumu için soru yüklenmesi ≤ 2 sn (10–20 soru).  
- **Güvenlik:**  
  - Firestore security rules: kullanıcı sadece kendi verisini okuyup yazabilmeli.  
  - AI loglarında kişisel veri tutulmamalı, sadece teknik metadatayı sakla.  
- **Güncellik:**  
  - Mevzuat değişikliği olduğunda admin panel üzerinden konu işaretleri ve açıklamalar güncellenebilmeli.  
- **Kullanılabilirlik:**  
  - 2025 trendine uygun sade, koyu/açık tema desteği.  
- **Esneklik:**  
  - HMGS formatı değiştiğinde (soru sayısı, süre, ders dağılımı) config ile hızlı adaptasyon.  

---

## 11. Riskler ve Mitigasyon

### 11.1. Hukuki Riskler

- AI yanıtlarının “hukuki danışmanlık” gibi algılanması:  
  - Önleyici: Kullanım koşullarında ve uygulama içi uyarılarda “sınav hazırlık koçu” olduğu, hukuki danışmanlık olmadığı açıkça belirtilmeli.  
  - Prompt’larda model, kesin görüş yerine “öğrenme amaçlı açıklama” verecek şekilde kısıtlanmalı.  

- Mevzuat değişiklikleri:  
  - Önleyici: HMGS kapsamındaki temel kanunların değişikliklerini düzenli takip edecek bir süreç belirlenmeli (ör. 3 ayda bir revizyon).  

### 11.2. Teknik Riskler

- Firestore maliyetlerinin artması:  
  - Çözüm: Sınav ve soru istatistiklerini özetleyen dokümanlarla okuma sayısını azaltmak.  
- AI API maliyetleri:  
  - Çözüm:  
    - Free plan limitlerini sıkı tutmak.  
    - Bazı açıklamaları statik/önceden oluşturulmuş hâle getirmek (cache).  

### 11.3. Ürün Riskleri

- Kullanıcıların HMGS zorluk seviyesini hafife alması / app’i “hafif test uygulaması” zannetmesi:  
  - Çözüm: Branding ve onboarding’de “ciddi sınav koçu” vurgusu, içerik yoğunluğunun gösterilmesi.  

---

## 12. Yol Haritası (Roadmap)

### Faz 1 – MVP (4–6 Hafta)

- Auth + Profil  
- Ders/kategori sistemi  
- Soru bankası temel şeması  
- Konu bazlı test modu  
- Basit sonuç ekranları  
- Free / Pro mantığı (minimum)  
- AI: sadece soru açıklama modülü  

### Faz 2 – Deneme & İstatistik (4 Hafta)

- Full HMGS deneme modülü  
- Deneme sonuç analizi  
- Temel grafikler (line/bar chart)  
- AI çalışma planı üreticisi  

### Faz 3 – Koçluk & Monetization Derinleştirme (4–8 Hafta)

- Serbest koçluk chat’i  
- Deneme paketleri store’u  
- Bildirim ve hatırlatıcı sistemi  
- Gelişmiş istatistikler & “weak topic drill” özelliği  

### Faz 4 – Genişleme (Opsiyonel)

- İdari Yargı Ön Sınavı (İYÖS) modu  
- Web arayüzü  
- Video / sesli mini ders içerikleri  

---

## 13. Toplanması Gereken Hukuk Dokümanları ve Kaynaklar

Uygulamanın **içerik doğruluğu ve kapsamının** sağlanması için aşağıdaki temel kaynakların (tercihen PDF) temini önerilir:

### 13.1. Resmî Metinler

1. **Hukuk Mesleklerine Giriş Sınavı Yönetmeliği**  
2. HMGS’yi düzenleyen **kanun değişiklikleri** (özellikle 7188 sayılı Kanun ve ilgili ek maddeler).  
3. ÖSYM’nin yayımladığı:  
   - Son yıllara ait **HMGS Başvuru Kılavuzları**  
   - **Kılavuzlardaki konu dağılımı, soru sayısı ve sınav süresi** bilgileri  

### 13.2. Temel Kanunlar (güncel metinler)

En azından aşağıdaki kanunların güncel, konsolide hâlleri:

- Anayasa  
- 4721 sayılı Türk Medeni Kanunu  
- 6098 sayılı Türk Borçlar Kanunu  
- 6102 sayılı Türk Ticaret Kanunu  
- 6100 sayılı Hukuk Muhakemeleri Kanunu (HMK)  
- 5271 sayılı Ceza Muhakemesi Kanunu (CMK)  
- 5237 sayılı Türk Ceza Kanunu (TCK)  
- 2004 sayılı İcra ve İflas Kanunu  
- 2577 sayılı İdari Yargılama Usulü Kanunu (İYUK)  
- 5521 sayılı İş Mahkemeleri Kanunu ve ilgili iş hukuku mevzuatı  
- 213 sayılı Vergi Usul Kanunu ve temel vergi mevzuatı  
- 1136 sayılı Avukatlık Kanunu  
- Milletlerarası Hukuk ve Milletlerarası Özel Hukuk ile ilgili temel kanun ve sözleşmeler  

### 13.3. Konu Kitapları (Öneri Türünde)

Tek tek kitap isimleri farklı tercih edilebilir; ancak her ders için şunlara benzer “standart kaynaklar” önerilir:

- Anayasa Hukuku için 1–2 temel ders kitabı  
- Medeni Hukuk ve Borçlar Hukuku için güncel, HMGS kapsamını iyi veren özet ve soru bankası kitapları  
- Ceza Hukuku (Genel–Özel), CMK, İdare, HMK, İcra, Ticaret için HMGS / hakimlik odaklı kitap setleri  
- Avukatlık Hukuku, Hukuk Felsefesi, Türk Hukuk Tarihi için özet kaynaklar  

Bu kitaplar:  
- Soru yazımında referans,  
- AI için prompt hazırlarken “öğrenme hiyerarşisi” oluşturmak,  
- Kullanıcıya önerilen “ek kaynaklar” listesi için kullanılabilir.  

---

**Bu PRD, StajyerPro’nun V1.0 planlaması için referans dokümandır.**  
Tüm teknik ve ürün mimarisi değişiklikleri, bu doküman üzerinde versiyonlanarak güncellenmelidir.

---

## 14. Uygulama İş Akışı ve To-Do Listesi

- [x] Flutter projesini oluşturup Firebase (Auth, Firestore, Storage) entegrasyonunu tamamla; environment ayarlarını paylaş.
- [x] Firestore şema & seed scriptlerini (`subjects`, `topics`, `questions`, `exam_attempts`, `daily_stats`) finalize ederek admin paneli/veri giriş akışını kur.
- [x] Soru bankası pipeline’ı (NotebookLLM şablonu → JSON → Firestore importer) ve kalite kontrol checklist’ini üret.
- [x] UI wireframe + component library’yi (Dashboard, Ders listesi, Quiz, Deneme, AI Koç, Paywall) hazırlayıp Flutter widget stratejisiyle eşleştir.
- [x] Paywall, Free/Pro limit kontrolü ve deneme paketi mağazasının teknik tasarımını (abonelik API’leri, mock sözleşmeler) oluştur.
- [x] Analytics & istatistik modülünü tasarla: `daily_stats`, `user_summary`, grafikler, Cloud Functions ve raporlama entegrasyonu.
- [x] Bildirim & hatırlatma sistemini (çalışma planı tetiklemeleri + Firebase Cloud Messaging) planla.
- [x] QA & release hazırlığı için test senaryoları, güvenlik kontrolleri ve mevzuat güncelleme prosedürünü belgeleyip checklist çıkar.
- [x] Auth & Profil modülü (FR-01/FR-02) için Flutter UI akışı + Firebase Auth ve Firestore user doc entegrasyonunu hazırla.
- [x] Ders/Konu modülü (FR-03/FR-04) için Firestore koleksiyonları, admin yönetim araçları ve Flutter liste ekranlarını geliştir.
- [x] Quiz motoru (FR-05–FR-07) için soru çekme, cevaplama, AI açıklama butonu ve limit kontrollerini uygulamaya dök.
- [x] Deneme sınavı akışı (FR-08–FR-10) + sonuç analizi ekranlarını tasarlayıp veri modeliyle eşleştir.
- [x] AI Koçluk servisi (FR-11–FR-13) için prompt setleri, rate-limit ve UI/Cloud Functions entegrasyonunu kur.
- [x] Monetization/Paywall ekranları ve deneme paketi store’u (FR-17–FR-19) için fiyatlandırma konfigürasyonu + satın alma iş akışını finalize et.