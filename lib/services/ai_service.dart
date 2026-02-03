import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // API Anahtarını buraya yapıştır
  static const String _apiKey = 'AIzaSyB8iKK69PAAGdTikqzXG1qb9cpPkjZzZ7I';
  
  // En güncel ve hata payı en düşük endpoint yapısı
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Kullanıcının girdiği yemek açıklamasını analiz eder ve besin değerlerini döner.
  Future<Map<String, dynamic>> analyzeFood(String foodDescription) async {
    try {
      final prompt = '''
Aşağıdaki yemek açıklamasını analiz et ve SADECE saf bir JSON objesi döndür. 
Markdown formatı (```json gibi) kullanma.
Beklenen JSON Yapısı:
{
  "calories": sayi,
  "macros": {
    "protein": sayi,
    "carbs": sayi,
    "fat": sayi
  }
}

Analiz edilecek yemek: "$foodDescription"
''';

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.1, // Daha kesin ve teknik yanıtlar için
            'topK': 1,
            'topP': 1,
          }
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Yanıtın içindeki text kısmını al
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Model bazen her şeye rağmen markdown tırnakları ekleyebilir, temizleyelim
        rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        
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

  /// Haftalık verilere dayanarak kullanıcıya Türkçe tavsiye verir.
  Future<String> generateRecommendation({
    required int weeklyCalories,
    required double weeklyProtein,
    required int weeklyWorkouts,
  }) async {
    try {
      final prompt = '''
Bir fitness koçu gibi davran. Aşağıdaki haftalık verilere göre kısa (max 2 cümle), 
motive edici ve Türkçe bir tavsiye ver:
- Toplam Kalori: $weeklyCalories kcal
- Toplam Protein: ${weeklyProtein.toStringAsFixed(1)}g
- Yapılan Spor Sayısı: $weeklyWorkouts
''';

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ]
        }),
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