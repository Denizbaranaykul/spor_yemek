import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // 1. ADIM: Hazırladığın tüm keyleri bu listeye ekle
  final List<String> _apiKeys = [
    'AIzaSyAFiN654jghbisSM59GuPCRVI4yR3c4o5k', // Mevcut keyin
    'AIzaSyDqpz1qx5b9g478u14Lz_5UVvN7wnk0ACE',
    'AIzaSyDAQJFbWa3rj4V-xpw90NF_URHRE7yaxrY',
    'AIzaSyAI7mxmk0DPyPToI4S9yVQSzxHPCfKCPfA',
    'AIzaSyBXF-v1CP105vPtcMujjQifsloMXgs9yhw',
    'AIzaSyBYhvPWrH335_VxWXNkBo8NDptzOx6d4-Y',
    'AIzaSyBeAF5WmXHxf66porhgeOpPeGReAKJIFUQ',
  ];

  int _currentKeyIndex = 0;

  static const String _model = 'gemini-2.5-flash';
  
  // URL artık key'i içinde barındırmıyor, metot içinde ekliyoruz
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  String get _currentApiKey => _apiKeys[_currentKeyIndex];

  /// 429 hatalarında key değiştirir ve işlemi tekrar dener.
  Future<http.Response> _postWithRetryAndRotation(Map<String, dynamic> body) async {
    int attempts = 0;
    // Elimizdeki toplam key sayısı kadar deneme hakkı veriyoruz
    while (attempts < _apiKeys.length) {
      final Uri url = Uri.parse('$_geminiApiUrl?key=$_currentApiKey');
      
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15));

        // Eğer kota hatası (429) aldıysak key değiştir
        if (response.statusCode == 429) {
          print('⚠️ Key ${_currentKeyIndex + 1} limiti doldu. Sonraki keye geçiliyor...');
          _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
          attempts++;
          continue; // Döngü başına dön ve yeni key ile tekrar dene
        }

        return response; // Başarılıysa veya 429 dışı bir hataysa sonucu dön
      } catch (e) {
        if (attempts >= _apiKeys.length - 1) rethrow;
        _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
        attempts++;
      }
    }
    throw Exception('Tüm API anahtarlarının kotası doldu.');
  }

  Future<Map<String, dynamic>> analyzeFood(String foodDescription) async {
    try {
      final prompt = '''
Sen bir profesyonel beslenme uzmanısın. Kullanıcının girdiği yemeği şu algoritma ile analiz et:

1. ADIM (Porsiyon Analizi): Kullanıcı miktar belirtmemişse (ör: "bir baklava", "bir tabak makarna"), bu yemeğin dünyaca kabul görmüş ortalama porsiyon ağırlığını (gram cinsinden) belirle.
2. ADIM (Referans): Bu belirlenen gramajın besin değerlerini hesapla. Kesinlikle 100g verisini doğrudan döndürme; porsiyonun ağırlığına göre (örneğin 40g baklava için) matematiksel oranlama yap.
3. ADIM (Doğrulama): Kaloriyi (Protein*4 + Karb*4 + Yağ*9) formülüyle hesapla ve sonucu tam sayıya yuvarla.

Yemek: "$foodDescription"

SADECE aşağıdaki JSON formatında yanıt ver, başka hiçbir açıklama ekleme:
{
  "calories": sayi,
  "macros": {
    "protein": sayi,
    "carbs": sayi,
    "fat": sayi
  }
}
''';

      final body = {
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        }
      };

      final response = await _postWithRetryAndRotation(body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        print('📊 AI Yanıtı: $rawText');
        return jsonDecode(rawText) as Map<String, dynamic>;
      } else {
        print('❌ API Hata Detayı: ${response.body}');
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ AI Service Error: $e');
      rethrow;
    }
  }

  Future<String> generateRecommendation({
    required int weeklyCalories,
    required double weeklyProtein,
    required int weeklyWorkouts,
  }) async {
    try {
      final body = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
Bir fitness koçu gibi davran. Aşağıdaki verilere göre 12% yağ oranı hedefine uygun, 
kısa (max 2 cümle), motive edici ve Türkçe bir tavsiye ver:
- Haftalık Kalori: $weeklyCalories kcal
- Haftalık Protein: ${weeklyProtein.toStringAsFixed(1)}g
- Antrenman Sayısı: $weeklyWorkouts
'''
              }
            ]
          }
        ],
        'generationConfig': {'temperature': 0.7}
      };

      final response = await _postWithRetryAndRotation(body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'].trim();
      }
      return 'Harika ilerliyorsun, veri girişi yapmaya devam et!';
    } catch (e) {
      return 'Verileriniz şu an analiz edilemiyor, ancak pes etmeyin!';
    }
  }
}