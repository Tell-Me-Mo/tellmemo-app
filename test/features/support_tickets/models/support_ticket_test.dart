import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/support_tickets/models/support_ticket.dart';

void main() {
  group('TicketType', () {
    test('fromString returns correct type', () {
      expect(TicketType.fromString('bug_report'), TicketType.bugReport);
      expect(TicketType.fromString('feature_request'), TicketType.featureRequest);
      expect(TicketType.fromString('general_support'), TicketType.generalSupport);
      expect(TicketType.fromString('documentation'), TicketType.documentation);
    });

    test('fromString returns default for invalid value', () {
      expect(TicketType.fromString('invalid'), TicketType.generalSupport);
      expect(TicketType.fromString(''), TicketType.generalSupport);
    });

    test('has correct value and label', () {
      expect(TicketType.bugReport.value, 'bug_report');
      expect(TicketType.bugReport.label, 'Bug Report');
      expect(TicketType.featureRequest.value, 'feature_request');
      expect(TicketType.featureRequest.label, 'Feature Request');
      expect(TicketType.generalSupport.value, 'general_support');
      expect(TicketType.generalSupport.label, 'General Support');
      expect(TicketType.documentation.value, 'documentation');
      expect(TicketType.documentation.label, 'Documentation');
    });
  });

  group('TicketPriority', () {
    test('fromString returns correct priority', () {
      expect(TicketPriority.fromString('low'), TicketPriority.low);
      expect(TicketPriority.fromString('medium'), TicketPriority.medium);
      expect(TicketPriority.fromString('high'), TicketPriority.high);
      expect(TicketPriority.fromString('critical'), TicketPriority.critical);
    });

    test('fromString returns default for invalid value', () {
      expect(TicketPriority.fromString('invalid'), TicketPriority.medium);
      expect(TicketPriority.fromString(''), TicketPriority.medium);
    });

    test('has correct value and label', () {
      expect(TicketPriority.low.value, 'low');
      expect(TicketPriority.low.label, 'Low');
      expect(TicketPriority.medium.value, 'medium');
      expect(TicketPriority.medium.label, 'Medium');
      expect(TicketPriority.high.value, 'high');
      expect(TicketPriority.high.label, 'High');
      expect(TicketPriority.critical.value, 'critical');
      expect(TicketPriority.critical.label, 'Critical');
    });
  });

  group('TicketStatus', () {
    test('fromString returns correct status', () {
      expect(TicketStatus.fromString('open'), TicketStatus.open);
      expect(TicketStatus.fromString('in_progress'), TicketStatus.inProgress);
      expect(TicketStatus.fromString('waiting_for_user'), TicketStatus.waitingForUser);
      expect(TicketStatus.fromString('resolved'), TicketStatus.resolved);
      expect(TicketStatus.fromString('closed'), TicketStatus.closed);
    });

    test('fromString returns default for invalid value', () {
      expect(TicketStatus.fromString('invalid'), TicketStatus.open);
      expect(TicketStatus.fromString(''), TicketStatus.open);
    });

    test('has correct value and label', () {
      expect(TicketStatus.open.value, 'open');
      expect(TicketStatus.open.label, 'Open');
      expect(TicketStatus.inProgress.value, 'in_progress');
      expect(TicketStatus.inProgress.label, 'In Progress');
      expect(TicketStatus.waitingForUser.value, 'waiting_for_user');
      expect(TicketStatus.waitingForUser.label, 'Waiting for User');
      expect(TicketStatus.resolved.value, 'resolved');
      expect(TicketStatus.resolved.label, 'Resolved');
      expect(TicketStatus.closed.value, 'closed');
      expect(TicketStatus.closed.label, 'Closed');
    });
  });

  group('SupportTicket', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final completeJson = {
      'id': 'ticket-123',
      'title': 'Test Ticket',
      'description': 'This is a test ticket description',
      'type': 'bug_report',
      'priority': 'high',
      'status': 'open',
      'created_by': 'user-123',
      'creator_name': 'John Doe',
      'creator_email': 'john@example.com',
      'assigned_to': 'admin-123',
      'assignee_name': 'Admin User',
      'assignee_email': 'admin@example.com',
      'resolved_at': '2024-01-16T10:30:00.000',
      'resolution_notes': 'Fixed the bug',
      'created_at': '2024-01-15T10:30:00.000',
      'updated_at': '2024-01-15T11:30:00.000',
      'comment_count': 5,
      'attachment_count': 2,
      'last_comment': {'comment': 'Latest comment', 'user': 'user-123'},
    };

    test('fromJson creates SupportTicket with all fields', () {
      final ticket = SupportTicket.fromJson(completeJson);

      expect(ticket.id, 'ticket-123');
      expect(ticket.title, 'Test Ticket');
      expect(ticket.description, 'This is a test ticket description');
      expect(ticket.type, TicketType.bugReport);
      expect(ticket.priority, TicketPriority.high);
      expect(ticket.status, TicketStatus.open);
      expect(ticket.createdBy, 'user-123');
      expect(ticket.creatorName, 'John Doe');
      expect(ticket.creatorEmail, 'john@example.com');
      expect(ticket.assignedTo, 'admin-123');
      expect(ticket.assigneeName, 'Admin User');
      expect(ticket.assigneeEmail, 'admin@example.com');
      expect(ticket.resolvedAt, DateTime(2024, 1, 16, 10, 30));
      expect(ticket.resolutionNotes, 'Fixed the bug');
      expect(ticket.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(ticket.updatedAt, DateTime(2024, 1, 15, 11, 30));
      expect(ticket.commentCount, 5);
      expect(ticket.attachmentCount, 2);
      expect(ticket.lastComment, {'comment': 'Latest comment', 'user': 'user-123'});
    });

    test('fromJson handles minimal JSON (only required fields)', () {
      final minimalJson = {
        'id': 'ticket-456',
        'title': 'Minimal Ticket',
        'description': 'Minimal description',
        'type': 'general_support',
        'priority': 'medium',
        'status': 'open',
        'created_by': 'user-456',
        'creator_email': 'user@example.com',
        'created_at': '2024-01-15T10:30:00.000',
        'updated_at': '2024-01-15T10:30:00.000',
      };

      final ticket = SupportTicket.fromJson(minimalJson);

      expect(ticket.id, 'ticket-456');
      expect(ticket.title, 'Minimal Ticket');
      expect(ticket.description, 'Minimal description');
      expect(ticket.type, TicketType.generalSupport);
      expect(ticket.priority, TicketPriority.medium);
      expect(ticket.status, TicketStatus.open);
      expect(ticket.createdBy, 'user-456');
      expect(ticket.creatorName, null);
      expect(ticket.creatorEmail, 'user@example.com');
      expect(ticket.assignedTo, null);
      expect(ticket.assigneeName, null);
      expect(ticket.assigneeEmail, null);
      expect(ticket.resolvedAt, null);
      expect(ticket.resolutionNotes, null);
      expect(ticket.commentCount, 0);
      expect(ticket.attachmentCount, 0);
      expect(ticket.lastComment, null);
    });

    test('toJson serializes SupportTicket correctly', () {
      final ticket = SupportTicket(
        id: 'ticket-789',
        title: 'Serialization Test',
        description: 'Testing toJson',
        type: TicketType.featureRequest,
        priority: TicketPriority.critical,
        status: TicketStatus.inProgress,
        createdBy: 'user-789',
        creatorName: 'Test User',
        creatorEmail: 'test@example.com',
        assignedTo: 'admin-789',
        assigneeName: 'Admin',
        assigneeEmail: 'admin@example.com',
        resolvedAt: DateTime(2024, 1, 20, 15, 0),
        resolutionNotes: 'Feature implemented',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 16, 12, 0),
        commentCount: 3,
        attachmentCount: 1,
        lastComment: {'comment': 'Test comment'},
      );

      final json = ticket.toJson();

      expect(json['id'], 'ticket-789');
      expect(json['title'], 'Serialization Test');
      expect(json['description'], 'Testing toJson');
      expect(json['type'], 'feature_request');
      expect(json['priority'], 'critical');
      expect(json['status'], 'in_progress');
      expect(json['created_by'], 'user-789');
      expect(json['creator_name'], 'Test User');
      expect(json['creator_email'], 'test@example.com');
      expect(json['assigned_to'], 'admin-789');
      expect(json['assignee_name'], 'Admin');
      expect(json['assignee_email'], 'admin@example.com');
      expect(json['resolved_at'], '2024-01-20T15:00:00.000');
      expect(json['resolution_notes'], 'Feature implemented');
      expect(json['created_at'], '2024-01-15T10:30:00.000');
      expect(json['updated_at'], '2024-01-16T12:00:00.000');
      expect(json['comment_count'], 3);
      expect(json['attachment_count'], 1);
      expect(json['last_comment'], {'comment': 'Test comment'});
    });

    test('toJson handles null optional fields', () {
      final ticket = SupportTicket(
        id: 'ticket-999',
        title: 'Null Fields',
        description: 'Testing null fields',
        type: TicketType.documentation,
        priority: TicketPriority.low,
        status: TicketStatus.closed,
        createdBy: 'user-999',
        creatorEmail: 'user999@example.com',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 15, 10, 30),
        commentCount: 0,
        attachmentCount: 0,
      );

      final json = ticket.toJson();

      expect(json['creator_name'], null);
      expect(json['assigned_to'], null);
      expect(json['assignee_name'], null);
      expect(json['assignee_email'], null);
      expect(json['resolved_at'], null);
      expect(json['resolution_notes'], null);
      expect(json['last_comment'], null);
    });

    test('round-trip conversion preserves data', () {
      final original = SupportTicket.fromJson(completeJson);
      final json = original.toJson();
      final reconstructed = SupportTicket.fromJson(json);

      expect(reconstructed, original);
    });

    test('equality works correctly', () {
      final ticket1 = SupportTicket.fromJson(completeJson);
      final ticket2 = SupportTicket.fromJson(completeJson);
      final ticket3 = SupportTicket.fromJson({
        ...completeJson,
        'id': 'different-id',
      });

      expect(ticket1, ticket2);
      expect(ticket1, isNot(ticket3));
    });
  });

  group('TicketComment', () {
    final completeJson = {
      'id': 'comment-123',
      'ticket_id': 'ticket-123',
      'user_id': 'user-123',
      'user_name': 'John Doe',
      'user_email': 'john@example.com',
      'comment': 'This is a test comment',
      'is_internal': true,
      'is_system_message': false,
      'created_at': '2024-01-15T10:30:00.000',
      'attachments': [
        {'file_name': 'screenshot.png', 'url': 'https://example.com/file.png'},
        {'file_name': 'log.txt', 'url': 'https://example.com/log.txt'},
      ],
    };

    test('fromJson creates TicketComment with all fields', () {
      final comment = TicketComment.fromJson(completeJson);

      expect(comment.id, 'comment-123');
      expect(comment.ticketId, 'ticket-123');
      expect(comment.userId, 'user-123');
      expect(comment.userName, 'John Doe');
      expect(comment.userEmail, 'john@example.com');
      expect(comment.comment, 'This is a test comment');
      expect(comment.isInternal, true);
      expect(comment.isSystemMessage, false);
      expect(comment.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(comment.attachments.length, 2);
      expect(comment.attachments[0]['file_name'], 'screenshot.png');
      expect(comment.attachments[1]['file_name'], 'log.txt');
    });

    test('fromJson handles minimal JSON', () {
      final minimalJson = {
        'id': 'comment-456',
        'ticket_id': 'ticket-456',
        'user_id': 'user-456',
        'user_email': 'user@example.com',
        'comment': 'Minimal comment',
        'created_at': '2024-01-15T10:30:00.000',
      };

      final comment = TicketComment.fromJson(minimalJson);

      expect(comment.id, 'comment-456');
      expect(comment.ticketId, 'ticket-456');
      expect(comment.userId, 'user-456');
      expect(comment.userName, null);
      expect(comment.userEmail, 'user@example.com');
      expect(comment.comment, 'Minimal comment');
      expect(comment.isInternal, false);
      expect(comment.isSystemMessage, false);
      expect(comment.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(comment.attachments, isEmpty);
    });

    test('toJson serializes TicketComment correctly', () {
      final comment = TicketComment(
        id: 'comment-789',
        ticketId: 'ticket-789',
        userId: 'user-789',
        userName: 'Test User',
        userEmail: 'test@example.com',
        comment: 'Serialization test comment',
        isInternal: true,
        isSystemMessage: true,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        attachments: [
          {'file_name': 'file.pdf', 'url': 'https://example.com/file.pdf'},
        ],
      );

      final json = comment.toJson();

      expect(json['id'], 'comment-789');
      expect(json['ticket_id'], 'ticket-789');
      expect(json['user_id'], 'user-789');
      expect(json['user_name'], 'Test User');
      expect(json['user_email'], 'test@example.com');
      expect(json['comment'], 'Serialization test comment');
      expect(json['is_internal'], true);
      expect(json['is_system_message'], true);
      expect(json['created_at'], '2024-01-15T10:30:00.000');
      expect(json['attachments'], [
        {'file_name': 'file.pdf', 'url': 'https://example.com/file.pdf'},
      ]);
    });

    test('round-trip conversion preserves data', () {
      final original = TicketComment.fromJson(completeJson);
      final json = original.toJson();
      final reconstructed = TicketComment.fromJson(json);

      expect(reconstructed, original);
    });

    test('equality works correctly', () {
      final comment1 = TicketComment.fromJson(completeJson);
      final comment2 = TicketComment.fromJson(completeJson);
      final comment3 = TicketComment.fromJson({
        ...completeJson,
        'id': 'different-id',
      });

      expect(comment1, comment2);
      expect(comment1, isNot(comment3));
    });

    test('handles empty attachments array', () {
      final json = {
        ...completeJson,
        'attachments': [],
      };

      final comment = TicketComment.fromJson(json);
      expect(comment.attachments, isEmpty);
    });
  });
}
