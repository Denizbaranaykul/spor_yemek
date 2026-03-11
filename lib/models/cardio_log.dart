import '../utils/data_parser.dart';

class CardioLog {
  final String? id;
  final int minutes;
  final DateTime timestamp;

  CardioLog({
    this.id,
    required this.minutes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'minutes': minutes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CardioLog.fromMap(String id, Map<String, dynamic> map) {
    return CardioLog(
      id: id,
      minutes: DataParser.parseInt(map['minutes']),
      timestamp: DataParser.parseDateTime(map['timestamp']),
    );
  }
}
