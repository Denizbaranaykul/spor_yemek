import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/meal.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final _foodController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _aiService = AIService();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }

  Future<void> _analyzeFood() async {
    if (_foodController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yemek açıklaması girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final result = await _aiService.analyzeFood(_foodController.text.trim());
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
      
      // Check if result is valid (not empty/zero values)
      if (result['calories'] == 0 && 
          result['macros']['protein'] == 0 &&
          result['macros']['carbs'] == 0 &&
          result['macros']['fat'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analiz sonucu alınamadı. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveMeal() async {
    if (_analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce yemeği analiz edin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final meal = Meal(
        foodName: _foodController.text.trim(),
        calories: _analysisResult!['calories'] ?? 0,
        macros: Map<String, dynamic>.from(_analysisResult!['macros'] ?? {}),
        timestamp: DateTime.now(),
      );

      await _firestoreService.addMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yemek kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        _foodController.clear();
        setState(() {
          _analysisResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yediğiniz yemeği açıklayın',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Örn: "2 dilim tam buğday ekmeği ve 3 yumurta"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _foodController,
                      decoration: const InputDecoration(
                        hintText: 'Yemek açıklaması...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeFood,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isAnalyzing ? 'Analiz ediliyor...' : 'AI ile Analiz Et'),
                    ),
                  ],
                ),
              ),
            ),
            if (_analysisResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analiz Sonucu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Kalori', '${_analysisResult!['calories']} kcal'),
                      const Divider(),
                      _buildInfoRow(
                        'Protein',
                        '${_analysisResult!['macros']['protein']}g',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Karbonhidrat',
                        '${_analysisResult!['macros']['carbs']}g',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Yağ',
                        '${_analysisResult!['macros']['fat']}g',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            StreamBuilder<List<Meal>>(
              stream: _firestoreService.getMeals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final meals = snapshot.data ?? [];

                if (meals.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Henüz yemek kaydı yok'),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Son Kayıtlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...meals.take(5).map((meal) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(meal.foodName),
                            subtitle: Text(
                              '${meal.calories} kcal • P: ${meal.macros['protein']}g • K: ${meal.macros['carbs']}g • Y: ${meal.macros['fat']}g',
                            ),
                            trailing: Text(
                              '${meal.timestamp.hour}:${meal.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}

