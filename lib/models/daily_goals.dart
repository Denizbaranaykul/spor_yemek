class DailyGoals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  DailyGoals({
    this.calories = 2000,
    this.protein = 150,
    this.carbs = 250,
    this.fat = 65,
  });

  static double _toDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? fallback;
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory DailyGoals.fromMap(Map<String, dynamic>? map) {
    if (map == null) return DailyGoals();
    return DailyGoals(
      calories: _toDouble(map['calories'], 2000),
      protein: _toDouble(map['protein'], 150),
      carbs: _toDouble(map['carbs'], 250),
      fat: _toDouble(map['fat'], 65),
    );
  }
}
