class Meal {
  final String? id;
  final String foodName;
  final double calories;
  final Map<String, dynamic> macros; // protein, carbs, fat (değerler double)
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

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  factory Meal.fromMap(String id, Map<String, dynamic> map) {
    final rawMacros = map['macros'];
    Map<String, dynamic> macrosMap = {};
    if (rawMacros is Map) {
      for (final e in rawMacros.entries) {
        macrosMap[e.key.toString()] = _toDouble(e.value);
      }
    }
    return Meal(
      id: id,
      foodName: map['food_name'] ?? '',
      calories: _toDouble(map['calories']),
      macros: macrosMap,
      timestamp: DateTime.parse(map['timestamp'] as String? ?? ''),
    );
  }
}

