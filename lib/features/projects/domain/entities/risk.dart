enum RiskSeverity {
  low,
  medium,
  high,
  critical,
}

enum RiskStatus {
  identified,
  mitigating,
  resolved,
  accepted,
  escalated,
}

class Risk {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final RiskSeverity severity;
  final RiskStatus status;
  final String? mitigation;
  final String? impact;
  final double? probability;
  final bool aiGenerated;
  final double? aiConfidence;
  final String? sourceContentId;
  final DateTime? identifiedDate;
  final DateTime? resolvedDate;
  final DateTime? lastUpdated;
  final String? updatedBy;
  final String? assignedTo;
  final String? assignedToEmail;

  const Risk({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    this.mitigation,
    this.impact,
    this.probability,
    this.aiGenerated = false,
    this.aiConfidence,
    this.sourceContentId,
    this.identifiedDate,
    this.resolvedDate,
    this.lastUpdated,
    this.updatedBy,
    this.assignedTo,
    this.assignedToEmail,
  });

  Risk copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    RiskSeverity? severity,
    RiskStatus? status,
    String? mitigation,
    String? impact,
    double? probability,
    bool? aiGenerated,
    double? aiConfidence,
    String? sourceContentId,
    DateTime? identifiedDate,
    DateTime? resolvedDate,
    DateTime? lastUpdated,
    String? updatedBy,
    String? assignedTo,
    String? assignedToEmail,
  }) {
    return Risk(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      mitigation: mitigation ?? this.mitigation,
      impact: impact ?? this.impact,
      probability: probability ?? this.probability,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      sourceContentId: sourceContentId ?? this.sourceContentId,
      identifiedDate: identifiedDate ?? this.identifiedDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Risk && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Risk{id: $id, title: $title, severity: $severity, status: $status}';
  }

  // Helper methods
  bool get isResolved => status == RiskStatus.resolved;
  bool get isActive => status != RiskStatus.resolved && status != RiskStatus.accepted;
  bool get isHighPriority => severity == RiskSeverity.critical || severity == RiskSeverity.high;

  String get severityLabel {
    switch (severity) {
      case RiskSeverity.low:
        return 'Low';
      case RiskSeverity.medium:
        return 'Medium';
      case RiskSeverity.high:
        return 'High';
      case RiskSeverity.critical:
        return 'Critical';
    }
  }

  String get statusLabel {
    switch (status) {
      case RiskStatus.identified:
        return 'Identified';
      case RiskStatus.mitigating:
        return 'Mitigating';
      case RiskStatus.resolved:
        return 'Resolved';
      case RiskStatus.accepted:
        return 'Accepted';
      case RiskStatus.escalated:
        return 'Escalated';
    }
  }
}