import 'package:freezed_annotation/freezed_annotation.dart';

/// Custom JSON converter for DateTime that handles various date formats from the backend
class DateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const DateTimeConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('Cannot convert null to DateTime');
    }

    final dateStr = json.toString();

    // If it's already a valid ISO format with timezone, parse directly
    if (dateStr.endsWith('Z') || dateStr.contains('+')) {
      return DateTime.parse(dateStr).toLocal();
    }

    // If it's date only (YYYY-MM-DD), treat as local date at start of day
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      // Parse as local date, not UTC
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]), // year
        int.parse(parts[1]), // month
        int.parse(parts[2]), // day
        0, 0, 0 // midnight in local time
      );
    }

    // If it's datetime without timezone, assume UTC and add Z
    if (dateStr.contains('T') && !dateStr.endsWith('Z')) {
      return DateTime.parse('${dateStr}Z').toLocal();
    }

    // Try parsing as-is and convert to local
    return DateTime.parse(dateStr).toLocal();
  }

  @override
  dynamic toJson(DateTime date) => date.toUtc().toIso8601String();
}

/// Nullable version of DateTimeConverter
class DateTimeConverterNullable implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverterNullable();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;

    final dateStr = json.toString();

    try {
      // If it's already a valid ISO format with timezone, parse directly
      if (dateStr.endsWith('Z') || dateStr.contains('+')) {
        return DateTime.parse(dateStr).toLocal();
      }

      // If it's date only (YYYY-MM-DD), treat as local date at start of day
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        // Parse as local date, not UTC
        final parts = dateStr.split('-');
        return DateTime(
          int.parse(parts[0]), // year
          int.parse(parts[1]), // month
          int.parse(parts[2]), // day
          0, 0, 0 // midnight in local time
        );
      }

      // If it's datetime without timezone, assume UTC and add Z
      if (dateStr.contains('T') && !dateStr.endsWith('Z')) {
        return DateTime.parse('${dateStr}Z').toLocal();
      }

      // Try parsing as-is and convert to local
      return DateTime.parse(dateStr).toLocal();
    } catch (e) {
      print('Failed to parse date: $dateStr - $e');
      return null;
    }
  }

  @override
  dynamic toJson(DateTime? date) => date?.toUtc().toIso8601String();
}