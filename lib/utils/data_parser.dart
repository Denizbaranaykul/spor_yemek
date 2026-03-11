import 'package:cloud_firestore/cloud_firestore.dart';

class DataParser {
  /// Safely parses a DateTime from dynamic input (String, Timestamp, or null).
  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is String) {
      if (value.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  /// Safely parses a double from dynamic input.
  static double parseDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  /// Safely parses an int from dynamic input.
  static int parseInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value.replaceAll(',', '.'))?.toInt() ?? fallback;
    }
    return fallback;
  }
}
