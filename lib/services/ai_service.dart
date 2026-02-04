import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // API Anahtarı (Güvenlik için bu anahtarı daha sonra .env dosyasına taşıman önerilir)
  static const String _apiKey = 'AIzaSyB8iKK69PAAGdTikqzXG1qb9cpPkjZzZ7I';

  // Free tier'da en yüksek kota: 15 RPM, 1000 RPD
  static const String _model = 'gemini-2.5-flash-lite';
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// 429 (quota) hatalarında belirtilen süre kadar bekleyip tekrar dener.
  Future<http.Response> _postWithRetry(Uri url, Map<String, dynamic> body) async {
    const maxRetries = 2;
    for (var i = 0; i <= maxRetries; i++) {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 429 || i == maxRetries) return response;

      // Retry-After veya mesajdaki süreyi parse et (ör: "retry in 52.02s")
      final bodyStr = response.body;
      final retryMatch = RegExp(r'retry in ([\d.]+)s', caseSensitive: false).firstMatch(bodyStr);
      final waitSeconds = retryMatch != null
          ? (double.tryParse(retryMatch.group(1)!) ?? 60).ceil().clamp(5, 90)
          : 60;

      print('⏳ Kota aşıldı, ${waitSeconds}s sonra tekrar deneniyor...');
      await Future<void>.delayed(Duration(seconds: waitSeconds));
    }
    throw StateError('Unreachable');
  }

  /// Yemek açıklamasını analiz eder ve doğrudan JSON objesi döner.
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
      final response = await _postWithRetry(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // responseMimeType kullandığı için rawText doğrudan geçerli bir JSON stringidir
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

  /// Haftalık verilere göre Türkçe tavsiye verir.
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
      final response = await _postWithRetry(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        body,
      );

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