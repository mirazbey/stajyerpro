# Teknik Yol Haritası ve Kullanım Notları

## Konu Bazlı Rastgele Test
- Admin, soru eklerken doğru subjectId/topicId ile etiketleme yapmalı.
- Test başlatıldığında, sistem ilgili konuya ait soruları rastgele çeker.
- Soru havuzunun genişliği ve etiketleme kalitesi önemlidir.

## AI Destekli İpucu Baloncuğu
- Soruya eklenmiş `aiTip` varsa, kullanıcıya gösterilir.
- Yoksa, AI servisi prompt ile kısa pratik ipucu üretir.
- Admin, örnek ipuçlarını manuel de girebilir.

## Yanlış Soruda AI/Uzman Açıklaması
- Soruya eklenmiş `detailedExplanation` varsa, yanlış cevapta gösterilir.
- Yoksa, AI servisi prompt ile detaylı açıklama üretir.

## Kişiselleştirilmiş Analiz ve Plan
- Kullanıcı test/deneme sonuçları analiz edilir.
- Zayıf konular belirlenir, çalışma planı önerisi sunulur.
- Admin, analiz algoritmasını ve öneri metinlerini güncelleyebilir.

## Sınav Simülasyonu ve Zaman Yönetimi
- Deneme sınavı başlatıldığında, süre ve soru dağılımı admin panelinden ayarlanabilir.
- Sınav sonunda, zaman yönetimi raporu ve analiz sunulur.

## Gelişmiş İstatistik ve Bildirimler
- Kullanıcıya konu bazlı başarı, hız, hata analizleri ve güncel bildirimler sunulur.
- Admin, bildirimleri panelden yönetebilir.
# StajyerPro Yönetici Rehberi

Bu rehber, içerik yöneticilerinin sisteme soru eklemesi ve düzenlemesi içindir.

## 📝 Soru Ekleme

Admin paneline erişmek için yetkili hesapla giriş yapın ve menüden **"Soru Yönetimi"** seçeneğine gidin.

### Soru Giriş Formu
1. **Ders ve Konu:** Sorunun ait olduğu dersi ve alt konuyu doğru seçin.

## Yeni Özellikler ve Kullanım Notları

- **Konu Bazlı Rastgele Test:** Kullanıcı, admin panelinden tanımlanan ders/konu başlıklarına göre rastgele test başlatabilir. Soru havuzunun genişliği ve etiketleme kalitesi önemlidir.
- **AI Destekli İpucu Baloncuğu:** Soru çözüm ekranında, admin tarafından eklenen kısa pratik ipuçları veya AI tarafından otomatik üretilen özetler gösterilebilir. Yanlış yapılan sorularda, AI/uzman açıklaması ve püf noktası sunulmalıdır.
- **Kişiselleştirilmiş Analiz ve Plan:** Kullanıcıların zayıf olduğu konular, sistem tarafından analiz edilip çalışma planı önerileri sunulabilir. Admin, bu analizlerin doğruluğunu kontrol edebilir.
- **Sınav Simülasyonu ve Zaman Yönetimi:** Gerçek sınav formatında deneme sınavları oluşturulabilir. Admin, süre ve soru dağılımı ayarlarını yönetir.
- **Gelişmiş İstatistikler:** Kullanıcıların konu bazlı başarı, hız, hata ve eksik analizleri sistemde tutulur. Admin, bu raporları görebilir ve iyileştirme önerileri sunabilir.
- **Güncel Bildirimler:** Sınav takvimi, mevzuat değişikliği, yeni paketler gibi güncellemeler admin tarafından duyurulabilir.
2. **Soru Metni (Stem):** Açık, anlaşılır ve imla kurallarına uygun olmalıdır.
3. **Şıklar:** 5 adet şık (A, B, C, D, E) girilmelidir.
4. **Doğru Cevap:** Doğru şıkkı işaretleyin.
5. **Zorluk:** Sorunun zorluk seviyesini (Kolay/Orta/Zor) belirleyin.

### Detaylı Alanlar (Önemli ⭐)
Kaliteli bir soru bankası için aşağıdaki alanların doldurulması kritiktir:

- **Kanun Maddesi:** Sorunun dayanağı olan kanun ve madde numarası.
  - *Örnek:* "TMK m. 123" veya "TBK m. 45"
- **Detaylı Açıklama:** Doğru cevabın neden doğru olduğunu açıklayan metin. Kanuni gerekçe buraya yazılmalıdır.
- **Yanlış Şık Açıklamaları:** Çeldirici şıkların neden yanlış olduğunu açıklayın. Bu, öğrencinin hatasını anlaması için çok değerlidir.

---

## ⚠️ İçerik Standartları

### Biçimlendirme
- **Kalın/İtalik:** Vurgulanması gereken yerleri (örn: **değildir**, *yanlıştır*) biçimlendirin.
- **Uzunluk:** Soru metni çok uzun olmamalı, okuyucuyu yormamalıdır. HMGS formatına uygun olmalıdır.

### Kalite Kontrol
- Soruyu kaydetmeden önce mutlaka önizleme yapın.
- Şıkların birbirine çok yakın veya tartışmalı olmamasına dikkat edin.
- Yazım hatalarını kontrol edin.

---

## 🔄 Soru Güncelleme
Hatalı bir soru raporlandığında:
1. Soru listesinden ilgili soruyu bulun.
2. "Düzenle" butonuna tıklayın.
3. Gerekli düzeltmeyi yapıp "Kaydet" butonuna basın.
4. Değişiklik anında tüm kullanıcılara yansır.

---

## 📦 Manuel İçerik Stratejisi

Projemizde soruların kalitesini ve doğruluğunu sağlamak amacıyla **manuel veri girişi** tercih edilmektedir.

### Neden Manuel Giriş?
- **Doğruluk:** Hukuk soruları hassastır, AI hataları yanıltıcı olabilir.
- **Format:** HMGS formatına birebir uygunluk.
- **Kategorizasyon:** Konu ve alt konu etiketlerinin uzman gözüyle yapılması.

### Toplu İşlemler
Şu an için toplu soru yükleme (batch import) özelliği aktif değildir. Tüm sorular Admin Paneli üzerinden tek tek, kontrol edilerek girilmelidir.

