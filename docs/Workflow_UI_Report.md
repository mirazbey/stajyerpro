# StajyerPro Workflow & Experience Blueprint

Bu rapor StajyerPro PRD v1.0 içeriğini operasyonel akış, UI tasarım prensipleri, uygulama mekanizması ve Free/Pro üyelik kurgusu ekseninde yeniden düzenler. Amaç, uygulama geliştirmeye başlamadan önce ürün vizyonunu günlük kullanım senaryolarına ve teknik gereksinimlere çevirerek ekipler arası ortak referans oluşturmaktır.

---

## 1. Uçtan Uca Kullanıcı Workflow'u

### 1.1. Onboarding → Günlük Kullanım Akışı
1. **Splash & Intro Slider** – StajyerPro’nun HMGS koçu olduğu, AI destekli analiz ve deneme özellikleri vurgulanır.
2. **Kayıt / Giriş** – Firebase Auth tabanlı e-posta/şifre veya Google ile kimlik doğrulama (FR-01).
3. **Profil Toplama** – Hedef rol (avukat/hakim/savcı/noter), sınav tarihi ve çalışma yoğunluğu seçimi (FR-02). Bu bilgiler AI planlama için zorunlu input.
4. **Paywall / Free Trial Bilgilendirmesi** – Free ve Pro arasındaki temel farklar onboarding’de özetlenir, kullanıcıya denemeler için başlangıç kredisi tanımlanır.
5. **Dashboard** – Günlük hedef widget’ı, hızlı aksiyon butonları (Quiz, Deneme, AI Koçu) ve özet istatistikler.
6. **Aktivite Akışları**  
   - *Konu Bazlı Quiz*: Ders → Alt konu → Soru sayısı seçimi → Soru çözümü → Doğru/yanlış geri bildirimi → AI açıklaması (FR-05–FR-07).  
   - *Deneme Sınavı*: Deneme seçimi → 120 soruluk oturum → Süre yönetimi → Deneme analizi ekranı (FR-08–FR-10).  
   - *AI Koçluk*: Soru açıklama isteği, serbest chat veya çalışma planı üreticisi (FR-11–FR-13).
7. **İstatistik & Analitik** – Kullanıcının son quiz/deneme performansı, zayıf konular listesi, günlük soru grafikleri (FR-14–FR-15).
8. **Bildirim Döngüsü** – Plan hedeflerine göre push bildirimleri (FR-16).
9. **Abonelik Yönetimi** – Pro abonelik satın alma, deneme kredisi mağazası ve kullanım limitlerini gösteren paywall.

### 1.2. Tipik Kullanıcı Senaryoları
- **Baraj Avcısı**: Günlük hızlı quiz → Haftalık deneme → AI açıklamaları ile konu öğrenme → Zayıf ders drill’i.  
- **Tekrar Deneyen**: Denemeden sonra analiz ekranında zayıf konuları görüp AI planıyla 30 günlük sıkı program başlatır.  
- **Uzun Vadeli Planlayan**: AI’den 90 günlük plan alır, hafif yoğunlukta günlük hatırlatmalar ve aylık ücretsiz denemelerle ilerler.

---

## 2. UI Tasarım Prensipleri ve Ekran Organizasyonu

### 2.1. Görsel Dil
- Minimal, profesyonel ve hukuk temalı; karanlık/açık tema desteği (NFR gereği).
- Performans ve motivasyon odaklı “başarı kartları”, ilerleme barları, hedef rozetleri.
- Free kullanıcılarda banner reklam alanları için yedek bölgeler.

### 2.2. Temel Ekranlar ve Wireframe Notları
1. **Dashboard**  
   - Üstte HMGS geri sayımı, ortada “Bugünkü hedef (X soru)” kartı.  
   - Alt bölümde “Hızlı Başlat” (Quiz/Deneme/AI Koçu) ve mini analiz grafikleri.
2. **Ders Listesi**  
   - Ders kartları (Medeni, Borçlar, Ceza vb.) için ikon + yüzdelik başarı etiketi.  a<s>
   - Her ders kartı alt konu detay sayfasına gider.
