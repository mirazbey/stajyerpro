# StajyerPro - HMGS Hazırlık ve Sınav Koçu 🚀

StajyerPro, Hukuk Mesleklerine Giriş Sınavı (HMGS) adayları için geliştirilmiş, yapay zeka destekli, kapsamlı bir mobil hazırlık platformudur.

## 🎯 Proje Amacı
HMGS adaylarına, sadece soru çözdüren değil, aynı zamanda **öğreten**, **analiz eden** ve **kişiselleştirilmiş rehberlik sunan** bir dijital ekosistem sağlamak.

## ✨ Temel Özellikler

### 📚 Kapsamlı Soru Bankası
- HMGS müfredatına uygun 20+ ders modülü.
- **Konu Bazlı Test:** İstediğiniz dersten ve konudan test oluşturun.
- **Hızlı Test (Time Attack):** 25 dakikada 20 soru ile hızınızı test edin.
- **Maraton Modu:** Sınırsız soru ile dayanıklılığınızı ölçün.

### 🤖 AI Sınav Koçu (Gemini Destekli)
- **Akıllı İpuçları:** Sorularda takıldığınızda AI'dan ipucu alın.
- **Detaylı Çözüm Analizi:** Yanlış cevaplarınız için AI destekli, kanun maddeli açıklamalar.
- **Kişiselleştirilmiş Öneriler:** Zayıf olduğunuz konuları tespit edip size özel çalışma planı sunar.

### 📊 Gelişmiş Analitik
- **Detaylı İstatistikler:** Konu bazlı başarı oranları, hız analizi ve haftalık trendler.
- **Hedef Takibi:** Hedef puanınızı belirleyin, ne kadar yaklaştığınızı görün.
- **Rozet Sistemi:** Başarılarınızı rozetlerle taçlandırın ve liderlik tablosunda yarışın.

### 🔄 Akıllı Tekrar Sistemi
- **Yanlış Havuzu:** Yanlış yaptığınız soruları kaydedin ve daha sonra tekrar çözün.
- **Zayıf Konu Analizi:** Başarı oranınızın düşük olduğu konuları otomatik tespit eder.

## 🛠️ Teknolojiler

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Backend:** Firebase (Firestore, Auth, Functions)
- **AI:** Google Gemini API
- **Architecture:** Feature-First, Clean Architecture

## 🚀 Kurulum

1. **Projeyi Klonlayın:**
   ```bash
   git clone https://github.com/username/stajyerpro.git
   ```

2. **Bağımlılıkları Yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Firebase Yapılandırması:**
   - `flutterfire configure` komutu ile Firebase projenizi bağlayın.

4. **Uygulamayı Çalıştırın:**
   ```bash
   flutter run
   ```

## 📂 Proje Yapısı

```
lib/
├── core/           # Tema, Router, Utils gibi çekirdek modüller
├── features/       # Özellik bazlı modüller (Auth, Exam, Quiz, Analytics vb.)
│   ├── data/       # Repository ve Data Source katmanı
│   ├── domain/     # Model ve Entity katmanı
│   └── presentation/ # UI ve Controller katmanı
└── shared/         # Ortak widget ve modeller
```

## 📝 Katkıda Bulunma

1. Forklayın.
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`).
3. Commit atın (`git commit -m 'Add some amazing feature'`).
4. Pushlayın (`git push origin feature/amazing-feature`).
5. Pull Request açın.

---
**Not:** Bu proje HMGS hazırlık sürecini dijitalleştirmek amacıyla geliştirilmektedir. İçerikler hukuki tavsiye niteliği taşımaz.
