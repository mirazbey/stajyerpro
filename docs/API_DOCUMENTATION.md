# Teknik API Akışı ve Modeller

## Konu Bazlı Rastgele Test
- `getFastTestQuestions({subjectId, topicId, count})`: Seçilen ders/konu ve istenen sayıda rastgele soru getirir. Soru modeli: id, subjectId, topicId, text, options[], correctOption, detailedExplanation, aiTip

## AI Destekli İpucu Baloncuğu
- Soru modelinde `aiTip` alanı (opsiyonel). Eğer yoksa, AI servisine prompt ile kısa ipucu üretilir.

## Yanlış Soruda AI/Uzman Açıklaması
- Soru modelinde `detailedExplanation` alanı (opsiyonel). Eğer yoksa, AI servisine prompt ile detaylı açıklama üretilir.

## Kişiselleştirilmiş Analiz ve Plan
- `getPersonalizedAnalysis(userId)`: Kullanıcının zayıf olduğu konuları ve çalışma planı önerilerini döner. UserStats modeli: userId, subjectId, topicId, correctCount, wrongCount, lastTestedAt
- Plan modeli: userId, topicId, recommendedDate, note

## Sınav Simülasyonu ve Zaman Yönetimi
- `getExamSimulation({userId, examType})`: Gerçek sınav formatında deneme başlatır, süre ve soru dağılımı parametreleriyle. Exam modeli: id, userId, type, questionIds[], startedAt, finishedAt, duration, score, perQuestionDuration[]

## Gelişmiş İstatistik ve Bildirimler
- `getAdvancedStats(userId)`: Konu bazlı başarı, hız, hata ve eksik analizlerini döner. Stat modeli: userId, subjectId, topicId, correctCount, wrongCount, avgDuration
- `getNotifications(userId)`: Sınav takvimi, mevzuat değişikliği, yeni paketler gibi güncel bildirimleri döner. Notification modeli: id, userId, type, title, content, createdAt, read
# StajyerPro API Dokümantasyonu

Bu doküman, StajyerPro uygulamasının teknik mimarisini, veri modellerini ve temel servislerini açıklar.

## 🏗️ Mimari Genel Bakış
Proje, **Feature-First** klasör yapısını ve **Riverpod** ile state management yaklaşımını benimser.

### Klasör Yapısı
```
lib/
├── core/           # Ortak kullanılan yapılandırmalar (Router, Theme, Utils)
├── features/       # Özellik bazlı modüller (Auth, Exam, Quiz, Gamification)
│   ├── data/       # Repository ve Data Source'lar
│   ├── domain/     # Modeller ve Entity'ler
│   └── presentation/ # UI ve Controller'lar
└── shared/         # Paylaşılan widget'lar ve modeller
```

---

## 📦 Veri Modelleri (Domain)

### QuestionModel
Soru verisini temsil eder.
- `id` (String): Benzersiz ID.
- `stem` (String): Soru metni.
- `options` (List<String>): Şıklar (A-E).
- `correctIndex` (int): Doğru şıkkın indeksi (0-4).
- `subjectId` (String): Ders ID'si.
- `difficulty` (String): Zorluk seviyesi ('easy', 'medium', 'hard').
- `lawArticle` (String?): İlgili kanun maddesi.
- `detailedExplanation` (String?): Detaylı çözüm açıklaması.
- `aiTip` (String?): AI tarafından üretilen kısa ipucu veya pratik öneri (soru çözüm ekranında baloncuk olarak gösterilir).
- `wrongReasons` (Map<int, String>?): Yanlış şıkların neden yanlış olduğu.

### ExamAttemptModel
Kullanıcının deneme sınavı girişimini temsil eder.
- `id` (String): Girişim ID'si.
- `userId` (String): Kullanıcı ID'si.
- `examId` (String): Sınav ID'si.
- `score` (int): Puan (0-100).
- `answers` (Map<int, int>): Kullanıcının cevapları {soruIndex: cevapIndex}.
- `startedAt` (DateTime): Başlangıç zamanı.
- `completedAt` (DateTime?): Bitiş zamanı.

### BadgeModel
Oyunlaştırma rozetini temsil eder.
- `id` (String): Rozet ID'si.
- `conditionType` (enum): Kazanma koşulu (score, streak, examCount).
- `conditionValue` (int): Hedef değer.

---

## 🛠️ Servisler ve Repository'ler

### ExamRepository
Sınav ve soru verilerine erişimi yönetir.
- `getExamQuestions(examId)`: Bir sınav için soruları getirir. HMGS dağılımına göre soru seçer.
- `getFastTestQuestions({subjectId, topicId, count})`: Seçilen ders/konu ve istenen sayıda rastgele soru getirir. Test sırasında AI ipucu baloncuğu desteği sunar.
# Ek API Notları

- `getPersonalizedAnalysis(userId)`: Kullanıcının zayıf olduğu konuları ve çalışma planı önerilerini döner.
- `getExamSimulation({userId, examType})`: Gerçek sınav formatında deneme başlatır, süre ve soru dağılımı parametreleriyle.
- `getAdvancedStats(userId)`: Konu bazlı başarı, hız, hata ve eksik analizlerini döner.
- `getNotifications(userId)`: Sınav takvimi, mevzuat değişikliği, yeni paketler gibi güncel bildirimleri döner.
- `getMarathonQuestions(limit, lastDoc)`: Maraton modu için sayfalı soru getirir.

### GamificationRepository
Rozet ve liderlik tablosu işlemlerini yönetir.
- `checkAndUnlockBadges(userId, type, value)`: Yeni rozet kazanılıp kazanılmadığını kontrol eder.
- `getLeaderboard(period)`: Haftalık/Aylık sıralamayı getirir.

### WrongAnswerRepository
Yanlış yapılan soruları yönetir.
- `addToWrongPool(questionId)`: Soruyu yanlış havuzuna ekler.
- `removeFromWrongPool(questionId)`: Soruyu havuzdan çıkarır.
- `getWrongAnswers()`: Havuzdaki soruları getirir.

---

## 🔐 Güvenlik ve Kurallar
- **Firestore Rules**: Kullanıcılar sadece kendi `exam_attempts` ve `user_badges` verilerini yazabilir.
- **Validation**: Soru eklerken tüm şıkların dolu olması zorunludur.
