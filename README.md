# Spor Yemek

Sağlıklı yaşam için yemek ve antrenman takip uygulaması. AI destekli kalori hesaplama ve veri analizi özellikleri ile donatılmıştır.

## Özellikler

- 🔐 **Kimlik Doğrulama**: Firebase Authentication ile güvenli giriş/kayıt
- 🍽️ **AI Destekli Yemek Takibi**: Doğal dil ile yemek girişi ve otomatik kalori/makro hesaplama
- 💪 **Antrenman Kaydı**: Ağırlık ve hareket kayıtları
- 📊 **Veri Analizi**: Haftalık istatistikler ve görselleştirmeler
- 🤖 **AI Önerileri**: Kişiselleştirilmiş sağlık ve fitness önerileri
- 🌙 **Dark Mode**: Modern ve göz yormayan karanlık tema

## Teknoloji Yığını

- **Framework**: Flutter
- **Backend**: Firebase (Authentication, Firestore)
- **AI**: Google Gemini API
- **State Management**: Provider
- **UI**: Material 3

## Kurulum

Detaylı kurulum talimatları için [SETUP.md](SETUP.md) dosyasına bakın.

### Hızlı Başlangıç

1. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

2. **Firebase yapılandırması:**
   ```bash
   flutterfire configure
   ```

3. **AI API Key'i ayarlayın:**
   - `lib/services/ai_service.dart` dosyasındaki `_apiKey` değişkenini güncelleyin

4. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

## Proje Yapısı

```
lib/
├── models/          # Veri modelleri (Meal, Workout, UserProfile)
├── services/        # Firebase ve AI servisleri
├── providers/       # State management (Provider)
├── screens/         # UI ekranları
│   ├── auth/       # Giriş/Kayıt ekranları
│   └── home/       # Ana uygulama ekranları
└── theme/          # Tema ve renk tanımlamaları
```

## Kullanım

1. **Kayıt Ol / Giriş Yap**: İlk kullanımda hesap oluşturun
2. **Yemek Ekle**: Yediğiniz yemeği doğal dille yazın, AI analiz edip kalori/makro değerlerini hesaplasın
3. **Antrenman Kaydet**: Yaptığınız antrenmanları ve kaldırdığınız ağırlıkları kaydedin
4. **Analiz**: Haftalık verilerinizi görüntüleyin ve AI önerilerini alın
5. **Profil**: Kişisel bilgilerinizi güncelleyin

## Tasarım

- **Arkaplan**: #121212
- **Kartlar**: #1E1E1E
- **Primary Color**: #BB86FC (Vibrant Purple)
- **Secondary Color**: #03DAC6 (Teal)

## Lisans

Bu proje özel bir projedir.
