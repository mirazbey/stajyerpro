# StajyerPro Development TODO

## ✅ Tamamlanan Özellikler (v1.0 - v1.3)

- [x] Fix UTF-8 text/encoding issues in paywall and other screens (garbled Turkish characters).
- [x] Implement Free/Pro gating: user plan provider, daily limits (quiz/AI/deneme), and enforcement in UI flows (quiz check).
- [x] Stub purchase/restore flow and paywall actions; wire plan state to paywall buttons.
- [x] Add subscription/credits data model (Firestore) and integrate with app state (deneme paketleri, extra credits).
- [x] Implement AI coach/study plan service layer with usage logging and rate limits.
- [x] Implement exam/deneme attempt flow + result analysis UI with Firestore data (gating eklendi).
- [x] Build analytics summaries (daily_stats, user_summary) and charts plumbing.
- [x] Add notifications (FCM/local) hooks for study plan reminders.
- [x] Integrate admin/seed flow or in-app management for subjects/topics/questions.
- [x] QA checklist: tests for gating, quiz/exam flows, and critical screens.
- [x] **Mikro-Öğrenme Sistemi** - Hap Bilgi + Quiz döngüsü (TopicLessonScreen, LessonCompleteScreen)
- [x] **AI İçerik Üretimi** - Zengin eğitim içeriği (tablolar, emojiler, ezber teknikleri)
- [x] **İstatistik Entegrasyonu** - 6 Firestore koleksiyonuna kayıt
- [x] **Admin Paneli Sadeleştirme** - Müfredat oluşturucu kaldırıldı, içerik durumu eklendi

### v1.3 - 03.12.2024 (Quiz Sistemi & Shadcn UI)
- [x] **HMGS Soru Bankası** - 1173 soru, 15 ders, tüm konular için içerik üretildi
- [x] **Shadcn UI Tasarım Sistemi** - Modern UI component kütüphanesi oluşturuldu:
  - `shadcn_theme.dart` - Renkler, tipografi, efektler, gölgeler
  - `shadcn_button.dart` - 5 buton varyantı (primary, secondary, outline, ghost, destructive)
  - `shadcn_card.dart` - 4 kart tipi (ShadcnCard, StatsCard, FeatureCard, OptionCard)
  - `shadcn_input.dart` - Input, select, switch bileşenleri
  - `shadcn_components.dart` - Badge, Progress, Toggle, Avatar, Skeleton
- [x] **ModernQuizSetupScreen** - 3 quiz modu ile modern quiz başlatma ekranı:
  - Hızlı Quiz (10 soru, rastgele)
  - Ders Bazlı (20 soru, seçilen ders)
  - Konu Bazlı (özelleştirilebilir, seçilen konular)
- [x] **Mini Sınav Desteği** - MiniExamConfig sınıfı (20 soru, 25 dakika, ders bazlı)
- [x] **Router Entegrasyonu**:
  - `/quiz/modern-setup` - Modern quiz setup ekranı
  - `/subjects/:subjectId/mini-exam` - Ders bazlı mini sınav
- [x] **Dashboard "Hızlı Quiz" Butonu** - BentoGrid'e amber renkli hızlı quiz kartı eklendi
- [x] **TopicDetailScreen "Mini Sınav" Butonu** - Ders detay ekranına mini sınav başlatma butonu eklendi
- [x] **Hata Düzeltmeleri**:
  - CardTheme → CardThemeData (Flutter 3.7+ uyumu)
  - DialogTheme → DialogThemeData
  - Matrix4.scale() ve Matrix4.translate() parametre düzeltmeleri
  - .animate() extension method çakışması → Animate widget kullanımı
  - List<dynamic> → List<Widget> type cast düzeltmesi
  - `/quiz/play` → `/quiz/start` route düzeltmesi

### v1.4 - 03.12.2024 (HMGS Deneme Sınavı Sistemi)
- [x] **HMGS Net Hesaplama** - `HMGSNetCalculator` sınıfı:
  - Net = Doğru - (Yanlış / 4) formülü
  - 70 baraj kontrolü
  - Puan hesaplama (net/120 * 100)
- [x] **ExamAttemptModel Güncellemesi**:
  - `markedQuestions` - Sonra bak işaretleme
  - `wrongAnswers`, `emptyAnswers` - Detaylı sayaçlar
  - `net` - HMGS net değeri
  - `subjectResults` - Ders bazlı sonuçlar (SubjectResult modeli)
- [x] **HMGSExamScreen** - Tam kapsamlı deneme sınavı ekranı:
  - 120 soru, 150 dakika kronometre
  - Soru işaretleme (sonra bak)
  - Drawer ile soru navigasyonu (grid view)
  - Cevaplanmış/boş/işaretli soru istatistikleri
  - Uygulama çıkış uyarısı (strict mode)
  - Ders etiketi her soruda görünür
- [x] **HMGSExamResultScreen** - Detaylı sonuç analizi:
  - Hero score kartı (gradient, animasyonlu)
  - Net hesaplama görselleştirmesi (formül gösterimi)
  - 70 baraj simülasyonu (progress bar + mesaj)
  - Ders bazlı performans (stacked bar chart)
  - Zaman yönetimi analizi
  - Yanlış/boş soru inceleme
