import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/meal.dart';
import '../../models/workout.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _firestoreService = FirestoreService();
  final _aiService = AIService();
  String? _recommendation;
  bool _isLoadingRecommendation = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    setState(() {
      _isLoadingRecommendation = true;
    });

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final meals = await _firestoreService.getMealsByDateRange(weekAgo, now);
      final workouts = await _firestoreService.getWorkoutsByDateRange(
        weekAgo,
        now,
      );

      int totalCalories = meals.fold(0, (sum, meal) => sum + meal.calories);
      double totalProtein = meals.fold(
        0.0,
        (sum, meal) => sum + (meal.macros['protein']?.toDouble() ?? 0.0),
      );

      final recommendation = await _aiService.generateRecommendation(
        weeklyCalories: totalCalories,
        weeklyProtein: totalProtein,
        weeklyWorkouts: workouts.length,
      );

      if (mounted) {
        setState(() {
          _recommendation = recommendation;
          _isLoadingRecommendation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecommendation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Recommendation Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'AI Önerisi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingRecommendation)
                      const Center(child: CircularProgressIndicator())
                    else if (_recommendation != null)
                      Text(
                        _recommendation!,
                        style: const TextStyle(fontSize: 14),
                      )
                    else
                      const Text('Veri yükleniyor...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Weekly Stats
            StreamBuilder<List<Meal>>(
              stream: _firestoreService.getMeals(),
              builder: (context, mealsSnapshot) {
                return StreamBuilder<List<Workout>>(
                  stream: _firestoreService.getWorkouts(),
                  builder: (context, workoutsSnapshot) {
                    if (!mealsSnapshot.hasData || !workoutsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final meals = mealsSnapshot.data ?? [];
                    final workouts = workoutsSnapshot.data ?? [];

                    final now = DateTime.now();
                    final weekAgo = now.subtract(const Duration(days: 7));

                    final weeklyMeals = meals.where((meal) {
                      return meal.timestamp.isAfter(weekAgo);
                    }).toList();

                    final weeklyWorkouts = workouts.where((workout) {
                      return workout.timestamp.isAfter(weekAgo);
                    }).toList();

                    int totalCalories = weeklyMeals.fold(
                      0,
                      (sum, meal) => sum + meal.calories,
                    );
                    double totalProtein = weeklyMeals.fold(
                      0.0,
                      (sum, meal) =>
                          sum + (meal.macros['protein']?.toDouble() ?? 0.0),
                    );
                    double totalCarbs = weeklyMeals.fold(
                      0.0,
                      (sum, meal) =>
                          sum + (meal.macros['carbs']?.toDouble() ?? 0.0),
                    );
                    double totalFat = weeklyMeals.fold(
                      0.0,
                      (sum, meal) =>
                          sum + (meal.macros['fat']?.toDouble() ?? 0.0),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Haftalık İstatistikler',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildStatRow('Toplam Kalori', '$totalCalories kcal'),
                                const Divider(),
                                _buildStatRow('Toplam Protein', '${totalProtein.toStringAsFixed(1)}g'),
                                const Divider(),
                                _buildStatRow('Toplam Karbonhidrat', '${totalCarbs.toStringAsFixed(1)}g'),
                                const Divider(),
                                _buildStatRow('Toplam Yağ', '${totalFat.toStringAsFixed(1)}g'),
                                const Divider(),
                                _buildStatRow('Antrenman Sayısı', '${weeklyWorkouts.length}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Calories Chart
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Günlük Kalori Dağılımı',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _buildCaloriesChart(weeklyMeals),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
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

  Widget _buildCaloriesChart(List<Meal> meals) {
    if (meals.isEmpty) {
      return const Center(
        child: Text('Veri yok'),
      );
    }

    // Group meals by date
    final Map<String, int> dailyCalories = {};
    for (final meal in meals) {
      final dateKey = DateFormat('dd/MM').format(meal.timestamp);
      dailyCalories[dateKey] =
          (dailyCalories[dateKey] ?? 0) + meal.calories;
    }

    final entries = dailyCalories.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const Center(child: Text('Veri yok'));
    }

    final maxCalories = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCalories * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.surfaceColor,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      entries[value.toInt()].key,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value.toDouble(),
                color: AppTheme.primaryColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

