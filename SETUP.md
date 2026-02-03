# Kurulum Talimatları

## 1. Firebase Yapılandırması

### Adımlar:
1. Firebase Console'a gidin: https://console.firebase.google.com/
2. Yeni bir proje oluşturun veya mevcut projeyi seçin
3. Flutter uygulamanızı Firebase projesine ekleyin
4. Firebase CLI'yi yükleyin:
   ```bash
   npm install -g firebase-tools
   ```
5. FlutterFire CLI'yi yükleyin:
   ```bash
   dart pub global activate flutterfire_cli
   ```
6. Firebase yapılandırmasını oluşturun:
   ```bash
   flutterfire configure
   ```
   Bu komut `lib/firebase_options.dart` dosyasını oluşturacaktır.

### Firebase Servislerini Etkinleştirin:
- **Authentication**: Email/Password authentication'ı etkinleştirin
- **Firestore Database**: Firestore Database'i oluşturun (test mode'da başlayabilirsiniz)

## 2. AI API Key Yapılandırması

### Google Gemini API:
1. Google AI Studio'ya gidin: https://makersuite.google.com/app/apikey
2. Yeni bir API key oluşturun
3. `lib/services/ai_service.dart` dosyasındaki `_apiKey` değişkenini güncelleyin:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```

### Alternatif: OpenAI API:
Eğer OpenAI kullanmak isterseniz, `ai_service.dart` dosyasını OpenAI API'ye göre güncelleyin.

## 3. Paketleri Yükleyin

```bash
flutter pub get
```

## 4. Uygulamayı Çalıştırın

```bash
flutter run
```

## Notlar

- Firebase yapılandırması yapılmadan uygulama çalışmayacaktır
- AI API key olmadan yemek analizi özelliği çalışmayacaktır (fallback değerler dönecektir)
- İlk çalıştırmada Firebase başlatma hatası alırsanız, `firebase_options.dart` dosyasının oluşturulduğundan emin olun

