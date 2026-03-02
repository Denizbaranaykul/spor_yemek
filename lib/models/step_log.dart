class StepLog {
  final String? id;
  final int steps;
  final DateTime timestamp;

  StepLog({
    this.id,
    required this.steps,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'steps': steps,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StepLog.fromMap(String id, Map<String, dynamic> map) {
    return StepLog(
      id: id,
      steps: map['steps'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