3. **Konu Detay & Quiz Başlatma**  
   - Alt konu listesi, soru sayısı seçenekleri, Free/Pro limit göstergesi.  
   - “Önerilen quiz” butonu: zayıf konulardan otomatik oluşturulan set.
4. **Quiz Ekranı**  
   - Üstte soru ilerleme çubuğu ve süre (opsiyonel).  
   - Yanıt sonrası statik açıklama, Pro kullanıcıya “AI çözümünü göster” CTA; Free’de limit sayacı.
5. **Deneme Sınavı Ekranı**  
   - Bölümlere göre soru sayısı, kalan süre, cevaplama navigasyonu.  
   - Çıkışta sonuç özetleri, baraj simülasyonu grafiği.
6. **AI Koç Ekranı**  
   - Chat bubble UI; soru gönderme alanında konu etiketi seçimi.  
   - Çalışma planı sekmesi: 30/60/90 günlük plan listeleri.
7. **İstatistikler**  
   - Line chart: günlük soru sayısı.  
   - Bar chart: ders bazlı doğruluk.  
   - Weak topic list: her biri “Quiz başlat” butonuyla.
8. **Paywall & Mağaza**  
   - Free vs Pro tablo karşılaştırması.  
   - Deneme paketleri için kartlar (5’li, 10’lu).  
   - Limit göstergeleri (kalan AI isteği, soru limiti, deneme hakkı).

---

## 3. Mekanizma Tasarımı

### 3.1. Teknik Katmanlar
- **Flutter Client** – Riverpod tabanlı state yönetimi, responsive widget yapısı (PRD 9.2).  
- **Firebase Auth** – Email/şifre ve Google Sign-in; Firestore Security Rules ile erişim kontrolü.  
- **Firestore** – Kullanıcı profili, konu ağacı, soru bankası, deneme ve attempt verilerini saklayan ana veritabanı.  
- **Cloud Functions** – AI prompt yönetimi, deneme skor hesaplama, abonelik web-hook’ları, limit sayacı güncellemeleri.  
- **Gemini 2.5** – Soru açıklamaları, çalışma planları ve koçluk chat’i için ana model; guardrail prompt’ları hukuki danışmanlık riskini azaltır.  
- **Firebase Storage** – Gelecekte PDF/video gibi ağır içerikler için.

### 3.2. Veri & İş Akışları
1. **Konu Bazlı Quiz**  
   - Kullanıcı seçimleri client’ta → Firestore’dan filtreli soru çekimi → Kullanıcının cevapları local state’te tutulur → Tamamlandığında Cloud Function’a sonuç yazılır → Daily stats güncellenir → AI açıklama çağrıları `ai_sessions` koleksiyonuna loglanır.
2. **Deneme Sınavı**  
   - Deneme konfigürasyonu `exams` koleksiyonundan çekilir → Oturum sırasında cevaplar local cache + periodik Firestore sync → Bitince `exam_attempts` dökümanı oluşur, skor hesaplanır, baraj bilgisi set edilir.
3. **AI Çalışma Planı**  
   - Kullanıcı profili + son istatistikler → Cloud Function prompt → Günlük/haftalık görev listesi döner → `study_plans` alanına kaydedilir ve UI’da timeline olarak sunulur.
4. **Limit & Gating Mekanizması**  
   - Free kullanıcılar için `daily_stats.ai_requests`, `daily_stats.questions_solved` ve `exam_credits` alanları limit kontrolünde kullanılır.  
   - Pro abonelerde limitler yüksek veya devre dışıdır ancak abuse’u önlemek için servis tarafında hard cap tutulur.
5. **Analitik**  
   - Quiz/deneme sonuçlarından türetilen özetler `user_summary` dokümanlarına yazılır; UI grafikleri bu özetlerden beslenerek Firestore okuma maliyeti düşürülür.

### 3.3. Güvenlik ve Uyarılar
- AI yanıtlarının “hukuki danışmanlık” olmadığı her kritik noktada kullanıcıya gösterilir.  
- Prompt’larda “Bu cevap sınav hazırlığı amaçlıdır” uyarısı sabit.  
- Mevzuat değişiklikleri için üç ayda bir içerik revizyon akışı planlanır.

