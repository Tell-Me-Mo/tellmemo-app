import '../../domain/entities/blocker.dart';

class BlockerModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String impact;
  final String status;
  final String? resolution;
  final String? category;
  final String? owner;
  final String? dependencies;
  final String? targetDate;
  final String? resolvedDate;
  final String? escalationDate;
  final dynamic aiGenerated;
  final double? aiConfidence;
  final String? sourceContentId;
  final String? assignedTo;
  final String? assignedToEmail;
  final String? identifiedDate;
  final String? lastUpdated;
  final String? updatedBy;

  BlockerModel({
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
    this.aiGenerated,
    this.aiConfidence,
    this.sourceContentId,
    this.assignedTo,
    this.assignedToEmail,
    this.identifiedDate,
    this.lastUpdated,
    this.updatedBy,
  });

  factory BlockerModel.fromJson(Map<String, dynamic> json) {
    return BlockerModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      impact: json['impact'] as String,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      category: json['category'] as String?,
      owner: json['owner'] as String?,
      dependencies: json['dependencies'] as String?,
      targetDate: json['target_date'] as String?,
      resolvedDate: json['resolved_date'] as String?,
      escalationDate: json['escalation_date'] as String?,
      aiGenerated: json['ai_generated'],
      aiConfidence: json['ai_confidence'] != null
          ? (json['ai_confidence'] as num).toDouble()
          : null,
      sourceContentId: json['source_content_id'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToEmail: json['assigned_to_email'] as String?,
      identifiedDate: json['identified_date'] as String?,
      lastUpdated: json['last_updated'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'impact': impact,
      'status': status,
      'resolution': resolution,
      'category': category,
      'owner': owner,
      'dependencies': dependencies,
      'target_date': targetDate,
      'resolved_date': resolvedDate,
      'escalation_date': escalationDate,
      'ai_generated': aiGenerated,
      'ai_confidence': aiConfidence,
      'source_content_id': sourceContentId,
      'assigned_to': assignedTo,
      'assigned_to_email': assignedToEmail,
      'identified_date': identifiedDate,
      'last_updated': lastUpdated,
      'updated_by': updatedBy,
    };
  }

  Blocker toEntity() {
    return Blocker(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      impact: BlockerImpact.values.firstWhere(
        (e) => e.name == impact,
        orElse: () => BlockerImpact.medium,
      ),
      status: BlockerStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => BlockerStatus.active,
      ),
      resolution: resolution,
      category: category,
      owner: owner,
      dependencies: dependencies,
      targetDate: targetDate != null ? DateTime.parse(targetDate!) : null,
      resolvedDate: resolvedDate != null ? DateTime.parse(resolvedDate!) : null,
      escalationDate: escalationDate != null ? DateTime.parse(escalationDate!) : null,
      aiGenerated: aiGenerated == true || aiGenerated == 'true',
      aiConfidence: aiConfidence,
      sourceContentId: sourceContentId,
      assignedTo: assignedTo,
      assignedToEmail: assignedToEmail,
      identifiedDate: identifiedDate != null ? DateTime.parse(identifiedDate!) : null,
      lastUpdated: lastUpdated != null ? DateTime.parse(lastUpdated!) : null,
      updatedBy: updatedBy,
    );
  }

  factory BlockerModel.fromEntity(Blocker blocker) {
    return BlockerModel(
      id: blocker.id,
      projectId: blocker.projectId,
      title: blocker.title,
      description: blocker.description,
      impact: blocker.impact.name,
      status: blocker.status.name,
      resolution: blocker.resolution,
      category: blocker.category,
      owner: blocker.owner,
      dependencies: blocker.dependencies,
      targetDate: blocker.targetDate?.toIso8601String(),
      resolvedDate: blocker.resolvedDate?.toIso8601String(),
      escalationDate: blocker.escalationDate?.toIso8601String(),
      aiGenerated: blocker.aiGenerated,
      aiConfidence: blocker.aiConfidence,
      sourceContentId: blocker.sourceContentId,
      assignedTo: blocker.assignedTo,
      assignedToEmail: blocker.assignedToEmail,
      identifiedDate: blocker.identifiedDate?.toIso8601String(),
      lastUpdated: blocker.lastUpdated?.toIso8601String(),
      updatedBy: blocker.updatedBy,
    );
  }
}