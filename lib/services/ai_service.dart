import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  int _currentKeyIndex = 0;

  List<String> _getApiKeys() {
    final keyString = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (keyString.isEmpty) {
      return [];
    }
    // Anahtarları virgülle ayırıp boşlukları temizleyerek listeye çeviriyoruz
    return keyString.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
  }

  String _getCurrentKey(List<String> keys) {
    if (keys.isEmpty) return '';
    // Endeksi güvenli sınırlar içinde tutuyoruz
    if (_currentKeyIndex >= keys.length) {
      _currentKeyIndex = 0;
    }
    return keys[_currentKeyIndex];
  }

  void _rotateKey(List<String> keys) {
    if (keys.isNotEmpty) {
      _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;
      print('🔄 API Anahtarı değiştirildi. Yeni endeks: $_currentKeyIndex');
    }
  }

  /// Yemek Analizi: Gemini API'yi doğrudan çağırır. 
  /// 429 gibi hatalarda (veya diğer GenerativeAIException durumlarında) diğer anahtarlara geçer.
  Future<Map<String, dynamic>> analyzeFood(String foodDescription) async {
    final keys = _getApiKeys();
    if (keys.isEmpty) {
      throw Exception('GEMINI_API_KEY bulunamadı. Lütfen .env dosyanıza ekleyin.');
    }

    int attempts = 0;
    final maxAttempts = keys.length; // Her anahtarı bir kez deneyelim

    while (attempts < maxAttempts) {
      try {
        final currentKey = _getCurrentKey(keys);
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: currentKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final prompt = '''
Lütfen kullanıcının yediği şu yemeği analiz et: "$foodDescription"

Sadece ve sadece aşağıdaki formattaki bir JSON döndür. Başka hiçbir metin veya açıklama ekleme:
{
  "calories": Toplam kalori miktarı (sayı),
  "macros": {
    "protein": Protein miktarı gram (sayı),
    "carbs": Karbonhidrat miktarı gram (sayı),
    "fat": Yağ miktarı gram (sayı)
  }
}
Birimleri yazma, sadece sayı değerlerini gir. Eğer tam emin değilsen mantıklı ortalama değerler kullan.
''';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        final responseText = response.text;

        if (responseText == null || responseText.isEmpty) {
          throw Exception('Gemini API boş yanıt döndürdü.');
        }

        // Her ihtimale karşı markdown formatı (```json ... ```) kaldıralım
        String cleanedText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

        final Map<String, dynamic> decodedData = jsonDecode(cleanedText);
        print('📊 AI Analiz Sonucu: $decodedData');
        return decodedData;
      } on GenerativeAIException catch (e) {
        print('⚠️ GenerativeAIException Hatası (analyzeFood): $e');
        // Özellikle ResourceExhausted (429) yakalamak için veya genel bir kısıtlama hatasında rotasyon yap.
        if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota') || e.toString().toLowerCase().contains('exhausted')) {
          attempts++;
          if (attempts < maxAttempts) {
             print('⏳ 429 / Quota Hatası alındı. Başka bir API anahtarına geçiliyor...');
            _rotateKey(keys);
          } else {
             throw Exception('Tüm API anahtarlarının limiti doldu (429). Lütfen daha sonra tekrar deneyin.');
          }
        } else {
           // 429 dışı bir API hatasıysa direkt fırlat
           rethrow;
        }
      } catch (e) {
        print('⚠️ AI Service Hatası (analyzeFood): $e');
        rethrow;
      }
    }
    
    throw Exception('Analiz işlemi başarısız oldu.');
  }

  /// Tavsiye Oluşturma: Gemini kullanarak genel bir sağlık / diyet tavsiyesi verir.
  Future<String> generateRecommendation({
    required int weeklyCalories,
    required double weeklyProtein,
    required int weeklyWorkouts,
  }) async {
    final keys = _getApiKeys();
    if (keys.isEmpty) {
      return 'Tavsiye oluşturulamadı: GEMINI_API_KEY bulunamadı.';
    }

    int attempts = 0;
    final maxAttempts = keys.length;

    while (attempts < maxAttempts) {
      try {
        final currentKey = _getCurrentKey(keys);
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: currentKey,
        );

        final prompt = '''
Kullanıcının bu haftaki spor ve beslenme gelişimi şu şekilde:
- Alınan Toplam Kalori: $weeklyCalories kcal
- Alınan Toplam Protein: $weeklyProtein g
- Haftalık Antrenman Sayısı: $weeklyWorkouts

Bu verileri göz önünde bulundurarak, samimi, kısa, motive edici ve yapıcı bir spor/diyet tavsiyesi ver (maksimum 2 cümle).
''';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!.trim();
        }
        
        return 'Harika ilerliyorsun, hedeflerine odaklanmaya devam et!';
      } on GenerativeAIException catch (e) {
        print('⚠️ GenerativeAIException (generateRecommendation): $e');
        if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota') || e.toString().toLowerCase().contains('exhausted')) {
          attempts++;
          if (attempts < maxAttempts) {
             print('⏳ 429 / Quota Hatası alındı. Başka bir API anahtarına geçiliyor...');
            _rotateKey(keys);
          } else {
             return 'Sistem şu an yoğun (Tüm API limitleri dolu), daha sonra tekrar deneyin.';
          }
        } else {
           return 'Verileriniz değerlendirilemedi, lütfen tekrar deneyin.';
        }
      } catch (e) {
        print('⚠️ Tavsiye fonksiyonu genel hatası: $e');
        return 'Verileriniz değerlendiriliyor, motivasyonunu koru!';
      }
    }
    return 'Harika ilerliyorsun, hedeflerine odaklanmaya devam et!';
  }
}