---

## 4. Free vs Pro Üyelik İçeriği

| Özellik | Free Plan | Pro Plan |
| --- | --- | --- |
| Günlük Quiz Sorusu | ~40 soru limiti, reklam gösterimi | Yüksek/sınırsız limit, reklamsız |
| AI Açıklama / Chat | Günlük 3–5 açıklama + 5 chat mesajı | Günlük 200’e kadar açıklama + pratikte sınırsız chat |
| Deneme Sınavı | Aylık 1 ücretsiz deneme | Sınırsız veya aylık 30 deneme |
| AI Çalışma Planı | Onboarding’de 1 plan, güncelleme limitli | 30/60/90 günlük planları sınırsız güncelleme |
| Analitik | Temel doğru/yanlış tabloları | Gelişmiş grafikler, weak topic drill önerileri |
| Reklamlar | AdMob banner/interstitial | Yok |
| Deneme Paketleri | Store’dan paket satın alarak ekstra hak | Pro olsa da paket satın alımı ek krediler sağlar |
| Fiyatlandırma | Ücretsiz | Haftalık ~129 TL, yıllık ~999 TL (PRD varsayımı) |

Ek olarak, Free kullanıcıya onboarding’de “Pro deneme” için kısa süreli (ör. 7 gün) kampanya sunulabilir; iptal edilmezse abonelik devam eder. Deneme paketleri, plan bağımsız `exam_credits` alanına yazılarak yönetilir.

---

## 5. Yol Haritası ile Eşleşme

1. **Faz 1 – MVP**  
   - Yukarıdaki workflow’un temel parçaları: Auth, profil, ders/kategori, konu bazlı quiz, basit sonuç ekranı, minimal Free/Pro ve AI açıklaması.  
   - UI: Dashboard, Ders Listesi, Quiz ekranı ve Paywall’ın basit sürümleri tasarlanmalı.
2. **Faz 2 – Deneme & İstatistik**  
   - Deneme sınavı akışı, sonuç analizi ekranı, temel grafikleri UI kütüphanesinde tamamla.  
   - AI çalışma planı ekranı ve veri modeli aktif hale gelir.
3. **Faz 3 – Koçluk & Monetization**  
   - AI chat UI’sı, deneme paket mağazası, bildirim scheduler’ı ve gelişmiş analitikler.  
   - Gating mekaniği + paywall optimizasyonu.
4. **Faz 4 – Opsiyonel Genişleme**  
   - İYÖS modu, web arayüzü, zengin içerik (video/podcast) gibi yeni kanallar bu rapordaki mekanizmalar üzerine inşa edilir.

---

## 6. Sonraki Aşamalar İçin Öneriler
1. **Wireframe & Component Library** – Yukarıdaki ekran notlarına göre Figma’da komponent kütüphanesi oluşturup Flutter widget stratejisini netleştir.
2. **Firestore Şema Doğrulaması** – PRD’deki şema taslağını gerçek koleksiyon/alan isimleriyle finalize ederek seed/edit araçlarını planla.
3. **AI Prompt Kartları** – Soru açıklama, çalışma planı ve chat için örnek prompt + guardrail setlerini hazırlayıp Cloud Functions’a göm.
4. **Free/Pro İzleme Paneli** – Kullanım limitleri, conversion funnel ve gelir ölçümleri için Firebase Analytics + BigQuery entegrasyonunu planla.
5. **İçerik Operasyonu** – HMGS resmi kaynaklarını (kanun PDF’leri, ÖSYM kılavuzları) toplayıp soru yazım sürecini ve doğrulama checklist’ini oluştur.

Bu rapor, geliştirme sürecinde hem ürün hem de mühendislik ekiplerine tek referans olacak şekilde StajyerPro PRD’sinin kritik ögelerini yeniden yapılandırır. İhtiyaç halinde yeni sürümlerde modül bazlı eklemeler yapılabilir.
