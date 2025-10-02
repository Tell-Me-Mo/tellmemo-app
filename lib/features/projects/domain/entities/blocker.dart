enum BlockerImpact {
  low,
  medium,
  high,
  critical,
}

enum BlockerStatus {
  active,
  resolved,
  pending,
  escalated,
}

class Blocker {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final BlockerImpact impact;
  final BlockerStatus status;
  final String? resolution;
  final String? category;
  final String? owner;
  final String? dependencies;
  final DateTime? targetDate;
  final DateTime? resolvedDate;
  final DateTime? escalationDate;
  final bool aiGenerated;
  final double? aiConfidence;
  final String? sourceContentId;
  final String? assignedTo;
  final String? assignedToEmail;
  final DateTime? identifiedDate;
  final DateTime? lastUpdated;
  final String? updatedBy;

  const Blocker({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.impact,
    required this.status,
    this.resolution,
    this.category,
    this.owner,
    this.dependencies,
    this.targetDate,
    this.resolvedDate,
    this.escalationDate,
    this.aiGenerated = false,
    this.aiConfidence,
    this.sourceContentId,
    this.assignedTo,
    this.assignedToEmail,
    this.identifiedDate,
    this.lastUpdated,
    this.updatedBy,
  });

  Blocker copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    BlockerImpact? impact,
    BlockerStatus? status,
    String? resolution,
    String? category,
    String? owner,
    String? dependencies,
    DateTime? targetDate,
    DateTime? resolvedDate,
    DateTime? escalationDate,
    bool? aiGenerated,
    double? aiConfidence,
    String? sourceContentId,
    String? assignedTo,
    String? assignedToEmail,
    DateTime? identifiedDate,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return Blocker(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      impact: impact ?? this.impact,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      category: category ?? this.category,
      owner: owner ?? this.owner,
      dependencies: dependencies ?? this.dependencies,
      targetDate: targetDate ?? this.targetDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      escalationDate: escalationDate ?? this.escalationDate,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      sourceContentId: sourceContentId ?? this.sourceContentId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      identifiedDate: identifiedDate ?? this.identifiedDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Blocker && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Blocker{id: $id, title: $title, impact: $impact, status: $status}';
  }

  // Helper methods
  bool get isResolved => status == BlockerStatus.resolved;
  bool get isActive => status == BlockerStatus.active || status == BlockerStatus.escalated;
  bool get isPending => status == BlockerStatus.pending;
  bool get isHighPriority => impact == BlockerImpact.critical || impact == BlockerImpact.high;
  bool get needsEscalation => status == BlockerStatus.active && impact == BlockerImpact.critical;

  String get impactLabel {
    switch (impact) {
      case BlockerImpact.low:
        return 'Low';
      case BlockerImpact.medium:
        return 'Medium';
      case BlockerImpact.high:
        return 'High';
      case BlockerImpact.critical:
        return 'Critical';
    }
  }

  String get statusLabel {
    switch (status) {
      case BlockerStatus.active:
        return 'Active';
      case BlockerStatus.resolved:
        return 'Resolved';
      case BlockerStatus.pending:
        return 'Pending';
      case BlockerStatus.escalated:
        return 'Escalated';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'impact': impact.name,
      'status': status.name,
      'resolution': resolution,
      'category': category,
      'owner': owner,
      'dependencies': dependencies,
      'target_date': targetDate?.toIso8601String(),
      'resolved_date': resolvedDate?.toIso8601String(),
      'escalation_date': escalationDate?.toIso8601String(),
      'ai_generated': aiGenerated,
      'ai_confidence': aiConfidence,
      'source_content_id': sourceContentId,
      'assigned_to': assignedTo,
      'assigned_to_email': assignedToEmail,
      'identified_date': identifiedDate?.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  factory Blocker.fromJson(Map<String, dynamic> json) {
    return Blocker(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      impact: BlockerImpact.values.firstWhere(
        (e) => e.name == json['impact'],
        orElse: () => BlockerImpact.medium,
      ),
      status: BlockerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BlockerStatus.active,
      ),
      resolution: json['resolution'] as String?,
      category: json['category'] as String?,
      owner: json['owner'] as String?,
      dependencies: json['dependencies'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      resolvedDate: json['resolved_date'] != null
          ? DateTime.parse(json['resolved_date'] as String)
          : null,
      escalationDate: json['escalation_date'] != null
          ? DateTime.parse(json['escalation_date'] as String)
          : null,
      aiGenerated: json['ai_generated'] == true || json['ai_generated'] == 'true',
      aiConfidence: json['ai_confidence'] != null
          ? (json['ai_confidence'] as num).toDouble()
          : null,
      sourceContentId: json['source_content_id'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToEmail: json['assigned_to_email'] as String?,
      identifiedDate: json['identified_date'] != null
          ? DateTime.parse(json['identified_date'] as String)
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }
}