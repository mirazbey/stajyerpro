# Flutter + Firebase Setup Plan


Bu plan, StajyerPro için Flutter istemcisi ile Firebase (Auth, Firestore, Storage) entegrasyonunu kurarken izlenecek adımları özetler.

## 1. Flutter Projesi
- Flutter 3.19+ sürümünün kurulu olduğunu doğrula (`flutter --version`).
- Projeyi `stajyerpro_app` adıyla oluştur: `flutter create stajyerpro_app`.
- `lib/` altına `core`, `features`, `shared` klasörlerini ekle; Riverpod ve go_router bağımlılıkları için `pubspec.yaml` güncelle.

## 2. Firebase Entegrasyonu
- Firebase Console’da `stajyerpro-app` projesini aç; Android ve iOS uygulamaları ekle.
- Android için `google-services.json`, iOS için `GoogleService-Info.plist` dosyalarını `stajyerpro_app/android/app` ve `ios/Runner` içine yerleştir.
- `flutterfire configure` komutunu çalıştırarak `firebase_options.dart` üret.

## 3. Auth (FR-01/FR-02)
- Firebase Auth’ta Email/Password + Google Sign-In aktif et.
- Onboarding sırasında hedef rol, sınav tarihi ve çalışma yoğunluğu Firestore’daki `users/{uid}` dokümanına yazılacak.

## 4. Firestore & Storage
- Koleksiyonlar: `users`, `subjects`, `topics`, `questions`, `exam_attempts`, `daily_stats`, `ai_sessions`.
- `lib/core/firebase/firestore_paths.dart` dosyasında koleksiyon sabitlerini tanımla.
- Storage’da ileride PDF/video içeriği için `content/` klasörü aç.

## 5. Ortam Değişkenleri
- `.env` benzeri dosyada API anahtarları tutulacak; Flutter tarafında `flutter_dotenv` ile kullan.
- `README.md` içinden Firebase proje ID, App ID, `firebase_options.dart` üretim talimatları paylaş.

Bu dosya script_runner tarafından 2025-11-17 16:01:32Z tarihinde üretildi.
