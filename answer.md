eknik Yığın (Tech Stack)
Framework: Flutter

Backend/Database: Firebase (Auth, Firestore)

AI: Google Gemini API veya OpenAI API (Kalori hesaplama için)

State Management: Provider veya Bloc (Tercihen basitlik için Provider)

1. Tasarım ve Tema Kuralları
Tema: Tamamen Dark Mode.

Arkaplan: #121212

Kartlar/Yüzeyler: #1E1E1E

Ana Renk (Primary): #BB86FC (Vibrant Purple) veya #03DAC6 (Teal)

Navigasyon: Uygulama altında (Bottom Navigation Bar) 4 ana sekme bulunacaktır:

Yemek: AI destekli kalori girişi.

Spor: Antrenman ve ağırlık kaydı.

Analiz: Veri görselleştirme ve öneriler.

Profil: Kullanıcı bilgileri ve ayarlar.

2. Sayfa Detayları ve Fonksiyonlar
A. Kimlik Doğrulama (Auth)
Giriş/Kayıt Ekranları: Firebase Auth kullanılacak.

Giriş Kontrolü: Giriş yapmamış kullanıcılar doğrudan Login ekranına yönlendirilecek, ana sekmeleri göremeyecek.

B. Yemek Sekmesi (AI Destekli)
Input: Kullanıcının yediği yemeği doğal dille yazdığı bir Textfield (Örn: "2 dilim tam buğday ekmeği ve 3 yumurta").

AI Entegrasyonu: Yazılan metin bir API üzerinden LLM'e gönderilir. AI'dan dönen JSON (kalori, protein, karbonhidrat, yağ) ekranda gösterilir.

Kayıt: Onaylanan değerler Firebase Firestore'da users/{uid}/meals koleksiyonuna tarihle birlikte kaydedilir.

C. Spor Sekmesi
Input: Hareket adı (Dropdown veya Text) ve kaldırılan kilo (Number) girişi.

Kayıt: Veriler users/{uid}/workouts koleksiyonuna kaydedilir.

D. Analiz Sekmesi
Görselleştirme: Firebase'den çekilen yemek ve spor verileri listelenir.

AI Önerisi: Kullanıcının son 1 haftalık verileri analiz edilerek "Daha fazla protein almalısın" veya "Haftalık spor hedefine ulaştın" gibi otomatik öneriler sunulur.

E. Profil Sekmesi
Kullanıcı adı, e-posta, kilo/boy bilgileri ve çıkış yap (Logout) butonu.

3. Veri Yapısı (Firestore)
Plaintext

/users (collection)
  /{uid} (document)
    /meals (sub-collection)
      - food_name: String
      - calories: int
      - macros: Map
      - timestamp: DateTime
    /workouts (sub-collection)
      - exercise_name: String
      - weight: double
      - timestamp: DateTime
4. Cursor İçin Özel Talimatlar
Kodları modüler yaz (models, services, screens klasörleri oluştur).

UI için Material 3 kullan.

Hata yönetimi (error handling) ekle (Örn: API'den cevap gelmezse kullanıcıyı uyar).

BottomNavigationBar geçişlerinde IndexedStack kullanarak sayfa durumunu koru.