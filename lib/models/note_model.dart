class NoteModel {
  final String? id;
  final String text;
  final DateTime? reminderTime;
  final DateTime timestamp;
  final bool isSent;

  NoteModel({
    this.id,
    required this.text,
    this.reminderTime,
    required this.timestamp,
    this.isSent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'reminder_time': reminderTime?.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'isSent': isSent,
    };
  }

  factory NoteModel.fromMap(String id, Map<String, dynamic> map) {
    return NoteModel(
      id: id,
      text: map['text'] ?? '',
      reminderTime: map['reminder_time'] != null 
          ? DateTime.parse(map['reminder_time']) 
          : null,
      timestamp: DateTime.parse(map['timestamp'] as String? ?? ''),
      isSent: map['isSent'] ?? false,
    );
  }
}
