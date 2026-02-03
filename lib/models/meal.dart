class Meal {
  final String? id;
  final String foodName;
  final int calories;
  final Map<String, dynamic> macros; // protein, carbs, fat
  final DateTime timestamp;

  Meal({
    this.id,
    required this.foodName,
    required this.calories,
    required this.macros,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'food_name': foodName,
      'calories': calories,
      'macros': macros,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Meal.fromMap(String id, Map<String, dynamic> map) {
    return Meal(
      id: id,
      foodName: map['food_name'] ?? '',
      calories: map['calories'] ?? 0,
      macros: Map<String, dynamic>.from(map['macros'] ?? {}),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