- [x] **Router Entegrasyonu**:
  - `/exam/hmgs/start` - HMGS deneme başlatma
  - `/exam/hmgs_simulation/result/:attemptId` - Sonuç ekranı
- [x] **Dashboard "HMGS Deneme" Butonu** - Mor gradient kartı
- [x] **ExamListScreen Güncellemesi** - HMGS Featured Card (öne çıkan)

---

## 🚀 ROADMAP - Sonraki Adımlar

### Faz 1: Temel İyileştirmeler (1-2 Hafta)
**Öncelik: Yüksek**

- [x] **1.1 Deneme Sınavı Modu (FR-08 - FR-10)** ✅
  - Gerçek HMGS formatında 120 soru, 150 dakika süreli deneme
  - Sınav sırasında kronometre ve soru navigasyonu
  - Sonuç ekranı: Net hesaplama, ders bazlı analiz, 70 baraj simülasyonu
  - Deneme geçmişi ve karşılaştırma

- [x] **1.2 Zayıf Konu Analizi (FR-15)**
  - Kullanıcının en düşük başarı oranına sahip 5 konusunu gösterme
  - "Bu konulara göre önerilen quiz başlat" butonu
  - Mikro-öğrenme ile entegrasyon (zayıf konudan ders başlat)
  - WeakTopicsScreen ve SmartSuggestionCard iyileştirildi

- [x] **1.3 İstatistik Ekranı İyileştirmeleri**
  - Haftalık/aylık trend grafikleri (_MonthlyTrendCard)
  - Ders bazlı detaylı analiz (_SubjectPerformanceCard)
  - Hedef takibi (günlük soru hedefi)

### Faz 2: Koçluk & Kişiselleştirme (2-3 Hafta)
**Öncelik: Orta-Yüksek**

- [x] **2.1 Serbest Koçluk Chat'i (FR-12)**
  - Kullanıcının HMGS konuları hakkında soru sorabilmesi
  - AI ile interaktif sohbet (hukuki danışmanlık değil, eğitim odaklı)
  - Sohbet geçmişi drawer ve favorilere ekleme
  - Önerilen sorular özelliği

- [x] **2.2 Kişiselleştirilmiş Çalışma Planı (FR-13)** ✅
  - Hedef tarih + günlük çalışma süresi girişi
  - AI tarafından 30/60/90 günlük plan oluşturma
  - Günlük görevler ve hatırlatmalar
  - CreateStudyPlanScreen (3 adımlı wizard)
  - PersonalizedStudyPlanScreen (günlük görev takibi)
  - Dashboard'a çalışma planı kartı eklendi

- [x] **2.3 Bildirimler & Hatırlatıcılar (FR-16)**
  - Günlük çalışma hatırlatmaları (FCM)
  - "Sınava X gün kaldı" bildirimleri (90, 60, 30, 14, 7, 3, 1 gün)
  - Çalışma serisini koruma motivasyonu
  - Motivasyon bildirimleri

### Faz 3: Monetization & Polish (2-3 Hafta)
**Öncelik: Orta**

- [ ] **3.1 In-App Purchase Entegrasyonu**
  - Google Play Billing API kurulumu
  - Haftalık/yıllık abonelik akışı
  - Deneme paketi satın alma

- [ ] **3.2 Reklam Entegrasyonu (Free Plan)**
  - AdMob banner reklamları
  - Quiz arası interstitial (opsiyonel)
  - Rewarded video (ekstra AI kullanım hakkı)

- [ ] **3.3 UI/UX Polish**
  - Animasyonlar ve geçişler
  - Dark/Light tema desteği
  - Onboarding akışı iyileştirme

### Faz 4: Gelişmiş Özellikler (3-4 Hafta)
**Öncelik: Düşük**

- [ ] **4.1 Sosyal Özellikler**
  - Liderlik tablosu (opsiyonel)
  - Başarı rozetleri ve paylaşım

- [ ] **4.2 Offline Mod**
  - Soruların cihaza cache'lenmesi
  - Offline quiz çözme
  - Online olunca senkronizasyon

- [ ] **4.3 Web Arayüzü**
  - Flutter Web build
  - Responsive tasarım

---

## 📋 Teknik Borç (Technical Debt)

- [ ] Unit testler için coverage artırma
- [ ] Error handling ve logging iyileştirme
- [ ] Firestore security rules audit
- [ ] Performance profiling ve optimizasyon
- [ ] CI/CD pipeline kurulumu

---

## 🎯 Önerilen Başlangıç Sırası

1. **Deneme Sınavı Modu** → En çok talep edilen, HMGS hazırlığı için kritik
2. **Zayıf Konu Analizi** → Mevcut mikro-öğrenme ile entegre
3. **Serbest Koçluk Chat'i** → AI yatırımının karşılığını alma
4. **In-App Purchase** → Gelir akışı başlatma
