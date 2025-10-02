import 'package:flutter/material.dart';
import '../../../projects/domain/entities/task.dart';

class TaskUIHelpers {
  TaskUIHelpers._();

  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.yellow;
      case TaskPriority.low:
        return Colors.grey;
    }
  }

  static Color getStatusColor(TaskStatus status, ColorScheme colorScheme) {
    switch (status) {
      case TaskStatus.todo:
        return colorScheme.secondary;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.blocked:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.blocked:
        return Icons.block;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
      case TaskStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}