import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/daily_goals.dart';
import '../../models/meal.dart';
import '../../models/workout.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _firestoreService = FirestoreService();
  DailyGoals _goals = DailyGoals();
  bool _goalsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _firestoreService.getDailyGoals();
    if (mounted) {
      setState(() {
        _goals = goals;
        _goalsLoaded = true;
      });
    }
  }

  Future<void> _showEditGoalsDialog() async {
    final calController = TextEditingController(
      text: _goals.calories.truncateToDouble() == _goals.calories
          ? _goals.calories.toInt().toString()
          : _goals.calories.toString(),
    );
    final proController = TextEditingController(text: _goals.protein.toStringAsFixed(0));
    final carbController = TextEditingController(text: _goals.carbs.toStringAsFixed(0));
    final fatController = TextEditingController(text: _goals.fat.toStringAsFixed(0));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Besin Hedefleri'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalori (kcal)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: proController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: carbController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Karbonhidrat (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yağ (g)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == true) {
      final goals = DailyGoals(
        calories: double.tryParse(calController.text.replaceAll(',', '.')) ?? _goals.calories,
        protein: double.tryParse(proController.text.replaceAll(',', '.')) ?? _goals.protein,
        carbs: double.tryParse(carbController.text.replaceAll(',', '.')) ?? _goals.carbs,
        fat: double.tryParse(fatController.text.replaceAll(',', '.')) ?? _goals.fat,
      );
      await _firestoreService.saveDailyGoals(goals);
      if (mounted) {
        setState(() => _goals = goals);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hedefler kaydedildi!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz'),
      ),
      body: StreamBuilder<List<Meal>>(
        stream: _firestoreService.getMeals(),
        builder: (context, mealsSnapshot) {
          return StreamBuilder<List<Workout>>(
            stream: _firestoreService.getWorkouts(),
            builder: (context, workoutsSnapshot) {
              if (!mealsSnapshot.hasData || !workoutsSnapshot.hasData || !_goalsLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final meals = mealsSnapshot.data ?? [];
              final workouts = workoutsSnapshot.data ?? [];
              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final todayEnd = todayStart.add(const Duration(days: 1));

              // Bugünkü tüketim
              final todayMeals = meals.where((m) =>
                  m.timestamp.isAfter(todayStart) && m.timestamp.isBefore(todayEnd)).toList();
              final consumedCal = todayMeals.fold<double>(0, (s, m) => s + m.calories);
              final consumedPro = todayMeals.fold<double>(
                  0, (s, m) => s + (m.macros['protein']?.toDouble() ?? 0));
              final consumedCarb = todayMeals.fold<double>(
                  0, (s, m) => s + (m.macros['carbs']?.toDouble() ?? 0));
              final consumedFat = todayMeals.fold<double>(
                  0, (s, m) => s + (m.macros['fat']?.toDouble() ?? 0));

              final uniqueExercises = workouts
                  .map((w) => w.exerciseName)
                  .where((n) => n.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Spor hareketi gelişim grafiği
                    _ExerciseProgressChart(
                      workouts: workouts,
                      exerciseNames: uniqueExercises,
                    ),
                    const SizedBox(height: 24),
                    // Günlük hedef kalan
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Bugünkü Hedef Kalan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: _showEditGoalsDialog,
                                  tooltip: 'Hedefleri düzenle',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _RemainingRow(
                              label: 'Kalori',
                              unit: 'kcal',
                              target: _goals.calories,
                              consumed: consumedCal,
                            ),
                            const Divider(),
                            _RemainingRow(
                              label: 'Protein',
                              unit: 'g',
                              target: _goals.protein,
                              consumed: consumedPro,
                            ),
                            const Divider(),
                            _RemainingRow(
                              label: 'Karbonhidrat',
                              unit: 'g',
                              target: _goals.carbs,
                              consumed: consumedCarb,
                            ),
                            const Divider(),
                            _RemainingRow(
                              label: 'Yağ',
                              unit: 'g',
                              target: _goals.fat,
                              consumed: consumedFat,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExerciseProgressChart extends StatefulWidget {
  final List<Workout> workouts;
  final List<String> exerciseNames;

  const _ExerciseProgressChart({
    required this.workouts,
    required this.exerciseNames,
  });

  @override
  State<_ExerciseProgressChart> createState() => _ExerciseProgressChartState();
}

class _ExerciseProgressChartState extends State<_ExerciseProgressChart> {
  String? _selectedExercise;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseNames.isNotEmpty && _selectedExercise == null) {
      _selectedExercise = widget.exerciseNames.first;
    }
  }

  @override
  void didUpdateWidget(covariant _ExerciseProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedExercise == null && widget.exerciseNames.isNotEmpty) {
      _selectedExercise = widget.exerciseNames.first;
    }
    if (_selectedExercise != null && !widget.exerciseNames.contains(_selectedExercise)) {
      _selectedExercise = widget.exerciseNames.isNotEmpty ? widget.exerciseNames.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exerciseNames.isEmpty) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Gelişim grafiği için antrenman ekleyin',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final filtered = widget.workouts
        .where((w) => w.exerciseName == _selectedExercise)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spor Hareketi Gelişim Grafiği',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedExercise,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.exerciseNames
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedExercise = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: _buildLineChart(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Workout> workouts) {
    if (workouts.isEmpty) {
      return const Center(
        child: Text('Bu hareket için veri yok', style: TextStyle(color: Colors.grey)),
      );
    }

    final spots = workouts.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final maxY = workouts.map((w) => w.weight).reduce((a, b) => a > b ? a : b);
    final minY = workouts.map((w) => w.weight).reduce((a, b) => a < b ? a : b);
    final padding = (maxY - minY) * 0.2;
    final chartMinY = (minY - padding).clamp(0.0, double.infinity).toDouble();
    final chartMaxY = (maxY + padding).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (workouts.length - 1).toDouble(),
        minY: chartMinY,
        maxY: chartMaxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final w = workouts[s.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('dd/MM').format(w.timestamp)}\n${w.weight} kg',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < workouts.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(workouts[i].timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingRow extends StatelessWidget {
  final String label;
  final String unit;
  final double target;
  final double consumed;

  const _RemainingRow({
    required this.label,
    required this.unit,
    required this.target,
    required this.consumed,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (target - consumed).clamp(0.0, double.infinity);
    final isOver = consumed > target;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            Text(
              consumed.toStringAsFixed(consumed == consumed.truncateToDouble() ? 0 : 1),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const Text(' / ', style: TextStyle(color: Colors.grey)),
            Text(
              target.toStringAsFixed(target == target.truncateToDouble() ? 0 : 1),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(' $unit  →  ', style: const TextStyle(color: Colors.grey)),
            Text(
              isOver ? 'Hedef aşıldı' : '${remaining.toStringAsFixed(remaining == remaining.truncateToDouble() ? 0 : 1)} $unit kaldı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isOver ? Colors.orange : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
