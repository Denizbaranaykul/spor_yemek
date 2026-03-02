import 'package:flutter/material.dart';

import '../../models/meal.dart';
import '../../models/water_log.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

double _numToDouble(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return double.tryParse(v.toString()) ?? 0;
}

String _formatNum(double v) =>
    v.truncateToDouble() == v ? v.toInt().toString() : v.toStringAsFixed(1);

class _FoodScreenState extends State<FoodScreen> {
  final _foodController = TextEditingController();
  final _manualFoodController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _waterController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _aiService = AIService();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  bool _isAiMode = true;

  @override
  void dispose() {
    _foodController.dispose();
    _manualFoodController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _saveWater() async {
    if (_waterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen su miktarını girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final amount = int.tryParse(_waterController.text.trim()) ?? 0;
      if (amount <= 0) {
        throw Exception('Geçerli bir miktar girin');
      }

      final waterLog = WaterLog(
        amount: amount,
        timestamp: DateTime.now(),
      );

      await _firestoreService.addWaterLog(waterLog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Su tüketimi kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        _waterController.clear();
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
      final c = _numToDouble(result['calories']);
      final m = result['macros'] as Map? ?? {};
      if (c == 0 &&
          _numToDouble(m['protein']) == 0 &&
          _numToDouble(m['carbs']) == 0 &&
          _numToDouble(m['fat']) == 0) {
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

  Future<void> _saveManualMeal() async {
    if (_manualFoodController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yemek adı girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final meal = Meal(
        foodName: _manualFoodController.text.trim(),
        calories: _numToDouble(_caloriesController.text.replaceAll(',', '.')),
        macros: {
          'protein': _numToDouble(_proteinController.text.replaceAll(',', '.')),
          'carbs': _numToDouble(_carbsController.text.replaceAll(',', '.')),
          'fat': _numToDouble(_fatController.text.replaceAll(',', '.')),
        },
        timestamp: DateTime.now(),
      );

      await _firestoreService.addMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yemek manuel olarak kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        _manualFoodController.clear();
        _caloriesController.clear();
        _proteinController.clear();
        _carbsController.clear();
        _fatController.clear();
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
      final rawMacros = _analysisResult!['macros'] as Map? ?? {};
      final macros = rawMacros.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), _numToDouble(v)),
      );
      final meal = Meal(
        foodName: _foodController.text.trim(),
        calories: _numToDouble(_analysisResult!['calories']),
        macros: macros,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [SizedBox(height: 40), ...analysResult],
        ),
      ),
    );
  }

  List<Widget> get analysResult {
    return [
          if (_isAiMode) analysCard() else manualEntryCard(),
          if (_isAiMode && _analysisResult != null) ...[
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
                    _buildInfoRow(
                      'Kalori',
                      '${_formatNum(_numToDouble(_analysisResult!['calories']))} kcal',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Protein',
                      '${_formatNum(_numToDouble(_analysisResult!['macros']?['protein']))}g',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Karbonhidrat',
                      '${_formatNum(_numToDouble(_analysisResult!['macros']?['carbs']))}g',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Yağ',
                      '${_formatNum(_numToDouble(_analysisResult!['macros']?['fat']))}g',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          _buildWaterCard(),
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
                            '${_formatNum(meal.calories)} kcal • P: ${_formatNum((meal.macros['protein'] as num?)?.toDouble() ?? 0)}g • K: ${_formatNum((meal.macros['carbs'] as num?)?.toDouble() ?? 0)}g • Y: ${_formatNum((meal.macros['fat'] as num?)?.toDouble() ?? 0)}g',
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
        ];
  }

  SegmentedButton<bool> manual_or_ai() {
    return SegmentedButton<bool>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color.fromARGB(255, 205, 182, 8);
                  }
                  return Colors.transparent;
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.black;
                  }
                  return const Color.fromARGB(255, 195, 198, 22);
                },
              ),
            ),
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('Otomatik'),
                icon: Icon(Icons.auto_awesome),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('Manuel'),
                icon: Icon(Icons.edit),
              ),
            ],
            selected: {_isAiMode},
            onSelectionChanged: (newSelection) {
              setState(() {
                _isAiMode = newSelection.first;
              });
            },
          );
  }

  Card _buildWaterCard() {
    return Card(
      color: AppTheme.secondaryColor.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: AppTheme.secondaryColor), 
                const SizedBox(width: 8),
                const Text(
                  'Su Tüketimi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _waterController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Miktar (ml)',
                      border: OutlineInputBorder(),
                      suffixText: 'ml',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveWater,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Card manualEntryCard() {
    return Card(
      color: Colors.amber.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: manual_or_ai()),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text(
                  'Manuel Olarak Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualFoodController,
            decoration: const InputDecoration(
              labelText: 'Yemek Adı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Kalori (kcal)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _carbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Karb. (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Yağ (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveManualMeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        ),
      ),
    );
  }

  Card analysCard() {
    return Card(
      color: Colors.amber.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: manual_or_ai()),
            const SizedBox(height: 24),
            Row(
              children: [                  
                const Icon(Icons.restaurant_menu, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text(
                  'Yediğiniz yemeği açıklayın',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: _isAnalyzing ? null : _analyzeFood,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isAnalyzing ? 'Analiz ediliyor...' : 'Otomatik Analiz Et', style: const TextStyle(fontWeight: FontWeight.bold)),
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

