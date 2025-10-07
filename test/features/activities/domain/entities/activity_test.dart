import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/activities/domain/entities/activity.dart';

void main() {
  group('Activity Entity', () {
    group('icon getter', () {
      test('returns correct icon for projectCreated', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectCreated,
          title: 'Project Created',
          description: 'New project created',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '📁');
      });

      test('returns correct icon for projectUpdated', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectUpdated,
          title: 'Project Updated',
          description: 'Project updated',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '✏️');
      });

      test('returns correct icon for projectDeleted', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectDeleted,
          title: 'Project Deleted',
          description: 'Project deleted',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '🗑️');
      });

      test('returns correct icon for contentUploaded', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.contentUploaded,
          title: 'Content Uploaded',
          description: 'Content uploaded',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '📤');
      });

      test('returns correct icon for summaryGenerated', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.summaryGenerated,
          title: 'Summary Generated',
          description: 'Summary generated',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '✨');
      });

      test('returns correct icon for querySubmitted', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.querySubmitted,
          title: 'Query Submitted',
          description: 'Query submitted',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '❓');
      });

      test('returns correct icon for reportGenerated', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.reportGenerated,
          title: 'Report Generated',
          description: 'Report generated',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '📄');
      });

      test('returns correct icon for memberAdded', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.memberAdded,
          title: 'Member Added',
          description: 'Member added',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '👤');
      });

      test('returns correct icon for memberRemoved', () {
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.memberRemoved,
          title: 'Member Removed',
          description: 'Member removed',
          timestamp: DateTime.now(),
        );

        expect(activity.icon, '👥');
      });
    });

    group('formattedTime getter', () {
      test('returns "Just now" for recent timestamp', () {
        final now = DateTime.now();
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectCreated,
          title: 'Project Created',
          description: 'Description',
          timestamp: now.subtract(const Duration(seconds: 30)),
        );

        expect(activity.formattedTime, 'Just now');
      });

      test('returns minutes ago for timestamps within an hour', () {
        final now = DateTime.now();
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectCreated,
          title: 'Project Created',
          description: 'Description',
          timestamp: now.subtract(const Duration(minutes: 45)),
        );

        expect(activity.formattedTime, '45m ago');
      });

      test('returns hours ago for timestamps within 24 hours', () {
        final now = DateTime.now();
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectCreated,
          title: 'Project Created',
          description: 'Description',
          timestamp: now.subtract(const Duration(hours: 5)),
        );

        expect(activity.formattedTime, '5h ago');
      });

      test('returns days ago for timestamps within a week', () {
        final now = DateTime.now();
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectCreated,
          title: 'Project Created',
          description: 'Description',
          timestamp: now.subtract(const Duration(days: 3)),
        );

        expect(activity.formattedTime, '3d ago');
      });

      test('returns formatted date for timestamps older than a week', () {
        final now = DateTime.now();
        final oldDate = now.subtract(const Duration(days: 10));
        final activity = Activity(
          id: '1',
          projectId: 'proj-1',
          type: ActivityType.projectCreated,
          title: 'Project Created',
          description: 'Description',
          timestamp: oldDate,
        );

        // Should return formatted date like "Dec 25, 2024"
        expect(activity.formattedTime, isNot('Just now'));
        expect(activity.formattedTime, isNot(contains('ago')));
        expect(activity.formattedTime, contains(',')); // Date format includes comma
      });
    });

    group('constructor', () {
      test('creates Activity with all required fields', () {
        final timestamp = DateTime.now();
        final activity = Activity(
          id: '123',
          projectId: 'proj-456',
          type: ActivityType.projectCreated,
          title: 'Test Activity',
          description: 'Test description',
          timestamp: timestamp,
        );

        expect(activity.id, '123');
        expect(activity.projectId, 'proj-456');
        expect(activity.type, ActivityType.projectCreated);
        expect(activity.title, 'Test Activity');
        expect(activity.description, 'Test description');
        expect(activity.timestamp, timestamp);
        expect(activity.metadata, isNull);
        expect(activity.userId, isNull);
        expect(activity.userName, isNull);
      });

      test('creates Activity with optional fields', () {
        final timestamp = DateTime.now();
        final activity = Activity(
          id: '123',
          projectId: 'proj-456',
          type: ActivityType.memberAdded,
          title: 'Member Added',
          description: 'John Doe added to project',
          metadata: '{"role": "developer"}',
          timestamp: timestamp,
          userId: 'user-789',
          userName: 'John Doe',
        );

        expect(activity.metadata, '{"role": "developer"}');
        expect(activity.userId, 'user-789');
        expect(activity.userName, 'John Doe');
      });
    });

    group('equality', () {
      test('two activities with same values are equal', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        final activity1 = Activity(
          id: '123',
          projectId: 'proj-456',
          type: ActivityType.projectCreated,
          title: 'Test',
          description: 'Description',
          timestamp: timestamp,
        );
        final activity2 = Activity(
          id: '123',
          projectId: 'proj-456',
          type: ActivityType.projectCreated,
          title: 'Test',
          description: 'Description',
          timestamp: timestamp,
        );

        expect(activity1, equals(activity2));
      });

      test('two activities with different IDs are not equal', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        final activity1 = Activity(
          id: '123',
          projectId: 'proj-456',
          type: ActivityType.projectCreated,
          title: 'Test',
          description: 'Description',
          timestamp: timestamp,
        );
        final activity2 = Activity(
          id: '456',
          projectId: 'proj-456',
          type: ActivityType.projectCreated,
          title: 'Test',
          description: 'Description',
          timestamp: timestamp,
        );

        expect(activity1, isNot(equals(activity2)));
      });
    });
  });
}
