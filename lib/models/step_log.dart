import '../utils/data_parser.dart';

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
      steps: DataParser.parseInt(map['steps']),
      timestamp: DataParser.parseDateTime(map['timestamp']),
    );
  }
}
