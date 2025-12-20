# StajyerPro UI/UX Tasarım Raporu (Elite/Trend Odaklı)

## 1) Tasarım Prensipleri
- **Stil**: Minimal + sofistike. Arka plan tek renk değil; gradient + hafif noise. Düzenli grid, bol whitespace.
- **Tipografi**: Başlık: display/grotesk (örn. Aeonik/Space Grotesk/Neue Montreal). Gövde: modern grotesk (Suisse Int’l, Forma DJR, Manrope alternatifi). H1 30–34, H2 24–28, body 15–16, caption 12–13. Başlıkta hafif letter spacing.
- **Renk Sistemi**: Ana: #5B21B6 (mor) veya #0F4C81 (derin mavi). Vurgu: #F5B400 (kehribar) veya #22C55E (yeşil). Nötr: Kömür #0F172A, Açık #F8FAFC. Durum: Success #22C55E, Warning #F59E0B, Danger #EF4444, Info #3B82F6.
- **Dokular & Kenarlar**: Radius 12/16. Shadow yerine yumuşak border (#E5E7EB) + çok hafif elevasyon. Blur (frosted) için 12px blur + %60 beyaz overlay.
- **Motion**: 150–220 ms ease-out; page load fade+scale, kart hover’da 2–3px lift, progress ring stroke animasyon, skeleton yerine “pulse blur”.
- **Erişilebilirlik**: Kontrast ≥ 4.5:1, dokunma hedefi ≥ 44px, renk + ikon çift kodlama, font scaling uyumlu.

## 2) Design Tokens (özet)
- **Spacing**: 4-8-12-16-24-32.
- **Radius**: 8 (buton/input), 12 (kart), 16 (hero/panel).
- **Border**: 1px #E5E7EB; highlight: 2px ana renk + %12 fill.
- **Animasyon**: fast 150ms, base 200ms, slow 250ms (ease-out).
- **Typography**: DisplayBold/H1: 30–34/1.2, H2: 24–28/1.25, Body: 15–16/1.5, Caption: 12–13/1.4.

## 3) Komponent Seti
- **Butonlar**: Filled (ana), Ghost (border), Tertiary (text); icon + label zorunlu. Loading state (spinner/ellipsis).
- **Kartlar**: Başlık, alt başlık, aksiyon (Chevron/CTA). Status çipi sağ üst; progress bar/ring opsiyon.
- **Çip/Pill**: Filtre/etiket; seçili durumda dolu + ikon.
- **Tab/Segment**: Altta 3px aksan bar, 16px padding, 12px radius.
- **Form/Input**: Dolgu + border; focus’ta 2px ana renk. Hatada kırmızı border + yardım yazısı.
- **List Row**: Sol ikon, orta başlık/alt başlık, sağ aksiyon (badge/chevron).
- **Grafik Placeholder**: Area chart + marker; bar micro chart; donut/ring için ince stroke.
- **Badge**: Premium için rozet (altın degrade + ince siyah border).

## 4) Ekran Taslakları
### Onboarding
- 3 adım hero (illüstrasyon + kısa vaat), CTA “Başla”.
- Hedef rol ve sınav tarihi seçim kartları “pill” stili; ilerleme göstergesi dots.

### Dashboard
- Üst hero: Selamlama + günlük hedef çipi + “Bugün yapacakların” checklist.
- 2x2 CTA kart grid: Quiz, Deneme, AI Coach, Plan (her biri ikon + kısa veri).
- Alt sıra: Mini grafikler (günlük soru sayısı, doğruluk yüzdesi), zaman filtresi.
- Hızlı aksiyon bar: “Hızlı Quiz”, “AI Aç”, “Planımı Gör”.

### Quiz / Deneme
- Soru kartı: Sol üst konu/etiket, sağda zaman çipi. Seçenekler kart gibi; seçili durumda accent border + hafif fill.
- İlerleme bar üstte; alt aksiyon: “İşaretle”, “Açıklama” (Pro’da), “Sonraki”.

### AI Coach
- Chat baloncukları: Kullanıcı koyu kömür, bot açık krem; kart sınırı ince.
- Üstte kaynak filtresi pill’leri (pdf/konu). Altta aksiyon: “AI Aç”, “Kaynak Ekle”.
- Yan panel (tablet/desk): Son görüşmeler listesi + hızlı ipucu kutusu.

### Study Plan
- Gün kartları listesi: Progress ring, süre etiketi, hatırlat ikon. Takvim 2 haftalık, seçili gün highlight.
- CTA: “Bugünün görevini başlat”, “Hatırlatıcı kur”.

### Paywall (Premium)
- Gradient hero + premium rozet; iki plan kartı (Haftalık/Yıllık) stagger anim.
- Avantaj listesi (check ikonlu, cam efektli panel). “Satın al” ve “Geri yükle” butonları.

## 5) Uygulama Adımları (Kod)
- `reports/` altına bu rapor + ileride ekran bazlı rehberler.
- `lib/theme/design_tokens.dart`: renk paleti, tipografi stilleri, radius/spacing, anim süreleri; ThemeData’ya entegre.
- Paywall ekranını yeni stile göre güncelle (gradient, cam panel, iki plan kartı).
- Dashboard örnek sayfası oluştur (mock veriyle) => hero + 2x2 grid + mini chart placeholder.
- Quiz ekranı seçenek kartlarını accent border/fill ile yenile; timer çip ve ilerleme barı notasyonunu temizle.
- AI coach chat bubble’ları ve kaynak filtresi pill’lerini düzenle; aksiyon buton barı ekle.

## 6) Kaynak & İlham
- Tipografi: Aeonik/Space Grotesk/Neue Montreal (alternatif: Manrope sadece body için).
- İkon: Phosphor/Feather outline seti.
- Motion: Cubic bezier (0.18, 0.88, 0.32, 1.1) hafif “overshoot” için; aksi halde ease-out.

## 7) Risk & Notlar
- Font lisansları: Ücretli font seçilirse self-host lisans gerekir; açık kaynak (Space Grotesk) yedeği hazır tut.
- Cam efektleri eski cihazlarda performans düşürebilir; blur’u düşük değerle başlatın, tema ile aç/kapa flag’i.
- Kontrast/erişilebilirlik testini (WCAG) her yeni renk kombinasyonunda doğrulayın.

## 8) Son Uygulamalar (Kod)
- Bildirimler: NotificationService tz tabanl� g�nl�k planlama yap�yor; �al��ma plan� zili ve profil ekran�ndaki bildirim ayarlar� ayn� provider ile saat/a�-kapa y�netiyor (�ak��ma yok).
- �al��ma Plan� ekran�: Zil ikonu bildirim sheet�ini a��yor, plan ekran�ndan direkt saat ve toggle de�i�tirilebiliyor.
- Dashboard/AI Coach: Dashboard g�nl�k hedef kart� mavi-gri degrade ve beyaz metinle g�ncel; AI chat ekran� UTF-8 temiz, arka plan tam ekran ve klavye a��ld���nda k���lme yapm�yor.

