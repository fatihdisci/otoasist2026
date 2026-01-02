# Oto Asist 2026

Araç bakım ve takip uygulaması - Flutter ile geliştirilmiş modern mobil uygulama.

## Özellikler

- 🚗 **Araç Yönetimi**: Araç ekleme, düzenleme ve takip
- 📊 **Bakım Takibi**: KM bazlı ve tarih bazlı bakım hatırlatmaları
- 🤖 **AI Ekspertiz**: Google Gemini AI ile araç analizi ve risk değerlendirmesi
- 📝 **Servis Kayıtları**: Periyodik bakım ve onarım kayıtları
- 🔔 **Bildirimler**: Bakım hatırlatmaları ve kritik uyarılar
- 💾 **Firebase Entegrasyonu**: Güvenli veri saklama ve senkronizasyon

## Kurulum

### Gereksinimler

- Flutter SDK (>=3.0.0)
- Firebase projesi
- Google Gemini API anahtarı

### Adımlar

1. **Repository'yi klonlayın**
   ```bash
   git clone <repository-url>
   cd otoasist2026-1
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Environment variables ayarlayın**
   - `.env.example` dosyasını kopyalayıp `.env` olarak kaydedin
   - Google Gemini API anahtarınızı ekleyin:
     ```
     GEMINI_API_KEY=your_api_key_here
     ```

4. **Firebase yapılandırması**
   - Firebase projenizi oluşturun
   - `flutterfire configure` komutu ile yapılandırın
   - Android/iOS için gerekli dosyaları ekleyin

5. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

## Proje Yapısı

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── firebase_options.dart        # Firebase konfigürasyonu
├── core/
│   └── extensions/             # Enum label'ları
├── features/
│   ├── garage/                 # Ana garaj ekranı
│   ├── advisor/                 # AI ekspertiz
│   ├── onboarding/             # Araç ekleme wizard
│   └── service_logs/           # Servis kayıtları
└── integrations/
    ├── ai_service.dart          # AI servis entegrasyonu
    └── notification_service.dart # Bildirim servisi
```

## Test

Unit testleri çalıştırmak için:

```bash
flutter test
```

## Güvenlik

- API anahtarları `.env` dosyasında saklanır
- `.env` dosyası `.gitignore`'da bulunur
- Firebase Security Rules ile veri güvenliği sağlanır

## Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## Lisans

Bu proje özel bir projedir.
