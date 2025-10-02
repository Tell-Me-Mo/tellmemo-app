import 'package:equatable/equatable.dart';

enum TicketType {
  bugReport('bug_report', 'Bug Report'),
  featureRequest('feature_request', 'Feature Request'),
  generalSupport('general_support', 'General Support'),
  documentation('documentation', 'Documentation');

  final String value;
  final String label;

  const TicketType(this.value, this.label);

  static TicketType fromString(String value) {
    return TicketType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TicketType.generalSupport,
    );
  }
}

enum TicketPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  critical('critical', 'Critical');

  final String value;
  final String label;

  const TicketPriority(this.value, this.label);

  static TicketPriority fromString(String value) {
    return TicketPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TicketPriority.medium,
    );
  }
}

enum TicketStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  waitingForUser('waiting_for_user', 'Waiting for User'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  final String value;
  final String label;

  const TicketStatus(this.value, this.label);

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TicketStatus.open,
    );
  }
}

class SupportTicket extends Equatable {
  final String id;
  final String title;
  final String description;
  final TicketType type;
  final TicketPriority priority;
  final TicketStatus status;
  final String createdBy;
  final String? creatorName;
  final String creatorEmail;
  final String? assignedTo;
  final String? assigneeName;
  final String? assigneeEmail;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int commentCount;
  final int attachmentCount;
  final Map<String, dynamic>? lastComment;

  const SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdBy,
    this.creatorName,
    required this.creatorEmail,
    this.assignedTo,
    this.assigneeName,
    this.assigneeEmail,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
    required this.attachmentCount,
    this.lastComment,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: TicketType.fromString(json['type']),
      priority: TicketPriority.fromString(json['priority']),
      status: TicketStatus.fromString(json['status']),
      createdBy: json['created_by'],
      creatorName: json['creator_name'],
      creatorEmail: json['creator_email'],
      assignedTo: json['assigned_to'],
      assigneeName: json['assignee_name'],
      assigneeEmail: json['assignee_email'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolutionNotes: json['resolution_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      commentCount: json['comment_count'] ?? 0,
      attachmentCount: json['attachment_count'] ?? 0,
      lastComment: json['last_comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'priority': priority.value,
      'status': status.value,
      'created_by': createdBy,
      'creator_name': creatorName,
      'creator_email': creatorEmail,
      'assigned_to': assignedTo,
      'assignee_name': assigneeName,
      'assignee_email': assigneeEmail,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'comment_count': commentCount,
      'attachment_count': attachmentCount,
      'last_comment': lastComment,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        priority,
        status,
        createdBy,
        creatorName,
        creatorEmail,
        assignedTo,
        assigneeName,
        assigneeEmail,
        resolvedAt,
        resolutionNotes,
        createdAt,
        updatedAt,
        commentCount,
        attachmentCount,
        lastComment,
      ];
}

class TicketComment extends Equatable {
  final String id;
  final String ticketId;
  final String userId;
  final String? userName;
  final String userEmail;
  final String comment;
  final bool isInternal;
  final bool isSystemMessage;
  final DateTime createdAt;
  final List<Map<String, dynamic>> attachments;

  const TicketComment({
    required this.id,
    required this.ticketId,
    required this.userId,
    this.userName,
    required this.userEmail,
    required this.comment,
    required this.isInternal,
    required this.isSystemMessage,
    required this.createdAt,
    required this.attachments,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'],
      ticketId: json['ticket_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      comment: json['comment'],
      isInternal: json['is_internal'] ?? false,
      isSystemMessage: json['is_system_message'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      attachments: List<Map<String, dynamic>>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'comment': comment,
      'is_internal': isInternal,
      'is_system_message': isSystemMessage,
      'created_at': createdAt.toIso8601String(),
      'attachments': attachments,
    };
  }

  @override
  List<Object?> get props => [
        id,
        ticketId,
        userId,
        userName,
        userEmail,
        comment,
        isInternal,
        isSystemMessage,
        createdAt,
        attachments,
      ];
}