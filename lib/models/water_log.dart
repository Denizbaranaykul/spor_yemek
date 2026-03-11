import '../utils/data_parser.dart';

class WaterLog {
  final String? id;
  final int amount; // in ml
  final DateTime timestamp;

  WaterLog({
    this.id,
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WaterLog.fromMap(String id, Map<String, dynamic> map) {
    return WaterLog(
      id: id,
      amount: DataParser.parseInt(map['amount']),
      timestamp: DataParser.parseDateTime(map['timestamp']),
    );
  }
}
