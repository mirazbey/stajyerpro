# 🚀 StajyerPro - Firebase Kurulum Rehberi

## 📋 Önkoşullar
- Firebase projeniz "stajyerpro" adıyla oluşturulmuş olmalı
- Firebase Console'a erişiminiz olmalı

## 🔥 Firebase Konfigürasyon Dosyalarını İndirme

### Android için (google-services.json)

1. [Firebase Console](https://console.firebase.google.com/) açın
2. "stajyerpro" projenizi seçin
3. Sol menüden **Project Settings** (Proje Ayarları) ⚙️ tıklayın
4. **Your apps** bölümünde Android uygulam anızı seçin
   - Eğer Android app yoksa:
     - "Add app" → Android simgesi tıklayın
     - Package name: `com.stajyerpro.stajyerpro_app`
     - App nickname: "StajyerPro Android"
     - Register app butonuna tıklayın
5. **Download google-services.json** butonuna tıklayın
6. İndirilen dosyayı şu konuma kopyalayın:
   ```
   StajyerPro/stajyerpro_app/android/app/google-services.json
   ```

### iOS için (GoogleService-Info.plist)

1. Firebase Console'da aynı projede
2. **Your apps** bölümünde iOS uygulamanızı seçin
   - Eğer iOS app yoksa:
     - "Add app" → iOS simgesi tıklayın
     - Bundle ID: `com.stajyerpro.stajyerproApp`
     - App nickname: "StajyerPro iOS"
     - Register app butonuna tıklayın
3. **Download GoogleService-Info.plist** butonuna tıklayın
4. İndirilen dosyayı şu konuma kopyalayın:
   ```
   StajyerPro/stajyerpro_app/ios/Runner/GoogleService-Info.plist
   ```

## ✅ Kurulum Kontrolü

Config dosyalarını kopyaladıktan sonra:

```powershell
cd StajyerPro/stajyerpro_app
flutter clean
flutter pub get
flutter run
```

## 🔐 Firebase Servisleri Aktifleştirme

Firebase Console'da şu servisleri aktif edin:

### 1. Authentication
- Sol menüden **Authentication** → **Get Started**
- **Sign-in method** sekmesinde şunları aktif edin:
  - ✅ Email/Password
  - ✅ Google

### 2. Firestore Database
- Sol menüden **Firestore Database** → **Create database**
- Mod seçin: **Test mode** (geliştirme için)
- Region: `europe-west3` (Frankfurt) önerilir
- **Create** butonuna tıklayın

### 3. Storage
- Sol menüden **Storage** → **Get Started**
- Güvenlik kurallarını başlat
- Konum: Firestore ile aynı

## 📱 Test Etme

Uygulamayı çalıştırın:

```powershell
cd stajyerpro_app
flutter run
```

Eğer Firebase bağlantısı başarılıysa, login ekranını görmelisiniz!

## 🐛 Sorun Giderme

**Hata: "FlutterError: Unable to load asset"**
- `flutter clean` çalıştırın
- `flutter pub get` tekrar yapın

**Hata: "Firebase API key is invalid"**
- Config dosyalarını doğru klasöre kopyaladığınızdan emin olun
- Dosya isimlerini kontrol edin (tam olarak eşleşmeli)

**Hata: "Google Sign In failed"**
- Firebase Console'da Google Sign-In metodunun aktif olduğunu kontrol edin
- SHA-1 fingerprint'inizi Firebase'e eklemeniz gerekebilir (Android için)

## 🤖 Otomatik Geliştirme Botu

Config dosyalarını yerleştirdikten sonra, sürekli geliştirme botunu çalıştırabilirsiniz:

```powershell
python continuous_dev_bot.py
```

Bot şunları yapar:
- ✅ Tüm features modüllerini oluşturur
- ✅ PRD'ye göre ekranları kodlar
- ✅ Her işlemi `yapilan_islemler.md`'ye raporlar
- ✅ 50 döngü boyunca kesintisiz çalışır

---

## 📞 Destek

Sorun yaşıyorsanız:
1. `yapilan_islemler.md` dosyasını kontrol edin
2. Terminal çıktısını inceleyin
3. Firebase Console'da servis durumlarını gözden geçirin

**Not:** Bot Firebase config olmadan da çalışmaya devam eder, sadece uyarı verir.
