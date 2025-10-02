import 'package:intl/intl.dart';

class DateTimeUtils {
  static DateTime? parseUtcToLocal(String? dateTimeStr) {
    if (dateTimeStr == null) return null;
    try {
      final utcDateTime = DateTime.parse(dateTimeStr);
      return utcDateTime.toLocal();
    } catch (e) {
      return null;
    }
  }

  static DateTime parseUtcToLocalRequired(String dateTimeStr) {
    final utcDateTime = DateTime.parse(dateTimeStr);
    return utcDateTime.toLocal();
  }

  static String formatDate(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('MMM dd, yyyy').format(localDateTime);
  }

  static String formatTime(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('HH:mm').format(localDateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('MMM d, y • HH:mm').format(localDateTime);
  }

  static String formatDateTimeShort(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return DateFormat('MMM d, HH:mm').format(localDateTime);
  }

  static String formatTimeAgo(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(localDateTime);
    }
  }

  static String formatRelativeTime(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);

    if (targetDate == today) {
      return 'Today at ${formatTime(localDateTime)}';
    } else if (targetDate == yesterday) {
      return 'Yesterday at ${formatTime(localDateTime)}';
    } else if (now.difference(localDateTime).inDays < 7) {
      return '${now.difference(localDateTime).inDays}d ago at ${formatTime(localDateTime)}';
    } else {
      return '${formatDate(localDateTime)} at ${formatTime(localDateTime)}';
    }
  }

  static String toIsoString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  static DateTime ensureLocal(DateTime dateTime) {
    return dateTime.isUtc ? dateTime.toLocal() : dateTime;
  }
}