import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../projects/domain/entities/lesson_learned.dart';

class LessonUIHelpers {
  static Color getImpactColor(LessonImpact impact) {
    switch (impact) {
      case LessonImpact.high:
        return Colors.red;
      case LessonImpact.medium:
        return Colors.orange;
      case LessonImpact.low:
        return Colors.green;
    }
  }

  static Color getTypeColor(LessonType type) {
    switch (type) {
      case LessonType.success:
        return Colors.green;
      case LessonType.improvement:
        return Colors.blue;
      case LessonType.challenge:
        return Colors.orange;
      case LessonType.bestPractice:
        return Colors.amber;
    }
  }

  static IconData getCategoryIcon(LessonCategory category) {
    switch (category) {
      case LessonCategory.technical:
        return Icons.code;
      case LessonCategory.process:
        return Icons.account_tree;
      case LessonCategory.communication:
        return Icons.forum;
      case LessonCategory.planning:
        return Icons.calendar_today;
      case LessonCategory.resource:
        return Icons.people;
      case LessonCategory.quality:
        return Icons.verified;
      case LessonCategory.other:
        return Icons.category;
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  static String formatDateRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}