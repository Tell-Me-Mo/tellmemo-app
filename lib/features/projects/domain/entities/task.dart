enum TaskStatus {
  todo,
  inProgress,
  blocked,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class Task {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assignee;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final int progressPercentage;
  final String? blockerDescription;
  final String? questionToAsk;
  final bool aiGenerated;
  final double? aiConfidence;
  final String? sourceContentId;
  final String? dependsOnRiskId;
  final DateTime? createdDate;
  final DateTime? lastUpdated;
  final String? updatedBy;

  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assignee,
    this.dueDate,
    this.completedDate,
    this.progressPercentage = 0,
    this.blockerDescription,
    this.questionToAsk,
    this.aiGenerated = false,
    this.aiConfidence,
    this.sourceContentId,
    this.dependsOnRiskId,
    this.createdDate,
    this.lastUpdated,
    this.updatedBy,
  });

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assignee,
    DateTime? dueDate,
    DateTime? completedDate,
    int? progressPercentage,
    String? blockerDescription,
    String? questionToAsk,
    bool? aiGenerated,
    double? aiConfidence,
    String? sourceContentId,
    String? dependsOnRiskId,
    DateTime? createdDate,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      blockerDescription: blockerDescription ?? this.blockerDescription,
      questionToAsk: questionToAsk ?? this.questionToAsk,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      sourceContentId: sourceContentId ?? this.sourceContentId,
      dependsOnRiskId: dependsOnRiskId ?? this.dependsOnRiskId,
      createdDate: createdDate ?? this.createdDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task{id: $id, title: $title, status: $status, priority: $priority}';
  }

  // Helper methods
  bool get isCompleted => status == TaskStatus.completed;
  bool get isBlocked => status == TaskStatus.blocked;
  bool get isActive => status == TaskStatus.inProgress || status == TaskStatus.todo || status == TaskStatus.blocked;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
  bool get isHighPriority => priority == TaskPriority.urgent || priority == TaskPriority.high;

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  // Calculate progress based on status if not explicitly set
  int get effectiveProgress {
    if (progressPercentage > 0) return progressPercentage;
    switch (status) {
      case TaskStatus.todo:
        return 0;
      case TaskStatus.inProgress:
        return 50;
      case TaskStatus.blocked:
        return progressPercentage;
      case TaskStatus.completed:
        return 100;
      case TaskStatus.cancelled:
        return progressPercentage;
    }
  }
}