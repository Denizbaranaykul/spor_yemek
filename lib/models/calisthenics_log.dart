class CalisthenicsLog {
  final String? id;
  final String exerciseName;
  final int reps; // Veya dakika da olabilir
  final DateTime timestamp;

  CalisthenicsLog({
    this.id,
    required this.exerciseName,
    required this.reps,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'exercise_name': exerciseName,
      'reps': reps,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalisthenicsLog.fromMap(String id, Map<String, dynamic> map) {
    return CalisthenicsLog(
      id: id,
      exerciseName: map['exercise_name'] ?? '',
      reps: map['reps']?.toInt() ?? 0,
      timestamp: DateTime.parse(map['timestamp'] as String? ?? ''),
    );
  }
}
