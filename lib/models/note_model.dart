import '../utils/data_parser.dart';

class NoteModel {
  final String? id;
  final String text;
  final DateTime? reminderTime;
  final DateTime timestamp;
  final bool isSent;
  final List<int>? repeatDays; // 1 = Monday, 7 = Sunday

  NoteModel({
    this.id,
    required this.text,
    this.reminderTime,
    required this.timestamp,
    this.isSent = false,
    this.repeatDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'reminder_time': reminderTime?.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'isSent': isSent,
      if (repeatDays != null) 'repeatDays': repeatDays,
    };
  }

  factory NoteModel.fromMap(String id, Map<String, dynamic> map) {
    return NoteModel(
      id: id,
      text: map['text'] ?? '',
      reminderTime: map['reminder_time'] != null 
          ? DataParser.parseDateTime(map['reminder_time']) 
          : null,
      timestamp: DataParser.parseDateTime(map['timestamp']),
      isSent: map['isSent'] ?? false,
      repeatDays: map['repeatDays'] != null 
          ? List<int>.from(map['repeatDays']) 
          : null,
    );
  }
}
