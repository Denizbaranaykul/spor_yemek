class Workout {
  final String? id;
  final String exerciseName;
  final double weight;
  final DateTime timestamp;

  Workout({
    this.id,
    required this.exerciseName,
    required this.weight,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'exercise_name': exerciseName,
      'weight': weight,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Workout.fromMap(String id, Map<String, dynamic> map) {
    return Workout(
      id: id,
      exerciseName: map['exercise_name'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

