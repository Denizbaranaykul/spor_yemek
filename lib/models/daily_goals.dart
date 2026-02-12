class DailyGoals {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  DailyGoals({
    this.calories = 2000,
    this.protein = 150,
    this.carbs = 250,
    this.fat = 65,
  });

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
      calories: (map['calories'] ?? 2000).toInt(),
      protein: (map['protein'] ?? 150).toDouble(),
      carbs: (map['carbs'] ?? 250).toDouble(),
      fat: (map['fat'] ?? 65).toDouble(),
    );
  }
}
